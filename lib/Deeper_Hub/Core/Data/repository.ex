defmodule Deeper_Hub.Core.Data.Repository do
  @moduledoc """
  Repositório genérico para operações CRUD.

  Este módulo funciona como uma fachada (Facade) para os módulos específicos:
  - RepositoryCore: Funções de gerenciamento de cache e inicialização
  - RepositoryCrud: Operações CRUD básicas (insert, get, update, delete, list, find)
  - RepositoryJoins: Operações de join (inner, left, right)
  """

  alias Deeper_Hub.Core.Data.RepositoryCore
  alias Deeper_Hub.Core.Data.RepositoryCrud
  alias Deeper_Hub.Core.Data.RepositoryJoins
  
  @doc """
  Define a especificação para o supervisor.
  
  Esta função é chamada pelo supervisor para iniciar o processo
  do repositório.
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

  # Delegação de funções de cache e inicialização
  
  @doc """
  Inicializa o cache do repositório.

  Esta função cria as tabelas ETS necessárias para o cache se elas ainda não existirem.
  É seguro chamar esta função múltiplas vezes.

  ## Retorno

  - `:ok` se a inicialização for bem-sucedida
  """
  @spec initialize_cache() :: :ok
  defdelegate initialize_cache(), to: RepositoryCore
  
  @doc """
  Inicia o processo GenServer do repositório.

  ## Parâmetros

  - `opts`: Opções para inicialização do processo

  ## Retorno

  - `{:ok, pid}` se o processo for iniciado com sucesso
  - `{:error, reason}` em caso de falha
  """
  @spec start_link(keyword()) :: {:ok, pid()} | {:error, term()}
  defdelegate start_link(opts), to: RepositoryCore
  
  @doc """
  Inicializa o cache do repositório.

  ## Retorno

  - `:ok` se a inicialização for bem-sucedida
  """
  @spec init_cache() :: :ok
  defdelegate init_cache(), to: RepositoryCore
  
  @doc """
  Invalida uma entrada específica no cache.

  ## Parâmetros

  - `schema`: O módulo do schema Ecto
  - `id`: O ID do registro a ser invalidado

  ## Retorno

  - `:ok` se a operação for bem-sucedida
  """
  @spec invalidate_cache(module(), term()) :: :ok
  defdelegate invalidate_cache(schema, id), to: RepositoryCore
  
  @doc """
  Retorna estatísticas de uso do cache.

  ## Retorno

  Um mapa contendo:
    - `:hits`: Número de acertos no cache
    - `:misses`: Número de erros no cache
    - `:hit_rate`: Taxa de acertos (hits / (hits + misses))
  """
  @spec get_cache_stats() :: %{hits: non_neg_integer(), misses: non_neg_integer(), hit_rate: float()}
  defdelegate get_cache_stats(), to: RepositoryCore
  
  @doc """
  Garante que as tabelas ETS do cache estão inicializadas.

  ## Retorno

  - `:ok` se o cache estiver inicializado corretamente
  """
  @spec ensure_cache_initialized() :: :ok
  defdelegate ensure_cache_initialized(), to: RepositoryCore
  
  @doc """
  Busca um valor no cache.

  ## Parâmetros

  - `schema`: O módulo do schema Ecto
  - `id`: O ID do registro a ser buscado

  ## Retorno

  - `{:ok, value}` se o valor for encontrado no cache
  - `:not_found` se o valor não for encontrado no cache
  """
  @spec get_from_cache(module(), term()) :: {:ok, term()} | :not_found
  defdelegate get_from_cache(schema, id), to: RepositoryCore
  
  @doc """
  Armazena um valor no cache.

  ## Parâmetros

  - `schema`: O módulo do schema Ecto
  - `id`: O ID do registro
  - `value`: O valor a ser armazenado

  ## Retorno

  - `:ok` se o valor for armazenado com sucesso
  """
  @spec put_in_cache(module(), term(), term()) :: :ok
  defdelegate put_in_cache(schema, id, value), to: RepositoryCore
  
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

  # Delegação de operações CRUD
  
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
  Remove um registro do banco de dados.

  ## Parâmetros

  - `struct`: A struct Ecto a ser removida

  ## Retorno

  - `{:ok, :deleted}` se o registro for removido com sucesso
  - `{:error, changeset}` em caso de falha
  """
  @spec delete(Ecto.Schema.t()) :: {:ok, :deleted} | {:error, Ecto.Changeset.t()}
  defdelegate delete(struct), to: RepositoryCrud
  
  @doc """
  Lista registros com opções de paginação.

  ## Parâmetros

  - `schema`: O módulo do schema Ecto
  - `opts`: Opções de paginação (`:limit` e `:offset`)

  ## Retorno

  - `{:ok, [struct]}` com a lista de registros
  - `{:error, reason}` em caso de falha
  """
  @spec list(module(), keyword()) :: {:ok, [Ecto.Schema.t()]} | {:error, term()}
  defdelegate list(schema, opts \\ []), to: RepositoryCrud
  
  @doc """
  Busca registros que atendem a determinadas condições.

  ## Parâmetros

  - `schema`: O módulo do schema Ecto
  - `conditions`: Condições para a busca (mapa de campo => valor)
  - `opts`: Opções adicionais para a busca

  ## Retorno

  - `{:ok, [struct]}` com a lista de registros encontrados
  - `{:error, reason}` em caso de falha
  """
  @spec find(module(), map(), keyword()) :: {:ok, [Ecto.Schema.t()]} | {:error, term()}
  defdelegate find(schema, conditions, opts \\ []), to: RepositoryCrud

  # Delegação de operações de join
  
  @doc """
  Realiza um INNER JOIN entre duas tabelas.

  ## Parâmetros

  - `schema1`: O módulo do primeiro schema Ecto
  - `schema2`: O módulo do segundo schema Ecto
  - `select_fields`: Campos a serem selecionados (lista de átomos)
  - `where_conditions`: Condições para a cláusula WHERE (mapa)
  - `opts`: Opções adicionais, incluindo `:join_on` para especificar os campos de join

  ## Retorno

  - `{:ok, [map]}` com a lista de resultados do join
  - `{:error, reason}` em caso de falha
  """
  @spec join_inner(module(), module(), list(atom()) | nil, map() | nil, keyword()) :: {:ok, [map()]} | {:error, term()}
  defdelegate join_inner(schema1, schema2, select_fields \\ nil, where_conditions \\ nil, opts \\ []), to: RepositoryJoins
  
  @doc """
  Realiza um LEFT JOIN entre duas tabelas.

  ## Parâmetros

  - `schema1`: O módulo do primeiro schema Ecto (lado esquerdo)
  - `schema2`: O módulo do segundo schema Ecto (lado direito)
  - `select_fields`: Campos a serem selecionados (lista de átomos)
  - `where_conditions`: Condições para a cláusula WHERE (mapa)
  - `opts`: Opções adicionais, incluindo `:join_on` para especificar os campos de join

  ## Retorno

  - `{:ok, [map]}` com a lista de resultados do join
  - `{:error, reason}` em caso de falha
  """
  @spec join_left(module(), module(), list(atom()) | nil, map() | nil, keyword()) :: {:ok, [map()]} | {:error, term()}
  defdelegate join_left(schema1, schema2, select_fields \\ nil, where_conditions \\ nil, opts \\ []), to: RepositoryJoins
  
  @doc """
  Realiza um RIGHT JOIN entre duas tabelas.

  ## Parâmetros

  - `schema1`: O módulo do primeiro schema Ecto (lado esquerdo)
  - `schema2`: O módulo do segundo schema Ecto (lado direito)
  - `select_fields`: Campos a serem selecionados (lista de átomos)
  - `where_conditions`: Condições para a cláusula WHERE (mapa)
  - `opts`: Opções adicionais, incluindo `:join_on` para especificar os campos de join

  ## Retorno

  - `{:ok, [map]}` com a lista de resultados do join
  - `{:error, reason}` em caso de falha
  """
  @spec join_right(module(), module(), list(atom()) | nil, map() | nil, keyword()) :: {:ok, [map()]} | {:error, term()}
  defdelegate join_right(schema1, schema2, select_fields \\ nil, where_conditions \\ nil, opts \\ []), to: RepositoryJoins
end
