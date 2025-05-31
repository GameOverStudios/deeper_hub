# lib/deeper_hub/application.ex
defmodule DeeperHub.Application do
  @moduledoc """
  O callback da aplicação para o DeeperHub.
  Este módulo é responsável por iniciar e supervisionar os processos
  principais da aplicação.
  """
  use Application

  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Config.SystemConfig

  @impl true
  def start(_type, _args) do
    DeeperHub.Core.Logger.info("Iniciando o sistema DeeperHub...")

    # Aplica configurações do sistema antes de inicializar qualquer serviço
    :ok = SystemConfig.apply_system_config()

    # Valida configurações
    case SystemConfig.validate_config() do
      :ok ->
        DeeperHub.Core.Logger.info("Configurações validadas com sucesso")

        # Inicializa primeiro apenas o repositório para garantir que o banco de dados esteja disponível
        # antes de qualquer outra operação
        init_repo_result = init_repository()

        case init_repo_result do
          {:ok, _repo_pid} ->
            DeeperHub.Core.Logger.info("Repositório inicializado. Executando migrações...")

            # Executar migrações de forma síncrona antes de iniciar outros serviços
            case DeeperHub.Core.Data.Migrations.initialize() do
              :ok ->
                DeeperHub.Core.Logger.info("Migrações aplicadas com sucesso. Inicializando demais serviços.")
                init_main_supervisors()

              {:error, reason} ->
                DeeperHub.Core.Logger.error("Falha ao inicializar migrações: #{inspect(reason)}")
                {:error, reason}
            end

          {:error, reason} ->
            DeeperHub.Core.Logger.error("Falha ao inicializar repositório: #{inspect(reason)}")
            {:error, reason}
        end

      {:error, missing} ->
        DeeperHub.Core.Logger.error("Configurações inválidas: #{inspect(missing)}")
        {:error, {:invalid_config, missing}}
    end
  end

  # Inicializa apenas o repositório para garantir que o banco de dados esteja disponível
  defp init_repository do
    repo_children = [
      # Inicia o supervisor do repositório para gerenciar o pool de conexões do banco de dados
      {DeeperHub.Core.Data.Repo.Supervisor, []}
    ]

    # Configuração do supervisor do repositório
    opts = [strategy: :one_for_one, name: DeeperHub.RepoSupervisor]
    Supervisor.start_link(repo_children, opts)
  end

  # Inicializa o restante dos supervisores após as migrações serem aplicadas com sucesso
  defp init_main_supervisors do
    # Obtém configurações do sistema
    cache_config = Application.get_env(:deeper_hub, :cache, [])
    telemetry_config = Application.get_env(:deeper_hub, :telemetry, [])

    # Define a árvore de supervisão principal da aplicação
    children = [
      # Inicia o supervisor do subsistema de telemetria primeiro
      # para que possa monitorar outros serviços
      {DeeperHub.Core.Telemetry.Supervisor, telemetry_config},

      # Inicia o supervisor do sistema de cache
      {DeeperHub.Core.Cache.Supervisor, cache_config}
    ]

    # Configuração do supervisor principal
    # Obtém configurações de resiliência do ambiente
    supervisor_config = Application.get_env(:deeper_hub, :supervisor, [])

    # Define opções do supervisor com valores padrão caso não estejam configurados
    opts = [
      strategy: Keyword.get(supervisor_config, :strategy, :one_for_one),
      name: DeeperHub.Supervisor,
      max_restarts: Keyword.get(supervisor_config, :max_restarts, 3),
      max_seconds: Keyword.get(supervisor_config, :max_seconds, 5)
    ]

    # Inicia o supervisor principal
    result = Supervisor.start_link(children, opts)

    # Processa o resultado da inicialização do supervisor
    case result do
      {:ok, pid} ->
        DeeperHub.Core.Logger.info("Supervisor principal iniciado com sucesso.")

        # Aguarda um momento para garantir que os supervisors estejam prontos
        Process.sleep(1000)

        # Inicializa integrações entre sistemas
        init_system_integrations()

        DeeperHub.Core.Logger.info("Sistema DeeperHub completamente inicializado.")
        {:ok, pid}

      {:error, reason} ->
        DeeperHub.Core.Logger.error("Falha ao iniciar o sistema DeeperHub: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Inicializa integrações entre sistemas
  defp init_system_integrations do
    DeeperHub.Core.Logger.info("Inicializando integrações entre sistemas...")
    
    # Inicializa sistema de eventos primeiro para permitir comunicação entre componentes
    case initialize_event_manager() do
      :ok ->
        DeeperHub.Core.Logger.info("Sistema de eventos inicializado com sucesso")
        
        # Configura integração Cache-Telemetry
        case DeeperHub.Core.Cache.Integration.setup_telemetry_integration() do
          :ok ->
            DeeperHub.Core.Logger.info("Integração Cache-Telemetry configurada com sucesso")
          {:error, reason} ->
            DeeperHub.Core.Logger.warning("Falha ao configurar integração Cache-Telemetry: #{inspect(reason)}")
        end

        # Configura integração Database-Telemetry
        case setup_database_telemetry_integration() do
          :ok ->
            DeeperHub.Core.Logger.info("Integração Database-Telemetry configurada com sucesso")
          {:error, reason} ->
            DeeperHub.Core.Logger.warning("Falha ao configurar integração Database-Telemetry: #{inspect(reason)}")
        end
        
        DeeperHub.Core.Logger.info("Integrações entre sistemas inicializadas")
        :ok
        
      {:error, reason} ->
        DeeperHub.Core.Logger.error("Falha ao inicializar sistema de eventos: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Configura integração entre Database e Telemetry
  defp setup_database_telemetry_integration do
    try do
      alias DeeperHub.Core.Telemetry.Adapters.DatabaseAdapter
      alias DeeperHub.Core.Telemetry.Configurator.DatabaseConfigurator

      # Inicializa o adaptador de telemetria para o banco de dados
      case DatabaseAdapter.setup([
        pool_name: DeeperHub.DBConnectionPool,
        telemetry_prefix: "deeper_hub.database",
        enable_logging: Application.get_env(:deeper_hub, :telemetry, [])[:enable_logging] || false
      ]) do
        {:ok, _pid} -> 
          # Configura os handlers nomeados para telemetria do banco de dados
          # usando nosso novo configurador específico
          case DatabaseConfigurator.setup([
            pool_name: DeeperHub.DBConnectionPool,
            enable_logging: Application.get_env(:deeper_hub, :telemetry, [])[:enable_logging] || false
          ]) do
            :ok -> :ok
            {:error, reason} -> 
              DeeperHub.Core.Logger.warning("Falha ao configurar handlers de telemetria do banco de dados: #{inspect(reason)}")
              :ok  # Continuamos mesmo com falha nos handlers para não comprometer o sistema
          end
        {:error, reason} -> {:error, reason}
      end
    rescue
      error ->
        DeeperHub.Core.Logger.error("Erro ao configurar integração Database-Telemetry: #{inspect(error)}")
        {:error, error}
    end
  end

  # Inicializa o sistema de gerenciamento de eventos
  defp initialize_event_manager do
    try do
      # Importa os módulos necessários
      alias DeeperHub.Core.EventManager
      alias DeeperHub.Core.Cache.Subscribers.CacheEventsSubscriber
      alias DeeperHub.Core.Logger.Subscribers.LogEventsSubscriber

      # Inicializa o sistema de eventos
      :ok = EventManager.initialize()

      # Inicia os subscribers
      DeeperHub.Core.Logger.info("Iniciando subscribers de eventos...")

      # Inicia o subscriber de eventos do cache
      CacheEventsSubscriber.start()
      DeeperHub.Core.Logger.info("Subscriber de eventos do cache iniciado")

      # Inicia o subscriber de eventos de log
      LogEventsSubscriber.start()
      DeeperHub.Core.Logger.info("Subscriber de eventos de log iniciado")

      # Publica evento de início do sistema
      EventManager.publish(
        :system_started,
        %{timestamp: :os.system_time(:second)},
        "application"
      )

      :ok
    rescue
      error ->
        DeeperHub.Core.Logger.error("Erro ao inicializar sistema de eventos: #{inspect(error)}")
        {:error, error}
    end
  end
end
