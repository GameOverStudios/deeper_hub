defmodule DeeperHub.Application do
  @moduledoc """
  Módulo de aplicação principal para o DeeperHub.
  Responsável por gerenciar a inicialização e supervisão dos processos da aplicação.
  """
  use Application

  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Data.DBConnection.Config
  alias Deeper_Hub.Core.Data.DBConnection.Migrations
  alias Deeper_Hub.Core.Data.DBConnection.Telemetry
  alias Deeper_Hub.Core.Data.DBConnection.Facade, as: DB
  alias Deeper_Hub.Core.Supervisor, as: CoreSupervisor
  alias Deeper_Hub.Core.Metrics

  @impl true
  def start(_type, _args) do
    # Inicializa o banco de dados
    Logger.info("Inicializando aplicação DeeperHub", %{module: __MODULE__})

    # Inicializa a telemetria para o DBConnection
    Telemetry.initialize()

    # Inicializa o sistema de métricas
    Metrics.Reporter.setup()

    # Configura o banco de dados e verifica se ele existe
    case Config.configure() do
      :ok ->
        # Banco de dados configurado com sucesso, verificamos se existe
        conn_config = Config.get_connection_config()
        pool_config = Config.get_pool_config()
        db_exists = Config.database_exists?(conn_config)

        if db_exists do
          # Banco de dados já existe, verificamos se há migrações pendentes
          Logger.info("Banco de dados existente, verificando migrações pendentes", %{module: __MODULE__})
        else
          # Banco de dados acabou de ser criado, executamos as migrações iniciais
          Logger.info("Banco de dados criado, executando migrações iniciais", %{module: __MODULE__})
        end

        children = [
          # Adiciona o supervisor do Core que gerencia cache e métricas
          CoreSupervisor,

          # Adiciona o pool de conexões DBConnection à árvore de supervisão
          {DB, [
            pool_size: pool_config.pool_size,
            max_overflow: pool_config.max_overflow,
            idle_interval: pool_config.idle_interval,
            queue_target: pool_config.queue_target,
            queue_interval: pool_config.queue_interval
          ]}
        ]

        opts = [strategy: :one_for_one, name: DeeperHub.Supervisor]

        # Inicia a árvore de supervisão
        {:ok, pid} = Supervisor.start_link(children, opts)

        # Iniciamos o pool de conexões manualmente após a inicialização do supervisor
        # Removemos a mensagem de log duplicada, pois o módulo DB já registra o início do pool
        case DB.start_pool([
          pool_size: pool_config.pool_size,
          max_overflow: pool_config.max_overflow,
          idle_interval: pool_config.idle_interval,
          queue_target: pool_config.queue_target,
          queue_interval: pool_config.queue_interval
        ]) do
          {:ok, _} ->

            # Em ambos os casos, executamos as migrações para garantir que o banco está atualizado
            case Migrations.run_migrations() do
              :ok -> Logger.info("Migrações executadas com sucesso", %{module: __MODULE__})
              {:error, reason} -> Logger.error("Falha ao executar migrações", %{module: __MODULE__, error: reason})
            end

          {:error, reason} ->
            Logger.error("Falha ao iniciar pool de conexões", %{module: __MODULE__, error: reason})
        end

        {:ok, pid}

      {:error, reason} ->
        # Erro ao configurar o banco de dados
        Logger.error("Falha ao configurar o banco de dados", %{module: __MODULE__, error: reason})
        {:error, reason}
    end
  end
end
