defmodule Deeper_Hub.Core.Data.Repository do
  @moduledoc """
  Repositório genérico para operações CRUD e outras interações com o banco de dados.

  Este módulo funciona como uma fachada (Facade) para os módulos específicos:
  - RepositoryCrud: Operações CRUD básicas (insert, get, update, delete, list, find)
  - RepositoryJoins: Operações de join (inner, left, right)
  
  Também fornece funções auxiliares para manipulação de consultas.
  """

  alias Deeper_Hub.Core.Data.RepositoryCrud
  alias Deeper_Hub.Core.Data.RepositoryJoins
  alias Deeper_Hub.Core.Cache.CacheManager

  # Delegação de funções de cache para CacheManager
  
  @doc """
  Busca um valor no cache.
  
  ## Parâmetros
  
  - `schema`: O módulo do schema Ecto
  - `id`: O ID do registro
  
  ## Retorno
  
  - `{:ok, value}` se o valor for encontrado
  - `:not_found` se o valor não for encontrado
  """
  @spec get_from_cache(module(), term()) :: {:ok, term()} | :not_found
  defdelegate get_from_cache(schema, id), to: CacheManager
  
  @doc """
  Armazena um valor no cache.
  
  ## Parâmetros
  
  - `schema`: O módulo do schema Ecto
  - `id`: O ID do registro
  - `value`: O valor a ser armazenado
  - `ttl`: Tempo de vida em milissegundos (opcional)
  
  ## Retorno
  
  - `:ok` se o valor for armazenado com sucesso
  - `:error` em caso de falha
  """
  @spec put_in_cache(module(), term(), term(), integer() | nil) :: :ok | :error
  defdelegate put_in_cache(schema, id, value, ttl \\ nil), to: CacheManager
  
  @doc """
  Invalida (remove) um valor do cache.
  
  ## Parâmetros
  
  - `schema`: O módulo do schema Ecto
  - `id`: O ID do registro
  
  ## Retorno
  
  - `:ok` se o valor for removido com sucesso
  - `:error` em caso de falha
  """
  @spec invalidate_cache(module(), term()) :: :ok | :error
  defdelegate invalidate_cache(schema, id), to: CacheManager

  @doc """
  Aplica limitação e deslocamento a uma consulta Ecto.

  ## Parâmetros

  - `query`: A consulta Ecto
  - `opts`: Opções de paginação (`:limit` e `:offset`)

  ## Retorno

  - A consulta Ecto modificada com limitação e deslocamento aplicados
  """
  @spec apply_limit_offset(Ecto.Query.t(), keyword()) :: Ecto.Query.t()
  def apply_limit_offset(query, opts) do
    import Ecto.Query
    
    has_limit = Keyword.has_key?(opts, :limit)
    has_offset = Keyword.has_key?(opts, :offset)

    cond do
      has_limit && has_offset ->
        # Aplica ambos limit e offset
        limit_value = Keyword.get(opts, :limit)
        offset_value = Keyword.get(opts, :offset)
        from(item in query, limit: ^limit_value, offset: ^offset_value)

      has_limit && !has_offset ->
        # Aplica apenas limit
        limit_value = Keyword.get(opts, :limit)
        from(item in query, limit: ^limit_value)

      !has_limit && has_offset ->
        # Se tem offset mas não tem limit, aplica um limit padrão alto (1000)
        offset_value = Keyword.get(opts, :offset)
        from(item in query, limit: 1000, offset: ^offset_value)

      !has_limit && !has_offset ->
        # Nem limit nem offset
        query
    end
  end

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
