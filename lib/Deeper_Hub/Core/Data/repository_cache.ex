defmodule Deeper_Hub.Core.Data.RepositoryCache do
  @moduledoc """
  Módulo de integração com o Cache para operações de repositório.
  
  Este módulo centraliza o gerenciamento de cache para operações de banco de dados,
  melhorando o desempenho e reduzindo a carga no banco de dados.
  
  ## Configuração
  
  O cache é configurado com os seguintes parâmetros padrão:
  
  - `ttl`: 300_000 - Tempo de vida em milissegundos (5 minutos)
  - `max_size`: 1000 - Tamanho máximo do cache em número de entradas
  
  Estes parâmetros podem ser sobrescritos na configuração da aplicação:
  
  ```elixir
  config :deeper_hub, Deeper_Hub.Core.Data.RepositoryCache,
    ttl: 600_000,
    max_size: 5000
  ```
  
  ## Estratégias de Cache
  
  O módulo suporta diferentes estratégias de cache:
  
  - `:id` - Cache por ID (padrão para operações `get`)
  - `:query` - Cache por consulta (padrão para operações `list` e `find`)
  - `:none` - Sem cache
  
  ## Invalidação de Cache
  
  O cache é invalidado automaticamente após operações de escrita (insert, update, delete)
  para garantir a consistência dos dados.
  """
  
  alias Deeper_Hub.Core.Cache.CacheFacade, as: Cache
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Data.RepositoryMetrics
  
  @doc """
  Inicializa o cache para os schemas fornecidos.
  
  Esta função deve ser chamada durante a inicialização da aplicação para
  garantir que o cache esteja configurado corretamente.
  
  ## Parâmetros
  
  - `schemas` - Lista de schemas Ecto para os quais configurar o cache
  """
  def setup(schemas) when is_list(schemas) do
    # Obtém configuração
    config = Application.get_env(:deeper_hub, __MODULE__, [])
    ttl = Keyword.get(config, :ttl, 300_000)
    max_size = Keyword.get(config, :max_size, 1000)
    
    # Inicializa cache para cada schema
    Enum.each(schemas, fn schema ->
      schema_name = get_schema_name(schema)
      
      # Cache para registros individuais
      Cache.create_namespace(
        get_record_cache_namespace(schema),
        ttl: ttl,
        max_size: max_size
      )
      
      # Cache para consultas
      Cache.create_namespace(
        get_query_cache_namespace(schema),
        ttl: ttl,
        max_size: max_size
      )
      
      Logger.info("Cache inicializado para schema", %{
        module: __MODULE__,
        schema: schema_name,
        ttl: ttl,
        max_size: max_size
      })
    end)
    
    :ok
  end
  
  @doc """
  Obtém um registro do cache por ID.
  
  ## Parâmetros
  
  - `schema` - O schema Ecto do registro
  - `id` - O ID do registro
  
  ## Retorno
  
  - `{:ok, record}` - Se o registro for encontrado no cache
  - `{:error, :not_found}` - Se o registro não for encontrado no cache
  """
  def get_record(schema, id) do
    namespace = get_record_cache_namespace(schema)
    key = "#{id}"
    schema_name = get_schema_name(schema)
    
    case Cache.get(namespace, key) do
      {:ok, record} ->
        # Registra métrica de acerto no cache
        RepositoryMetrics.increment_cache_hit(schema, :get)
        
        Logger.debug("Registro encontrado no cache", %{
          module: __MODULE__,
          schema: schema_name,
          id: id
        })
        
        {:ok, record}
        
      {:error, :not_found} ->
        # Registra métrica de erro no cache
        RepositoryMetrics.increment_cache_miss(schema, :get)
        
        Logger.debug("Registro não encontrado no cache", %{
          module: __MODULE__,
          schema: schema_name,
          id: id
        })
        
        {:error, :not_found}
    end
  end
  
  @doc """
  Armazena um registro no cache.
  
  ## Parâmetros
  
  - `schema` - O schema Ecto do registro
  - `id` - O ID do registro
  - `record` - O registro a ser armazenado
  
  ## Retorno
  
  - `:ok` - Se o registro for armazenado com sucesso
  - `{:error, reason}` - Se ocorrer um erro ao armazenar o registro
  """
  def put_record(schema, id, record) do
    namespace = get_record_cache_namespace(schema)
    key = "#{id}"
    schema_name = get_schema_name(schema)
    
    case Cache.put(namespace, key, record) do
      :ok ->
        Logger.debug("Registro armazenado no cache", %{
          module: __MODULE__,
          schema: schema_name,
          id: id
        })
        
        # Atualiza métrica de tamanho do cache
        update_cache_size_metric(schema)
        
        :ok
        
      {:error, reason} = error ->
        Logger.error("Erro ao armazenar registro no cache", %{
          module: __MODULE__,
          schema: schema_name,
          id: id,
          reason: reason
        })
        
        error
    end
  end
  
  @doc """
  Obtém resultados de uma consulta do cache.
  
  ## Parâmetros
  
  - `schema` - O schema Ecto da consulta
  - `query_key` - A chave da consulta (geralmente um hash dos parâmetros)
  
  ## Retorno
  
  - `{:ok, results}` - Se os resultados forem encontrados no cache
  - `{:error, :not_found}` - Se os resultados não forem encontrados no cache
  """
  def get_query_results(schema, query_key) do
    namespace = get_query_cache_namespace(schema)
    key = "#{query_key}"
    schema_name = get_schema_name(schema)
    
    case Cache.get(namespace, key) do
      {:ok, results} ->
        # Registra métrica de acerto no cache
        RepositoryMetrics.increment_cache_hit(schema, :query)
        
        Logger.debug("Resultados de consulta encontrados no cache", %{
          module: __MODULE__,
          schema: schema_name,
          query_key: query_key
        })
        
        {:ok, results}
        
      {:error, :not_found} ->
        # Registra métrica de erro no cache
        RepositoryMetrics.increment_cache_miss(schema, :query)
        
        Logger.debug("Resultados de consulta não encontrados no cache", %{
          module: __MODULE__,
          schema: schema_name,
          query_key: query_key
        })
        
        {:error, :not_found}
    end
  end
  
  @doc """
  Armazena resultados de uma consulta no cache.
  
  ## Parâmetros
  
  - `schema` - O schema Ecto da consulta
  - `query_key` - A chave da consulta (geralmente um hash dos parâmetros)
  - `results` - Os resultados a serem armazenados
  
  ## Retorno
  
  - `:ok` - Se os resultados forem armazenados com sucesso
  - `{:error, reason}` - Se ocorrer um erro ao armazenar os resultados
  """
  def put_query_results(schema, query_key, results) do
    namespace = get_query_cache_namespace(schema)
    key = "#{query_key}"
    schema_name = get_schema_name(schema)
    
    case Cache.put(namespace, key, results) do
      :ok ->
        Logger.debug("Resultados de consulta armazenados no cache", %{
          module: __MODULE__,
          schema: schema_name,
          query_key: query_key
        })
        
        # Atualiza métrica de tamanho do cache
        update_cache_size_metric(schema)
        
        :ok
        
      {:error, reason} = error ->
        Logger.error("Erro ao armazenar resultados de consulta no cache", %{
          module: __MODULE__,
          schema: schema_name,
          query_key: query_key,
          reason: reason
        })
        
        error
    end
  end
  
  @doc """
  Invalida o cache para um registro específico.
  
  ## Parâmetros
  
  - `schema` - O schema Ecto do registro
  - `id` - O ID do registro
  
  ## Retorno
  
  - `:ok` - Se o cache for invalidado com sucesso
  """
  def invalidate_record(schema, id) do
    namespace = get_record_cache_namespace(schema)
    key = "#{id}"
    schema_name = get_schema_name(schema)
    
    # Remove o registro do cache
    Cache.delete(namespace, key)
    
    # Atualiza métrica de tamanho do cache
    update_cache_size_metric(schema)
    
    Logger.debug("Cache invalidado para registro", %{
      module: __MODULE__,
      schema: schema_name,
      id: id
    })
    
    :ok
  end
  
  @doc """
  Invalida todo o cache para um schema específico.
  
  ## Parâmetros
  
  - `schema` - O schema Ecto para o qual invalidar o cache
  
  ## Retorno
  
  - `:ok` - Se o cache for invalidado com sucesso
  """
  def invalidate_schema(schema) do
    # Invalida cache de registros
    Cache.clear_namespace(get_record_cache_namespace(schema))
    
    # Invalida cache de consultas
    Cache.clear_namespace(get_query_cache_namespace(schema))
    
    # Atualiza métrica de tamanho do cache
    update_cache_size_metric(schema)
    
    Logger.info("Cache invalidado para schema", %{
      module: __MODULE__,
      schema: get_schema_name(schema)
    })
    
    :ok
  end
  
  @doc """
  Gera uma chave de cache para uma consulta.
  
  ## Parâmetros
  
  - `conditions` - As condições da consulta
  - `opts` - Opções adicionais da consulta
  
  ## Retorno
  
  - `String.t()` - A chave de cache gerada
  """
  def generate_query_key(conditions, opts \\ []) do
    # Serializa as condições e opções
    serialized = :erlang.term_to_binary({conditions, opts})
    
    # Gera um hash da serialização
    :crypto.hash(:sha256, serialized)
    |> Base.encode16()
    |> String.downcase()
  end
  
  # Funções privadas auxiliares
  
  # Obtém o namespace do cache para registros individuais
  defp get_record_cache_namespace(schema) do
    "repository:#{get_schema_name(schema)}:records"
  end
  
  # Obtém o namespace do cache para consultas
  defp get_query_cache_namespace(schema) do
    "repository:#{get_schema_name(schema)}:queries"
  end
  
  # Extrai o nome do schema de um módulo ou string
  defp get_schema_name(schema) when is_atom(schema) do
    schema
    |> Atom.to_string()
    |> String.split(".")
    |> List.last()
  end
  
  defp get_schema_name(schema) when is_binary(schema) do
    schema
  end
  
  # Atualiza a métrica de tamanho do cache
  defp update_cache_size_metric(schema) do
    # Obtém o tamanho do cache de registros
    {:ok, record_size} = Cache.size(get_record_cache_namespace(schema))
    
    # Obtém o tamanho do cache de consultas
    {:ok, query_size} = Cache.size(get_query_cache_namespace(schema))
    
    # Atualiza a métrica
    RepositoryMetrics.set_cache_size(record_size + query_size, schema)
  end
end
