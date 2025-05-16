defmodule Deeper_Hub.Core.Data.RepositoryIntegration do
  @moduledoc """
  Módulo de integração central para todos os componentes do repositório.
  
  Este módulo centraliza a inicialização e configuração de todos os componentes
  relacionados ao repositório, como telemetria, cache, circuit breaker e métricas.
  
  ## Uso
  
  Este módulo deve ser inicializado durante a inicialização da aplicação:
  
  ```elixir
  # No arquivo application.ex
  def start(_type, _args) do
    # Inicializa a integração do repositório com os schemas da aplicação
    Deeper_Hub.Core.Data.RepositoryIntegration.setup([
      MyApp.Schemas.User,
      MyApp.Schemas.Product,
      MyApp.Schemas.Order
    ])
    
    # ...
  end
  ```
  """
  
  alias Deeper_Hub.Core.Data.RepositoryTelemetry
  alias Deeper_Hub.Core.Data.RepositoryCache
  alias Deeper_Hub.Core.Data.RepositoryCircuitBreaker
  alias Deeper_Hub.Core.Data.RepositoryMetrics
  alias Deeper_Hub.Core.Data.RepositoryConfig
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Cache.CacheFacade, as: Cache
  
  @doc """
  Inicializa todos os componentes do repositório para os schemas fornecidos.
  
  Esta função deve ser chamada durante a inicialização da aplicação para
  garantir que todos os componentes estejam configurados corretamente.
  
  ## Parâmetros
  
  - `schemas` - Lista de schemas Ecto para os quais configurar os componentes
  
  ## Retorno
  
  - `:ok` - Se todos os componentes forem inicializados com sucesso
  """
  def setup(schemas) when is_list(schemas) do
    Logger.info("Inicializando componentes do repositório", %{
      module: __MODULE__,
      schemas: Enum.map(schemas, &inspect/1)
    })
    
    # Carrega as configurações
    cache_config = RepositoryConfig.cache_config()
    circuit_breaker_config = RepositoryConfig.circuit_breaker_config()
    _telemetry_config = RepositoryConfig.telemetry_config()
    _metrics_config = RepositoryConfig.metrics_config()
    
    # Inicializa telemetria se estiver habilitada
    if RepositoryConfig.telemetry_enabled?() do
      RepositoryTelemetry.setup()
      Logger.info("Telemetria inicializada", %{module: __MODULE__})
    else
      Logger.info("Telemetria desabilitada pela configuração", %{module: __MODULE__})
    end
    
    # Inicializa métricas se estiverem habilitadas
    if RepositoryConfig.metrics_enabled?() do
      RepositoryMetrics.setup()
      Logger.info("Métricas inicializadas", %{module: __MODULE__})
    else
      Logger.info("Métricas desabilitadas pela configuração", %{module: __MODULE__})
    end
    
    # Inicializa cache se estiver habilitado
    if RepositoryConfig.cache_enabled?() do
      RepositoryCache.setup(schemas)
      Logger.info("Cache inicializado", %{
        module: __MODULE__,
        ttl: cache_config.ttl,
        max_size: cache_config.max_size
      })
    else
      Logger.info("Cache desabilitado pela configuração", %{module: __MODULE__})
    end
    
    # Inicializa circuit breaker se estiver habilitado
    if RepositoryConfig.circuit_breaker_enabled?() do
      RepositoryCircuitBreaker.setup(schemas)
      Logger.info("Circuit breaker inicializado", %{
        module: __MODULE__,
        max_failures: circuit_breaker_config.max_failures,
        reset_timeout: circuit_breaker_config.reset_timeout
      })
    else
      Logger.info("Circuit breaker desabilitado pela configuração", %{module: __MODULE__})
    end
    
    Logger.info("Componentes do repositório inicializados com sucesso", %{
      module: __MODULE__,
      schemas: Enum.map(schemas, &inspect/1)
    })
    
    :ok
  end
  
  @doc """
  Reinicia todos os componentes do repositório para os schemas fornecidos.
  
  Esta função pode ser chamada para reiniciar os componentes em caso de
  problemas ou para aplicar novas configurações.
  
  ## Parâmetros
  
  - `schemas` - Lista de schemas Ecto para os quais reiniciar os componentes
  
  ## Retorno
  
  - `:ok` - Se todos os componentes forem reiniciados com sucesso
  """
  def restart(schemas) when is_list(schemas) do
    Logger.info("Reiniciando componentes do repositório", %{
      module: __MODULE__,
      schemas: Enum.map(schemas, &inspect/1)
    })
    
    # Limpa o cache para cada schema se estiver habilitado
    if RepositoryConfig.cache_enabled?() do
      Enum.each(schemas, &RepositoryCache.invalidate_schema/1)
      Logger.info("Cache reiniciado", %{module: __MODULE__})
    end
    
    # Reseta os circuit breakers para cada schema se estiver habilitado
    if RepositoryConfig.circuit_breaker_enabled?() do
      Enum.each(schemas, &RepositoryCircuitBreaker.reset/1)
      Logger.info("Circuit breakers resetados", %{module: __MODULE__})
    end
    
    # Reinicializa telemetria se estiver habilitada
    if RepositoryConfig.telemetry_enabled?() do
      RepositoryTelemetry.setup()
      Logger.info("Telemetria reinicializada", %{module: __MODULE__})
    end
    
    Logger.info("Componentes do repositório reiniciados com sucesso", %{
      module: __MODULE__,
      schemas: Enum.map(schemas, &inspect/1)
    })
    
    :ok
  end
  
  @doc """
  Obtém o estado atual de todos os componentes do repositório para um schema específico.
  
  Esta função é útil para diagnóstico e monitoramento.
  
  ## Parâmetros
  
  - `schema` - O schema Ecto para o qual obter o estado
  
  ## Retorno
  
  - `map` - Um mapa contendo o estado de cada componente
  """
  def get_status(schema) do
    # Obtém as configurações
    cache_enabled = RepositoryConfig.cache_enabled?()
    circuit_breaker_enabled = RepositoryConfig.circuit_breaker_enabled?()
    telemetry_enabled = RepositoryConfig.telemetry_enabled?()
    metrics_enabled = RepositoryConfig.metrics_enabled?()
    events_enabled = RepositoryConfig.events_enabled?()
    
    # Inicializa o resultado com informações básicas
    result = %{
      schema: schema,
      config: %{
        cache_enabled: cache_enabled,
        circuit_breaker_enabled: circuit_breaker_enabled,
        telemetry_enabled: telemetry_enabled,
        metrics_enabled: metrics_enabled,
        events_enabled: events_enabled
      }
    }
    
    # Adiciona informações do circuit breaker se estiver habilitado
    result = if circuit_breaker_enabled do
      read_circuit_state = RepositoryCircuitBreaker.get_read_state(schema)
      write_circuit_state = RepositoryCircuitBreaker.get_write_state(schema)
      
      Map.put(result, :circuit_breaker, %{
        read: read_circuit_state,
        write: write_circuit_state
      })
    else
      result
    end
    
    # Adiciona informações do cache se estiver habilitado
    result = if cache_enabled do
      {:ok, record_cache_size} = Cache.size("repository:#{get_schema_name(schema)}:records")
      {:ok, query_cache_size} = Cache.size("repository:#{get_schema_name(schema)}:queries")
      
      Map.put(result, :cache, %{
        records: record_cache_size,
        queries: query_cache_size,
        total: record_cache_size + query_cache_size
      })
    else
      result
    end
    
    # Retorna o estado consolidado
    result
  end
  
  # Funções privadas auxiliares
  
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
end
