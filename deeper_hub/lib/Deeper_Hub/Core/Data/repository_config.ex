defmodule Deeper_Hub.Core.Data.RepositoryConfig do
  @moduledoc """
  Módulo de configuração para os componentes do repositório.
  
  Este módulo centraliza todas as configurações relacionadas aos componentes
  do repositório, como cache, circuit breaker, telemetria e métricas.
  
  As configurações podem ser definidas no arquivo de configuração da aplicação:
  
  ```elixir
  # No arquivo config.exs ou ambiente específico (dev.exs, prod.exs, etc.)
  config :deeper_hub, Deeper_Hub.Core.Data.RepositoryConfig,
    cache: [
      ttl: 300_000,
      max_size: 1000
    ],
    circuit_breaker: [
      max_failures: 5,
      reset_timeout: 30_000,
      half_open_threshold: 2
    ]
  ```
  """
  
  alias Deeper_Hub.Core.Logger
  
  @doc """
  Obtém as configurações de cache.
  
  ## Retorno
  
  - Mapa com as configurações de cache
  """
  def cache_config do
    app_config = Application.get_env(:deeper_hub, __MODULE__, [])
    cache_config = Keyword.get(app_config, :cache, [])
    
    # Valores padrão
    defaults = %{
      ttl: 300_000,  # 5 minutos
      max_size: 1000,
      query_ttl: 60_000,  # 1 minuto para consultas
      enabled: true
    }
    
    # Mescla as configurações fornecidas com os valores padrão
    config = Map.merge(defaults, Enum.into(cache_config, %{}))
    
    Logger.debug("Configurações de cache carregadas", %{
      module: __MODULE__,
      config: config
    })
    
    config
  end
  
  @doc """
  Obtém as configurações de circuit breaker.
  
  ## Retorno
  
  - Mapa com as configurações de circuit breaker
  """
  def circuit_breaker_config do
    app_config = Application.get_env(:deeper_hub, __MODULE__, [])
    cb_config = Keyword.get(app_config, :circuit_breaker, [])
    
    # Valores padrão
    defaults = %{
      max_failures: 5,
      reset_timeout: 30_000,  # 30 segundos
      half_open_threshold: 2,
      enabled: true
    }
    
    # Mescla as configurações fornecidas com os valores padrão
    config = Map.merge(defaults, Enum.into(cb_config, %{}))
    
    Logger.debug("Configurações de circuit breaker carregadas", %{
      module: __MODULE__,
      config: config
    })
    
    config
  end
  
  @doc """
  Obtém as configurações de telemetria.
  
  ## Retorno
  
  - Mapa com as configurações de telemetria
  """
  def telemetry_config do
    app_config = Application.get_env(:deeper_hub, __MODULE__, [])
    telemetry_config = Keyword.get(app_config, :telemetry, [])
    
    # Valores padrão
    defaults = %{
      enabled: true,
      log_level: :debug
    }
    
    # Mescla as configurações fornecidas com os valores padrão
    config = Map.merge(defaults, Enum.into(telemetry_config, %{}))
    
    Logger.debug("Configurações de telemetria carregadas", %{
      module: __MODULE__,
      config: config
    })
    
    config
  end
  
  @doc """
  Obtém as configurações de métricas.
  
  ## Retorno
  
  - Mapa com as configurações de métricas
  """
  def metrics_config do
    app_config = Application.get_env(:deeper_hub, __MODULE__, [])
    metrics_config = Keyword.get(app_config, :metrics, [])
    
    # Valores padrão
    defaults = %{
      enabled: true,
      prefix: "deeper_hub.core.data.repository"
    }
    
    # Mescla as configurações fornecidas com os valores padrão
    config = Map.merge(defaults, Enum.into(metrics_config, %{}))
    
    Logger.debug("Configurações de métricas carregadas", %{
      module: __MODULE__,
      config: config
    })
    
    config
  end
  
  @doc """
  Obtém as configurações de eventos.
  
  ## Retorno
  
  - Mapa com as configurações de eventos
  """
  def event_config do
    app_config = Application.get_env(:deeper_hub, __MODULE__, [])
    event_config = Keyword.get(app_config, :events, [])
    
    # Valores padrão
    defaults = %{
      enabled: true,
      publish_insert: true,
      publish_update: true,
      publish_delete: true,
      publish_query: false  # Por padrão, não publica eventos de consulta para reduzir o volume
    }
    
    # Mescla as configurações fornecidas com os valores padrão
    config = Map.merge(defaults, Enum.into(event_config, %{}))
    
    Logger.debug("Configurações de eventos carregadas", %{
      module: __MODULE__,
      config: config
    })
    
    config
  end
  
  @doc """
  Verifica se o cache está habilitado.
  
  ## Retorno
  
  - `true` se o cache estiver habilitado
  - `false` caso contrário
  """
  def cache_enabled? do
    cache_config().enabled
  end
  
  @doc """
  Verifica se o circuit breaker está habilitado.
  
  ## Retorno
  
  - `true` se o circuit breaker estiver habilitado
  - `false` caso contrário
  """
  def circuit_breaker_enabled? do
    circuit_breaker_config().enabled
  end
  
  @doc """
  Verifica se a telemetria está habilitada.
  
  ## Retorno
  
  - `true` se a telemetria estiver habilitada
  - `false` caso contrário
  """
  def telemetry_enabled? do
    telemetry_config().enabled
  end
  
  @doc """
  Verifica se as métricas estão habilitadas.
  
  ## Retorno
  
  - `true` se as métricas estiverem habilitadas
  - `false` caso contrário
  """
  def metrics_enabled? do
    metrics_config().enabled
  end
  
  @doc """
  Verifica se a publicação de eventos está habilitada.
  
  ## Retorno
  
  - `true` se a publicação de eventos estiver habilitada
  - `false` caso contrário
  """
  def events_enabled? do
    event_config().enabled
  end
  
  @doc """
  Verifica se a publicação de eventos de inserção está habilitada.
  
  ## Retorno
  
  - `true` se a publicação de eventos de inserção estiver habilitada
  - `false` caso contrário
  """
  def publish_insert_events? do
    config = event_config()
    config.enabled && config.publish_insert
  end
  
  @doc """
  Verifica se a publicação de eventos de atualização está habilitada.
  
  ## Retorno
  
  - `true` se a publicação de eventos de atualização estiver habilitada
  - `false` caso contrário
  """
  def publish_update_events? do
    config = event_config()
    config.enabled && config.publish_update
  end
  
  @doc """
  Verifica se a publicação de eventos de exclusão está habilitada.
  
  ## Retorno
  
  - `true` se a publicação de eventos de exclusão estiver habilitada
  - `false` caso contrário
  """
  def publish_delete_events? do
    config = event_config()
    config.enabled && config.publish_delete
  end
  
  @doc """
  Verifica se a publicação de eventos de consulta está habilitada.
  
  ## Retorno
  
  - `true` se a publicação de eventos de consulta estiver habilitada
  - `false` caso contrário
  """
  def publish_query_events? do
    config = event_config()
    config.enabled && config.publish_query
  end
end
