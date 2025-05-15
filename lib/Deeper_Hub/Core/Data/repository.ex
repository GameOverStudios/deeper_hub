defmodule Deeper_Hub.Core.Data.Repository do
  @moduledoc """
  Repositório genérico para operações CRUD e outras interações com o banco de dados.

  Este módulo funciona como uma fachada (Facade) para os módulos específicos:
  - RepositoryCore: Funções auxiliares e gerenciamento de processos.
  - RepositoryCrud: Operações CRUD básicas (insert, get, update, delete, list, find)
  - RepositoryJoins: Operações de join (inner, left, right)
  """

  alias Deeper_Hub.Core.Data.RepositoryCore
  alias Deeper_Hub.Core.Data.RepositoryCrud
  alias Deeper_Hub.Core.Data.RepositoryJoins

  @doc """
  Define a especificação para o supervisor.

  Esta função é chamada pelo supervisor para iniciar o processo
  do repositório (gerenciado por RepositoryCore).
  """
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {RepositoryCore, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  # Delegação de funções de gerenciamento de processo e auxiliares para RepositoryCore

  @doc """
  Inicia o processo GenServer do repositório (via RepositoryCore).

  ## Parâmetros

  - `opts`: Opções para inicialização do processo

  ## Retorno

  - `{:ok, pid}` se o processo for iniciado com sucesso
  - `{:error, reason}` em caso de falha
  """
  @spec start_link(keyword()) :: {:ok, pid()} | {:error, term()}
  defdelegate start_link(opts), to: RepositoryCore

  @doc """
  Aplica limitação e deslocamento a uma consulta Ecto.

  ## Parâmetros

  - `query`: A consulta Ecto
  - `opts`: Opções de paginação (`:limit` e `:offset`)

  ## Retorno

  - A consulta Ecto modificada com limitação e deslocamento aplicados
  """
  @spec apply_limit_offset(Ecto.Query.t(), keyword()) :: Ecto.Query.t()
  defdelegate apply_limit_offset(query, opts), to: RepositoryCore

  # Delegação de operações CRUD para RepositoryCrud

  @doc """
  Insere um novo registro no banco de dados.

  ## Parâmetros

  - `schema`: O módulo do schema Ecto
  - `attrs`: Atributos para o novo registro

  ## Retorno

  - `{:ok, struct}` se o registro for inserido com sucesso
  - `{:error, changeset}` em caso de falha na validação
  """
  @spec insert(module(), map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  defdelegate insert(schema, attrs), to: RepositoryCrud

  @doc """
  Busca um registro pelo ID.

  ## Parâmetros

  - `schema`: O módulo do schema Ecto
  - `id`: O ID do registro a ser buscado

  ## Retorno

  - `{:ok, struct}` se o registro for encontrado
  - `{:error, :not_found}` se o registro não for encontrado
  """
  @spec get(module(), term()) :: {:ok, Ecto.Schema.t()} | {:error, :not_found}
  defdelegate get(schema, id), to: RepositoryCrud

  @doc """
  Atualiza um registro existente.

  ## Parâmetros

  - `struct`: A struct Ecto a ser atualizada
  - `attrs`: Novos atributos para o registro

  ## Retorno

  - `{:ok, struct}` se o registro for atualizado com sucesso
  - `{:error, changeset}` em caso de falha na validação
  """
  @spec update(Ecto.Schema.t(), map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  defdelegate update(struct, attrs), to: RepositoryCrud

  @doc """
  Deleta um registro.

  ## Parâmetros

  - `struct`: A struct Ecto a ser deletada

  ## Retorno

  - `{:ok, struct}` se o registro for deletado com sucesso
  - `{:error, changeset}` em caso de falha
  """
  @spec delete(Ecto.Schema.t()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  defdelegate delete(struct), to: RepositoryCrud

  @doc """
  Lista todos os registros de um schema, com opções de filtro e paginação.

  ## Parâmetros

  - `schema`: O módulo do schema Ecto
  - `opts`: Opções de filtro e paginação (ex: `[active: true, limit: 10, offset: 0]`)

  ## Retorno

  - `{:ok, list_of_structs}` contendo a lista de registros
  """
  @spec list(module(), keyword()) :: {:ok, list(Ecto.Schema.t())}
  defdelegate list(schema, opts \\ []), to: RepositoryCrud

  @doc """
  Encontra registros com base em um conjunto de filtros.

  ## Parâmetros

  - `schema`: O módulo do schema Ecto
  - `filters`: Condições de filtro (ex: `[name: "John", age: 30]`)
  - `opts`: Opções de paginação (`:limit`, `:offset`)

  ## Retorno

  - `{:ok, list_of_structs}` contendo os registros encontrados
  """
  @spec find(module(), keyword(), keyword()) :: {:ok, list(Ecto.Schema.t())}
  defdelegate find(schema, filters, opts \\ []), to: RepositoryCrud

  # Delegação de operações de Join para RepositoryJoins

  @doc """
  Realiza um inner join entre duas tabelas.

  ## Parâmetros

  - `from_schema`: O schema principal da consulta
  - `join_schema`: O schema a ser unido
  - `on_clause`: A condição para o join (ex: `[from_schema_id: :id]`)
  - `select_fields`: Campos a serem selecionados (opcional)
  - `filters`: Condições de filtro (opcional)
  - `opts`: Opções de paginação (`:limit`, `:offset`) (opcional)

  ## Retorno

  - `{:ok, list_of_results}`
  """
  @spec join_inner(module(), module(), keyword(), list() | nil, keyword() | nil, keyword() | nil) :: {:ok, list(map()) | list(Ecto.Schema.t())}
  def join_inner(from_schema, join_schema, on_clause_kw, select_fields \\ nil, filters \\ [], opts \\ []) do
    join_on_tuple =
      cond do
        Keyword.keyword?(on_clause_kw) && length(on_clause_kw) == 1 ->
          List.first(on_clause_kw)
        is_tuple(on_clause_kw) && tuple_size(on_clause_kw) == 2 ->
          on_clause_kw
        true ->
          if Keyword.keyword?(on_clause_kw) && !Enum.empty?(on_clause_kw) do
            List.first(on_clause_kw)
          else
            nil
          end
      end

    new_opts =
      if join_on_tuple do
        Keyword.put(opts, :join_on, join_on_tuple)
      else
        opts
      end

    RepositoryJoins.join_inner(from_schema, join_schema, select_fields, filters, new_opts)
  end

  @doc """
  Realiza um left join entre duas tabelas.

  ## Parâmetros

  - `from_schema`: O schema principal da consulta
  - `join_schema`: O schema a ser unido
  - `on_clause`: A condição para o join
  - `select_fields`: Campos a serem selecionados (opcional)
  - `filters`: Condições de filtro (opcional)
  - `opts`: Opções de paginação (`:limit`, `:offset`) (opcional)

  ## Retorno

  - `{:ok, list_of_results}`
  """
  @spec join_left(module(), module(), keyword(), list() | nil, keyword() | nil, keyword() | nil) :: {:ok, list(map()) | list(Ecto.Schema.t())}
  def join_left(from_schema, join_schema, on_clause_kw, select_fields \\ nil, filters \\ [], opts \\ []) do
    join_on_tuple =
      cond do
        Keyword.keyword?(on_clause_kw) && length(on_clause_kw) == 1 ->
          List.first(on_clause_kw)
        is_tuple(on_clause_kw) && tuple_size(on_clause_kw) == 2 ->
          on_clause_kw
        true ->
          if Keyword.keyword?(on_clause_kw) && !Enum.empty?(on_clause_kw) do
            List.first(on_clause_kw)
          else
            nil
          end
      end

    new_opts =
      if join_on_tuple do
        Keyword.put(opts, :join_on, join_on_tuple)
      else
        opts
      end

    RepositoryJoins.join_left(from_schema, join_schema, select_fields, filters, new_opts)
  end

  @doc """
  Realiza um right join entre duas tabelas.

  ## Parâmetros

  - `from_schema`: O schema principal da consulta
  - `join_schema`: O schema a ser unido
  - `on_clause`: A condição para o join
  - `select_fields`: Campos a serem selecionados (opcional)
  - `filters`: Condições de filtro (opcional)
  - `opts`: Opções de paginação (`:limit`, `:offset`) (opcional)

  ## Retorno

  - `{:ok, list_of_results}`
  """
  @spec join_right(module(), module(), keyword(), list() | nil, keyword() | nil, keyword() | nil) :: {:ok, list(map()) | list(Ecto.Schema.t())}
  def join_right(from_schema, join_schema, on_clause_kw, select_fields \\ nil, filters \\ [], opts \\ []) do
    join_on_tuple =
      cond do
        Keyword.keyword?(on_clause_kw) && length(on_clause_kw) == 1 ->
          List.first(on_clause_kw)
        is_tuple(on_clause_kw) && tuple_size(on_clause_kw) == 2 ->
          on_clause_kw
        true ->
          if Keyword.keyword?(on_clause_kw) && !Enum.empty?(on_clause_kw) do
            List.first(on_clause_kw)
          else
            nil
          end
      end

    new_opts =
      if join_on_tuple do
        Keyword.put(opts, :join_on, join_on_tuple)
      else
        opts
      end

    # Assuming RepositoryJoins.right_join/5 will be implemented
    RepositoryJoins.join_right(from_schema, join_schema, select_fields, filters, new_opts)
  end
end
