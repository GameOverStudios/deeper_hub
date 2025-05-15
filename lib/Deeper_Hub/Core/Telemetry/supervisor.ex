defmodule Deeper_Hub.Core.Telemetry.Supervisor do
  @moduledoc """
  Supervisor para o sistema de telemetria do DeeperHub.
  
  Este módulo é responsável por iniciar e supervisionar os processos
  relacionados ao sistema de telemetria, garantindo que os handlers
  sejam registrados corretamente e que o sistema de telemetria esteja
  sempre disponível.
  
  ## Responsabilidades
  
  * 🚀 Inicializar o sistema de telemetria
  * 📊 Registrar handlers padrão para eventos importantes
  * 🔄 Garantir a disponibilidade do sistema de telemetria
  * 🛡️ Supervisionar processos relacionados à telemetria
  """
  
  use Supervisor
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Telemetry.Events
  alias Deeper_Hub.Core.Telemetry.Handlers
  alias Deeper_Hub.Core.Telemetry.TelemetryFacade
  
  @doc """
  Inicia o supervisor de telemetria.
  
  ## Retorno
  
    * `{:ok, pid}` - Supervisor iniciado com sucesso
    * `{:error, reason}` - Falha ao iniciar o supervisor
  """
  @spec start_link(term()) :: Supervisor.on_start()
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end
  
  @doc """
  Inicializa o supervisor e registra os handlers padrão.
  
  ## Parâmetros
  
    * `init_arg` - Argumentos de inicialização (não utilizados)
    
  ## Retorno
  
    * `{:ok, {supervisor_flags, child_specs}}` - Configuração do supervisor
  """
  @impl Supervisor
  def init(_init_arg) do
    Logger.info("Inicializando supervisor de telemetria", %{module: __MODULE__})
    
    # Registra os handlers padrão para eventos importantes
    register_default_handlers()
    
    # Define os processos filhos a serem supervisionados
    children = [
      # Por enquanto, não há processos filhos específicos para telemetria
      # No futuro, poderiam ser adicionados processos como coletores de métricas
    ]
    
    # Inicia o supervisor com a estratégia one_for_one
    Supervisor.init(children, strategy: :one_for_one)
  end
  
  @doc """
  Registra os handlers padrão para eventos importantes do sistema.
  
  Esta função é chamada durante a inicialização do supervisor e
  anexa handlers para os eventos mais relevantes do sistema.
  
  ## Retorno
  
    * `:ok` - Handlers registrados com sucesso
  """
  @spec register_default_handlers() :: :ok
  def register_default_handlers do
    Logger.debug("Registrando handlers padrão de telemetria", %{module: __MODULE__})
    
    # Handler para eventos de cache
    :ok =
      TelemetryFacade.attach_many(
        "deeper-hub-cache-handler",
        [
          Events.cache_hit(),
          Events.cache_miss(),
          Events.cache_put(),
          Events.cache_get(),
          Events.cache_delete(),
          Events.cache_clear()
        ],
        &Handlers.handle_cache_event/4,
        nil
      )
    
    # Handler para eventos de repositório
    :ok =
      TelemetryFacade.attach_many(
        "deeper-hub-repository-handler",
        [
          Events.start(Events.repository_query()),
          Events.stop(Events.repository_query()),
          Events.exception(Events.repository_query()),
          Events.start(Events.repository_insert()),
          Events.stop(Events.repository_insert()),
          Events.exception(Events.repository_insert()),
          Events.start(Events.repository_update()),
          Events.stop(Events.repository_update()),
          Events.exception(Events.repository_update()),
          Events.start(Events.repository_delete()),
          Events.stop(Events.repository_delete()),
          Events.exception(Events.repository_delete())
        ],
        &Handlers.handle_repository_event/4,
        nil
      )
    
    # Handler para eventos HTTP
    :ok =
      TelemetryFacade.attach_many(
        "deeper-hub-http-handler",
        [
          Events.http_request(),
          Events.http_response()
        ],
        &Handlers.handle_http_event/4,
        nil
      )
    
    # Handler para eventos de autenticação
    :ok =
      TelemetryFacade.attach_many(
        "deeper-hub-auth-handler",
        [
          Events.auth_login(),
          Events.auth_logout(),
          Events.auth_failure()
        ],
        &Handlers.handle_auth_event/4,
        nil
      )
    
    Logger.info("Handlers padrão de telemetria registrados com sucesso", %{module: __MODULE__})
    
    :ok
  end
end
