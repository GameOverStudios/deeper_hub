defmodule Deeper_Hub.Core.Data.ResilientRepository do
  @moduledoc """
  Repositório resiliente que integra CircuitBreaker e Cache com o Repository.
  
  Este módulo fornece uma camada de resiliência para operações de banco de dados,
  utilizando o CircuitBreaker para proteger contra falhas e o Cache como mecanismo
  de fallback para operações de leitura.
  
  ## Funcionalidades
  
  * 🔄 Proteção de operações de banco de dados com CircuitBreaker
  * 📦 Fallback automático para cache em operações de leitura
  * ⏱️ Configuração de TTL para dados em cache
  * 📊 Métricas detalhadas sobre operações de banco de dados
  * 🔍 Logging aprimorado para diagnóstico de problemas
  * 🔁 Políticas de retry para operações de escrita
  
  ## Exemplo de Uso
  
  ```elixir
  alias Deeper_Hub.Core.Data.ResilientRepository, as: Repo
  
  # Buscar um usuário com fallback para cache
  {:ok, user} = Repo.get(User, 123)
  
  # Inserir um novo usuário com proteção de CircuitBreaker
  {:ok, user} = Repo.insert(User, %{name: "João", email: "joao@example.com"})
  ```
  """
  
  alias Deeper_Hub.Core.Data.Repository
  alias Deeper_Hub.Core.CircuitBreaker.CacheIntegration
  alias Deeper_Hub.Core.CircuitBreaker.Integration, as: CB
  alias Deeper_Hub.Core.Cache.CacheFacade, as: Cache
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Metrics.MetricsFacade, as: Metrics
  
  # Nome do serviço para o CircuitBreaker
  @db_service :database_service
  
  # Nome do cache para dados
  @data_cache :data_cache
  
  # TTL padrão para itens em cache (1 hora)
  @default_ttl 3_600_000
  
  # Número máximo de tentativas para operações de escrita
  @max_retries 3
  
  # Tempo de espera entre tentativas (em ms)
  @retry_delay 500
  
  @doc """
  Inicializa o repositório resiliente.
  
  Esta função deve ser chamada durante a inicialização da aplicação para
  configurar o CircuitBreaker e o Cache necessários.
  
  ## Parâmetros
  
  - `opts`: Opções de configuração
    - `:failure_threshold` - Número de falhas antes de abrir o circuito (padrão: 5)
    - `:reset_timeout_ms` - Tempo para resetar o circuito em ms (padrão: 30000)
    - `:cache_ttl` - TTL padrão para itens em cache em ms (padrão: 3600000)
  
  ## Retorno
  
  - `:ok` se a inicialização for bem-sucedida
  - `{:error, reason}` em caso de falha
  """
  @spec init(keyword()) :: :ok | {:error, term()}
  def init(opts \\ []) do
    # Extrai opções
    failure_threshold = Keyword.get(opts, :failure_threshold, 5)
    reset_timeout_ms = Keyword.get(opts, :reset_timeout_ms, 30_000)
    
    # Inicializa o cache
    Cache.start_cache(@data_cache)
    
    # Configura o CircuitBreaker para o serviço de banco de dados
    case CB.setup_breaker(@db_service, %{
      failure_threshold: failure_threshold,
      reset_timeout_ms: reset_timeout_ms
    }) do
      {:ok, _pid} -> :ok
      error -> error
    end
  end
  
  @doc """
  Busca um registro pelo ID com proteção de CircuitBreaker e fallback para cache.
  
  ## Parâmetros
  
  - `schema`: O módulo do schema Ecto
  - `id`: O ID do registro a ser buscado
  - `opts`: Opções adicionais
    - `:ttl` - TTL para o item em cache (padrão: 3600000)
    - `:force_refresh` - Se `true`, força a busca no banco de dados (padrão: false)
  
  ## Retorno
  
  - `{:ok, struct}` se o registro for encontrado
  - `{:error, :not_found}` se o registro não for encontrado
  - `{:error, reason}` em caso de falha
  """
  @spec get(module(), term(), keyword()) :: {:ok, Ecto.Schema.t()} | {:error, term()}
  def get(schema, id, opts \\ []) do
    # Extrai opções
    ttl = Keyword.get(opts, :ttl, @default_ttl)
    force_refresh = Keyword.get(opts, :force_refresh, false)
    
    # Cria a chave de cache
    cache_key = "#{schema}_#{id}"
    
    # Executa a operação com proteção de CircuitBreaker e fallback para cache
    case CacheIntegration.with_cache_fallback(
      @db_service,
      "get_#{schema}",
      cache_key,
      fn -> Repository.get(schema, id) end,
      @data_cache,
      [ttl: ttl, force_refresh: force_refresh]
    ) do
      {:ok, result, _source} -> {:ok, result}
      {:error, reason} -> {:error, reason}
    end
  end
  
  @doc """
  Lista registros com proteção de CircuitBreaker e fallback para cache.
  
  ## Parâmetros
  
  - `schema`: O módulo do schema Ecto
  - `filters`: Condições de filtro
  - `opts`: Opções adicionais
    - `:ttl` - TTL para o item em cache (padrão: 3600000)
    - `:force_refresh` - Se `true`, força a busca no banco de dados (padrão: false)
    - `:limit` - Limite de registros a serem retornados
    - `:offset` - Deslocamento para paginação
  
  ## Retorno
  
  - `{:ok, list_of_structs}` contendo a lista de registros
  - `{:error, reason}` em caso de falha
  """
  @spec list(module(), keyword(), keyword()) :: {:ok, list(Ecto.Schema.t())} | {:error, term()}
  def list(schema, filters \\ [], opts \\ []) do
    # Extrai opções
    ttl = Keyword.get(opts, :ttl, @default_ttl)
    force_refresh = Keyword.get(opts, :force_refresh, false)
    
    # Extrai opções de paginação
    pagination_opts = Keyword.take(opts, [:limit, :offset])
    
    # Cria a chave de cache baseada no schema, filtros e paginação
    filters_hash = :erlang.phash2(filters)
    pagination_hash = :erlang.phash2(pagination_opts)
    cache_key = "#{schema}_list_#{filters_hash}_#{pagination_hash}"
    
    # Executa a operação com proteção de CircuitBreaker e fallback para cache
    case CacheIntegration.with_cache_fallback(
      @db_service,
      "list_#{schema}",
      cache_key,
      fn -> Repository.list(schema, filters ++ pagination_opts) end,
      @data_cache,
      [ttl: ttl, force_refresh: force_refresh]
    ) do
      {:ok, result, _source} -> {:ok, result}
      {:error, reason} -> {:error, reason}
    end
  end
  
  @doc """
  Encontra registros com base em filtros, com proteção de CircuitBreaker e fallback para cache.
  
  ## Parâmetros
  
  - `schema`: O módulo do schema Ecto
  - `filters`: Condições de filtro
  - `opts`: Opções adicionais
    - `:ttl` - TTL para o item em cache (padrão: 3600000)
    - `:force_refresh` - Se `true`, força a busca no banco de dados (padrão: false)
    - `:limit` - Limite de registros a serem retornados
    - `:offset` - Deslocamento para paginação
  
  ## Retorno
  
  - `{:ok, list_of_structs}` contendo os registros encontrados
  - `{:error, reason}` em caso de falha
  """
  @spec find(module(), keyword(), keyword()) :: {:ok, list(Ecto.Schema.t())} | {:error, term()}
  def find(schema, filters, opts \\ []) do
    # Extrai opções
    ttl = Keyword.get(opts, :ttl, @default_ttl)
    force_refresh = Keyword.get(opts, :force_refresh, false)
    
    # Extrai opções de paginação
    pagination_opts = Keyword.take(opts, [:limit, :offset])
    
    # Cria a chave de cache baseada no schema, filtros e paginação
    filters_hash = :erlang.phash2(filters)
    pagination_hash = :erlang.phash2(pagination_opts)
    cache_key = "#{schema}_find_#{filters_hash}_#{pagination_hash}"
    
    # Executa a operação com proteção de CircuitBreaker e fallback para cache
    case CacheIntegration.with_cache_fallback(
      @db_service,
      "find_#{schema}",
      cache_key,
      fn -> Repository.find(schema, filters, pagination_opts) end,
      @data_cache,
      [ttl: ttl, force_refresh: force_refresh]
    ) do
      {:ok, result, _source} -> {:ok, result}
      {:error, reason} -> {:error, reason}
    end
  end
  
  @doc """
  Insere um novo registro com proteção de CircuitBreaker e política de retry.
  
  ## Parâmetros
  
  - `schema`: O módulo do schema Ecto
  - `attrs`: Atributos para o novo registro
  - `opts`: Opções adicionais
    - `:max_retries` - Número máximo de tentativas (padrão: 3)
    - `:retry_delay` - Tempo de espera entre tentativas em ms (padrão: 500)
  
  ## Retorno
  
  - `{:ok, struct}` se o registro for inserido com sucesso
  - `{:error, changeset}` em caso de falha na validação
  - `{:error, reason}` em caso de falha no banco de dados
  """
  @spec insert(module(), map(), keyword()) :: {:ok, Ecto.Schema.t()} | {:error, term()}
  def insert(schema, attrs, opts \\ []) do
    # Extrai opções
    max_retries = Keyword.get(opts, :max_retries, @max_retries)
    retry_delay = Keyword.get(opts, :retry_delay, @retry_delay)
    
    # Executa a operação com proteção de CircuitBreaker
    CB.protected_call(
      @db_service,
      "insert_#{schema}",
      fn -> 
        # Tenta a operação com retry
        do_with_retry(fn -> Repository.insert(schema, attrs) end, max_retries, retry_delay)
      end
    )
  end
  
  @doc """
  Atualiza um registro existente com proteção de CircuitBreaker e política de retry.
  
  ## Parâmetros
  
  - `struct`: A struct Ecto a ser atualizada
  - `attrs`: Novos atributos para o registro
  - `opts`: Opções adicionais
    - `:max_retries` - Número máximo de tentativas (padrão: 3)
    - `:retry_delay` - Tempo de espera entre tentativas em ms (padrão: 500)
    - `:invalidate_cache` - Se `true`, invalida o cache para este registro (padrão: true)
  
  ## Retorno
  
  - `{:ok, struct}` se o registro for atualizado com sucesso
  - `{:error, changeset}` em caso de falha na validação
  - `{:error, reason}` em caso de falha no banco de dados
  """
  @spec update(Ecto.Schema.t(), map(), keyword()) :: {:ok, Ecto.Schema.t()} | {:error, term()}
  def update(struct, attrs, opts \\ []) do
    # Extrai opções
    max_retries = Keyword.get(opts, :max_retries, @max_retries)
    retry_delay = Keyword.get(opts, :retry_delay, @retry_delay)
    invalidate_cache = Keyword.get(opts, :invalidate_cache, true)
    
    # Executa a operação com proteção de CircuitBreaker
    result = CB.protected_call(
      @db_service,
      "update_#{struct.__struct__}",
      fn -> 
        # Tenta a operação com retry
        do_with_retry(fn -> Repository.update(struct, attrs) end, max_retries, retry_delay)
      end
    )
    
    # Se a atualização for bem-sucedida e invalidate_cache for true, invalida o cache
    case result do
      {:ok, updated_struct} when invalidate_cache ->
        schema = updated_struct.__struct__
        id = Map.get(updated_struct, :id)
        
        if id do
          # Invalida o cache para o registro específico
          Cache.del(@data_cache, "#{schema}_#{id}")
          
          # Invalida caches de list e find, que podem conter este registro
          invalidate_list_caches(schema)
        end
        
        {:ok, updated_struct}
        
      _ ->
        result
    end
  end
  
  @doc """
  Deleta um registro com proteção de CircuitBreaker e política de retry.
  
  ## Parâmetros
  
  - `struct`: A struct Ecto a ser deletada
  - `opts`: Opções adicionais
    - `:max_retries` - Número máximo de tentativas (padrão: 3)
    - `:retry_delay` - Tempo de espera entre tentativas em ms (padrão: 500)
    - `:invalidate_cache` - Se `true`, invalida o cache para este registro (padrão: true)
  
  ## Retorno
  
  - `{:ok, struct}` se o registro for deletado com sucesso
  - `{:error, changeset}` em caso de falha
  - `{:error, reason}` em caso de falha no banco de dados
  """
  @spec delete(Ecto.Schema.t(), keyword()) :: {:ok, Ecto.Schema.t()} | {:error, term()}
  def delete(struct, opts \\ []) do
    # Extrai opções
    max_retries = Keyword.get(opts, :max_retries, @max_retries)
    retry_delay = Keyword.get(opts, :retry_delay, @retry_delay)
    invalidate_cache = Keyword.get(opts, :invalidate_cache, true)
    
    # Executa a operação com proteção de CircuitBreaker
    result = CB.protected_call(
      @db_service,
      "delete_#{struct.__struct__}",
      fn -> 
        # Tenta a operação com retry
        do_with_retry(fn -> Repository.delete(struct) end, max_retries, retry_delay)
      end
    )
    
    # Se a deleção for bem-sucedida e invalidate_cache for true, invalida o cache
    case result do
      {:ok, deleted_struct} when invalidate_cache ->
        schema = deleted_struct.__struct__
        id = Map.get(deleted_struct, :id)
        
        if id do
          # Invalida o cache para o registro específico
          Cache.del(@data_cache, "#{schema}_#{id}")
          
          # Invalida caches de list e find, que podem conter este registro
          invalidate_list_caches(schema)
        end
        
        {:ok, deleted_struct}
        
      _ ->
        result
    end
  end
  
  # Função privada para executar uma operação com retry
  defp do_with_retry(fun, retries_left, delay, last_error \\ nil)
  
  defp do_with_retry(_fun, 0, _delay, last_error) do
    # Sem mais tentativas, retorna o último erro
    last_error || {:error, :max_retries_exceeded}
  end
  
  defp do_with_retry(fun, retries_left, delay, _last_error) do
    # Tenta executar a função
    case fun.() do
      {:ok, _} = success ->
        # Operação bem-sucedida
        success
        
      {:error, %Ecto.Changeset{}} = validation_error ->
        # Erro de validação, não tenta novamente
        validation_error
        
      {:error, _} = error ->
        # Erro de banco de dados, tenta novamente após o delay
        Logger.warning("Falha na operação de banco de dados, tentando novamente", %{
          module: __MODULE__,
          retries_left: retries_left - 1,
          error: inspect(error)
        })
        
        # Registra métrica de retry
        Metrics.increment("deeper_hub.core.data.resilient_repository.retry", %{
          retries_left: retries_left - 1
        })
        
        # Aguarda o delay
        Process.sleep(delay)
        
        # Tenta novamente com uma tentativa a menos
        do_with_retry(fun, retries_left - 1, delay, error)
    end
  end
  
  # Função privada para invalidar caches de list e find para um schema
  defp invalidate_list_caches(schema) do
    # Obtém todas as chaves do cache
    case Cache.stats(@data_cache) do
      {:ok, stats} ->
        # Extrai o número de chaves
        keys_count = Map.get(stats, :keys, 0)
        
        # Se houver chaves, tenta invalidar as relacionadas ao schema
        if keys_count > 0 do
          # Padrões para identificar chaves de list e find para o schema
          list_pattern = "#{schema}_list_"
          find_pattern = "#{schema}_find_"
          
          # TODO: Implementar uma forma eficiente de listar e filtrar chaves do cache
          # Por enquanto, apenas registra que a invalidação seria necessária
          Logger.debug("Invalidação de cache necessária para listas e consultas", %{
            module: __MODULE__,
            schema: schema,
            list_pattern: list_pattern,
            find_pattern: find_pattern
          })
        end
        
      _ ->
        :ok
    end
  end
end
