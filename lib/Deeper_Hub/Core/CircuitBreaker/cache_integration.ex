defmodule Deeper_Hub.Core.CircuitBreaker.CacheIntegration do
  @moduledoc """
  Fornece integração entre o CircuitBreaker e o Cache para operações resilientes com fallback.
  
  Este módulo permite que operações protegidas pelo CircuitBreaker utilizem o Cache como
  mecanismo de fallback, garantindo que mesmo quando um serviço estiver indisponível,
  os dados em cache possam ser utilizados como alternativa.
  
  ## Funcionalidades
  
  * 🔄 Execução de operações com fallback automático para cache
  * 📦 Armazenamento automático de resultados bem-sucedidos no cache
  * ⏱️ Configuração de TTL para dados em cache
  * 📊 Métricas detalhadas sobre hits/misses de cache durante fallbacks
  * 🔍 Logging aprimorado para diagnóstico de problemas
  
  ## Exemplo de Uso
  
  ```elixir
  alias Deeper_Hub.Core.CircuitBreaker.CacheIntegration
  
  # Executar operação com fallback para cache
  CacheIntegration.with_cache_fallback(
    :external_api,           # Nome do serviço
    "get_user_data",         # Nome da operação
    "user:123",              # Chave de cache
    fn -> 
      # Função que busca os dados do serviço externo
      {:ok, HTTPClient.get("https://api.example.com/users/123")}
    end,
    :user_cache,             # Nome do cache
    [ttl: 3600000]           # Opções (TTL de 1 hora)
  )
  ```
  """
  
  alias Deeper_Hub.Core.CircuitBreaker.Integration, as: CB
  alias Deeper_Hub.Core.Cache.CacheFacade, as: Cache
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Metrics.MetricsFacade, as: Metrics
  alias Deeper_Hub.Core.EventBus.EventBusFacade, as: EventBus
  
  @doc """
  Executa uma operação protegida pelo CircuitBreaker com fallback para cache.
  
  ## Parâmetros
  
    - `service_name`: Nome do serviço protegido pelo circuit breaker
    - `operation_name`: Nome da operação (para logs e métricas)
    - `cache_key`: Chave usada para armazenar/recuperar o valor no cache
    - `operation_fun`: Função que realiza a operação protegida (deve retornar {:ok, result} ou {:error, reason})
    - `cache_name`: Nome do cache a ser utilizado
    - `options`: Opções adicionais como TTL para o cache
  
  ## Opções
  
    - `:ttl`: Tempo de vida do item no cache em milissegundos (padrão: 3600000 - 1 hora)
    - `:stale_fallback`: Se `true`, usa dados em cache mesmo se expirados quando o serviço falhar (padrão: true)
    - `:skip_cache_check`: Se `true`, sempre tenta a operação principal primeiro sem verificar o cache (padrão: false)
    - `:force_refresh`: Se `true`, força a execução da operação principal e atualiza o cache (padrão: false)
    - `:circuit_breaker_opts`: Opções específicas para o CircuitBreaker
  
  ## Retorno
  
    - `{:ok, value, :origin}` - Operação bem-sucedida, dados obtidos da origem
    - `{:ok, value, :cache}` - Operação falhou, dados obtidos do cache
    - `{:error, reason}` - Operação falhou e não havia dados em cache
  
  ## Exemplo
  
  ```elixir
  CacheIntegration.with_cache_fallback(
    :external_api, 
    "get_user_profile",
    "user:123",
    fn -> 
      {:ok, HTTPClient.get("https://api.example.com/users/123")}
    end,
    :user_cache,
    [ttl: 86400000] # 24 horas
  )
  ```
  """
  @spec with_cache_fallback(atom(), String.t(), term(), (-> {:ok, term()} | {:error, term()}), atom(), Keyword.t()) ::
          {:ok, term(), :origin} | {:ok, term(), :cache} | {:error, term()}
  def with_cache_fallback(service_name, operation_name, cache_key, operation_fun, cache_name, options \\ []) do
    # Extrai opções
    ttl = Keyword.get(options, :ttl, 3_600_000) # 1 hora por padrão
    stale_fallback = Keyword.get(options, :stale_fallback, true)
    skip_cache_check = Keyword.get(options, :skip_cache_check, false)
    force_refresh = Keyword.get(options, :force_refresh, false)
    circuit_breaker_opts = Keyword.get(options, :circuit_breaker_opts, [])
    
    # Prepara o contexto de telemetria
    metadata = %{
      service_name: service_name,
      operation_name: operation_name,
      cache_name: cache_name,
      cache_key: cache_key
    }
    
    # Registra o início da operação
    start_time = System.monotonic_time(:millisecond)
    Logger.debug("Iniciando operação com fallback para cache", Map.merge(metadata, %{
      module: __MODULE__,
      options: options
    }))
    
    # Verifica se devemos tentar o cache primeiro
    if not skip_cache_check and not force_refresh do
      # Tenta obter do cache primeiro
      case Cache.get(cache_name, cache_key) do
        {:ok, value} when not is_nil(value) ->
          # Encontrou no cache, registra métricas e retorna
          duration_ms = System.monotonic_time(:millisecond) - start_time
          
          Logger.debug("Valor encontrado no cache", Map.merge(metadata, %{
            module: __MODULE__,
            duration_ms: duration_ms
          }))
          
          Metrics.increment("deeper_hub.core.circuit_breaker.cache_integration.cache_hit", %{
            service_name: service_name,
            operation_name: operation_name
          })
          
          # Verifica se devemos forçar a atualização mesmo com cache hit
          if force_refresh do
            # Executa a operação em background para atualizar o cache
            Task.start(fn -> 
              execute_and_cache(service_name, operation_name, cache_key, operation_fun, cache_name, ttl, circuit_breaker_opts)
            end)
          end
          
          {:ok, value, :cache}
          
        _ ->
          # Não encontrou no cache, executa a operação protegida
          execute_and_cache(service_name, operation_name, cache_key, operation_fun, cache_name, ttl, circuit_breaker_opts)
      end
    else
      # Pula a verificação do cache, executa diretamente a operação protegida
      execute_and_cache(service_name, operation_name, cache_key, operation_fun, cache_name, ttl, circuit_breaker_opts)
    end
  end
  
  @doc """
  Executa uma operação protegida pelo CircuitBreaker com fallback para cache, usando uma função de transformação.
  
  Similar a `with_cache_fallback/6`, mas permite especificar uma função para transformar o resultado antes de armazenar no cache.
  
  ## Parâmetros adicionais
  
    - `transform_fun`: Função que transforma o resultado antes de armazenar no cache
  
  ## Exemplo
  
  ```elixir
  CacheIntegration.with_cache_fallback_transform(
    :external_api, 
    "get_user_profile",
    "user:123",
    fn -> 
      {:ok, HTTPClient.get("https://api.example.com/users/123")}
    end,
    fn {:ok, data} -> 
      # Transforma os dados antes de armazenar no cache
      {:ok, Map.take(data, [:id, :name, :email])}
    end,
    :user_cache,
    [ttl: 86400000] # 24 horas
  )
  ```
  """
  @spec with_cache_fallback_transform(
          atom(),
          String.t(),
          term(),
          (-> {:ok, term()} | {:error, term()}),
          (({:ok, term()} -> {:ok, term()})),
          atom(),
          Keyword.t()
        ) ::
          {:ok, term(), :origin} | {:ok, term(), :cache} | {:error, term()}
  def with_cache_fallback_transform(
        service_name,
        operation_name,
        cache_key,
        operation_fun,
        transform_fun,
        cache_name,
        options \\ []
      ) do
    # Cria uma nova função que aplica a transformação
    transformed_operation = fn ->
      case operation_fun.() do
        {:ok, result} ->
          # Aplica a função de transformação
          transform_fun.({:ok, result})
        error ->
          error
      end
    end
    
    # Usa a implementação padrão com a operação transformada
    with_cache_fallback(service_name, operation_name, cache_key, transformed_operation, cache_name, options)
  end
  
  @doc """
  Invalida uma entrada no cache e força uma atualização através da operação protegida.
  
  ## Parâmetros
  
    - `service_name`: Nome do serviço protegido pelo circuit breaker
    - `operation_name`: Nome da operação (para logs e métricas)
    - `cache_key`: Chave a ser invalidada e atualizada
    - `operation_fun`: Função que realiza a operação protegida
    - `cache_name`: Nome do cache a ser utilizado
    - `options`: Opções adicionais como TTL para o cache
  
  ## Retorno
  
    - `{:ok, value, :origin}` - Operação bem-sucedida, cache atualizado
    - `{:error, reason}` - Falha ao atualizar o cache
  
  ## Exemplo
  
  ```elixir
  CacheIntegration.invalidate_and_refresh(
    :external_api, 
    "get_user_profile",
    "user:123",
    fn -> 
      {:ok, HTTPClient.get("https://api.example.com/users/123")}
    end,
    :user_cache
  )
  ```
  """
  @spec invalidate_and_refresh(atom(), String.t(), term(), (-> {:ok, term()} | {:error, term()}), atom(), Keyword.t()) ::
          {:ok, term(), :origin} | {:error, term()}
  def invalidate_and_refresh(service_name, operation_name, cache_key, operation_fun, cache_name, options \\ []) do
    # Prepara o contexto de telemetria
    metadata = %{
      service_name: service_name,
      operation_name: operation_name,
      cache_name: cache_name,
      cache_key: cache_key
    }
    
    # Registra o início da operação
    Logger.debug("Invalidando e atualizando cache", Map.merge(metadata, %{
      module: __MODULE__
    }))
    
    # Invalida a entrada no cache
    Cache.del(cache_name, cache_key)
    
    # Força a atualização
    options = Keyword.put(options, :force_refresh, true)
    options = Keyword.put(options, :skip_cache_check, true)
    
    # Executa a operação protegida
    with_cache_fallback(service_name, operation_name, cache_key, operation_fun, cache_name, options)
  end
  
  # Função privada para executar a operação e armazenar no cache
  defp execute_and_cache(service_name, operation_name, cache_key, operation_fun, cache_name, ttl, circuit_breaker_opts) do
    # Prepara o contexto de telemetria
    metadata = %{
      service_name: service_name,
      operation_name: operation_name,
      cache_name: cache_name,
      cache_key: cache_key
    }
    
    # Executa a operação protegida pelo circuit breaker
    fallback_fun = fn _error ->
      # Tenta obter do cache como fallback
      case Cache.get(cache_name, cache_key) do
        {:ok, value} when not is_nil(value) ->
          # Encontrou no cache como fallback
          Logger.info("Usando valor em cache como fallback", Map.merge(metadata, %{
            module: __MODULE__,
            reason: "circuit_breaker_fallback"
          }))
          
          Metrics.increment("deeper_hub.core.circuit_breaker.cache_integration.fallback_hit", %{
            service_name: service_name,
            operation_name: operation_name
          })
          
          # Publica evento de fallback para cache
          EventBus.publish("circuit_breaker.cache_fallback", %{
            service_name: service_name,
            operation_name: operation_name,
            cache_key: cache_key,
            timestamp: DateTime.utc_now()
          })
          
          {:ok, value, :cache}
          
        _ ->
          # Não encontrou no cache, registra e propaga o erro
          Logger.warning("Falha na operação e cache vazio", Map.merge(metadata, %{
            module: __MODULE__
          }))
          
          Metrics.increment("deeper_hub.core.circuit_breaker.cache_integration.complete_miss", %{
            service_name: service_name,
            operation_name: operation_name
          })
          
          {:error, :service_unavailable_and_no_cache}
      end
    end
    
    # Executa a operação com o circuit breaker
    case CB.protected_call(service_name, operation_name, operation_fun, fallback_fun, circuit_breaker_opts) do
      {:ok, result} ->
        # Operação bem-sucedida, armazena no cache
        Cache.put(cache_name, cache_key, result, [ttl: ttl])
        
        Logger.debug("Operação bem-sucedida, valor armazenado no cache", Map.merge(metadata, %{
          module: __MODULE__,
          ttl: ttl
        }))
        
        Metrics.increment("deeper_hub.core.circuit_breaker.cache_integration.origin_success", %{
          service_name: service_name,
          operation_name: operation_name
        })
        
        {:ok, result, :origin}
        
      {:ok, result, :cache} ->
        # Resultado veio do cache via fallback
        {:ok, result, :cache}
        
      error ->
        # Propaga o erro
        Logger.error("Falha na operação e no fallback", Map.merge(metadata, %{
          module: __MODULE__,
          error: inspect(error)
        }))
        
        error
    end
  end
end
