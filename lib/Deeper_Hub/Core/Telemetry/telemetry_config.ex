defmodule Deeper_Hub.Core.Telemetry.TelemetryConfig do
  @moduledoc """
  Configuração e inicialização do sistema de telemetria do DeeperHub. 🔧
  
  Este módulo é responsável por configurar o sistema de telemetria durante
  a inicialização da aplicação, definindo eventos padrão e handlers.
  """
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Telemetry
  
  @doc """
  Inicializa o sistema de telemetria.
  
  Esta função deve ser chamada durante a inicialização da aplicação para
  configurar o sistema de telemetria com os eventos e handlers padrão.
  
  ## Retorno
  
  - `:ok` se a inicialização for bem-sucedida
  """
  @spec initialize() :: :ok
  def initialize do
    Logger.info("Inicializando sistema de telemetria", %{module: __MODULE__})
    
    # Configura telemetria com eventos e handlers padrão
    Telemetry.setup(default_handlers(), default_events())
    
    Logger.info("Sistema de telemetria inicializado com sucesso", %{module: __MODULE__})
    :ok
  end
  
  @doc """
  Retorna a lista de handlers padrão para telemetria.
  
  ## Retorno
  
  - Lista de tuplas {módulo, função} que serão usadas como handlers
  """
  @spec default_handlers() :: list()
  def default_handlers do
    [
      # Handler padrão para logging e métricas
      {Deeper_Hub.Core.Telemetry, :handle_event}
    ]
  end
  
  @doc """
  Retorna a lista de eventos padrão para telemetria.
  
  ## Retorno
  
  - Lista de eventos no formato [:namespace, :entity, :action, :type]
  """
  @spec default_events() :: list()
  def default_events do
    # Eventos para o módulo de autenticação
    auth_events = [
      [:deeper_hub, :auth, :login, :start],
      [:deeper_hub, :auth, :login, :stop],
      [:deeper_hub, :auth, :login, :exception],
      [:deeper_hub, :auth, :logout, :start],
      [:deeper_hub, :auth, :logout, :stop],
      [:deeper_hub, :auth, :logout, :exception],
      [:deeper_hub, :auth, :token, :validate, :start],
      [:deeper_hub, :auth, :token, :validate, :stop],
      [:deeper_hub, :auth, :token, :validate, :exception]
    ]
    
    # Eventos para o módulo de dados
    data_events = [
      [:deeper_hub, :data, :repository, :get, :start],
      [:deeper_hub, :data, :repository, :get, :stop],
      [:deeper_hub, :data, :repository, :get, :exception],
      [:deeper_hub, :data, :repository, :insert, :start],
      [:deeper_hub, :data, :repository, :insert, :stop],
      [:deeper_hub, :data, :repository, :insert, :exception],
      [:deeper_hub, :data, :repository, :update, :start],
      [:deeper_hub, :data, :repository, :update, :stop],
      [:deeper_hub, :data, :repository, :update, :exception],
      [:deeper_hub, :data, :repository, :delete, :start],
      [:deeper_hub, :data, :repository, :delete, :stop],
      [:deeper_hub, :data, :repository, :delete, :exception],
      [:deeper_hub, :data, :repository, :find, :start],
      [:deeper_hub, :data, :repository, :find, :stop],
      [:deeper_hub, :data, :repository, :find, :exception]
    ]
    
    # Eventos para o módulo de API
    api_events = [
      [:deeper_hub, :api, :request, :start],
      [:deeper_hub, :api, :request, :stop],
      [:deeper_hub, :api, :request, :exception]
    ]
    
    # Eventos para o módulo de sistema
    system_events = [
      [:deeper_hub, :system, :startup, :start],
      [:deeper_hub, :system, :startup, :stop],
      [:deeper_hub, :system, :startup, :exception],
      [:deeper_hub, :system, :shutdown, :start],
      [:deeper_hub, :system, :shutdown, :stop],
      [:deeper_hub, :system, :shutdown, :exception]
    ]
    
    # Combina todos os eventos
    auth_events ++ data_events ++ api_events ++ system_events
  end
end
