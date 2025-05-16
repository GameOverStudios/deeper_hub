defmodule Deeper_Hub.Application do
  @moduledoc """
  Módulo de aplicação principal para o Deeper_Hub.
  Responsável por gerenciar a inicialização e supervisão dos processos da aplicação.
  """
  use Application

  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Data.DatabaseConfig
  alias Deeper_Hub.Core.Data.Migrations
  alias Deeper_Hub.Core.Data.Repo
  alias Deeper_Hub.Core.Telemetry.TelemetryEvents
  alias Deeper_Hub.Core.Telemetry.TelemetryHandlers
  alias Deeper_Hub.Core.EventBus.EventDefinitions
  alias Deeper_Hub.Core.EventBus.EventSubscribers
  alias Deeper_Hub.Core.Cache.CacheManager

  @impl true
  def start(_type, _args) do
    # Inicializa o banco de dados
    Logger.info("Inicializando aplicação Deeper_Hub", %{module: __MODULE__})

    # Configuração do sistema de telemetria
    configure_telemetry()

    # Configuração do sistema de eventos
    configure_event_bus()

    # Configura o banco de dados e verifica se ele existe
    case DatabaseConfig.configure() do
      :ok ->
        # Banco de dados configurado com sucesso, verificamos se existe
        config = DatabaseConfig.get_config()
        db_exists = DatabaseConfig.database_exists?(config)

        if db_exists do
          # Banco de dados já existe, verificamos se há migrações pendentes
          Logger.info("Banco de dados existente, verificando migrações pendentes", %{module: __MODULE__})
        else
          # Banco de dados acabou de ser criado, executamos as migrações iniciais
          Logger.info("Banco de dados criado, executando migrações iniciais", %{module: __MODULE__})
        end

        # Em ambos os casos, executamos as migrações para garantir que o banco está atualizado
        case Migrations.run_migrations() do
          :ok -> Logger.info("Migrações executadas com sucesso", %{module: __MODULE__})
          {:error, reason} -> Logger.error("Falha ao executar migrações", %{module: __MODULE__, error: reason})
        end

      {:error, reason} ->
        # Erro ao configurar o banco de dados
        Logger.error("Falha ao configurar o banco de dados", %{module: __MODULE__, error: reason})
    end

    children = [
      # Adiciona o repositório Ecto à árvore de supervisão
      Repo,

      # Adiciona o Cachex à árvore de supervisão com TTL e limpeza automática
      {Cachex, [
        name: :repository_cache,
        ttl: true,
        ttl_interval: 60_000
      ]},

      # Adiciona o gerenciador de cache
      {CacheManager, []},

      # Adiciona o servidor PubSub para WebSocket
      {Phoenix.PubSub, name: Deeper_Hub.PubSub},

      # Adiciona o supervisor do WebSocket
      Deeper_Hub.Core.Websocket.Supervisor,

      # Adiciona o Telemetry Poller para coletar métricas periodicamente
      {:telemetry_poller,
       measurements: [
         # Métricas de processo para o Repo
         {:process_info, name: Repo, event: [:deeper_hub, :repo], keys: [:memory, :message_queue_len]},
         # Métricas de processo para o Cache
         {:process_info, name: :repository_cache, event: [:deeper_hub, :cache], keys: [:memory, :message_queue_len]}
       ],
       period: :timer.seconds(10)}
    ]

    opts = [strategy: :one_for_one, name: Deeper_Hub.Supervisor]

    # Inicia a árvore de supervisão
    Supervisor.start_link(children, opts)
  end

  # Configura os handlers de telemetria
  defp configure_telemetry do
    Logger.info("Configurando telemetria", %{module: __MODULE__})

    # Registra handler para eventos de banco de dados
    :ok = :telemetry.attach(
      "deeper-hub-db-query-handler",
      TelemetryEvents.db_query(),
      &TelemetryHandlers.handle_db_query_event/4,
      nil
    )

    # Registra handler para eventos de transação
    :ok = :telemetry.attach(
      "deeper-hub-db-transaction-handler",
      TelemetryEvents.db_transaction(),
      &TelemetryHandlers.handle_db_transaction_event/4,
      nil
    )

    # Registra handler para eventos de cache
    :ok = :telemetry.attach(
      "deeper-hub-cache-hit-handler",
      TelemetryEvents.cache_hit(),
      &TelemetryHandlers.handle_cache_hit_event/4,
      nil
    )

    :ok = :telemetry.attach(
      "deeper-hub-cache-miss-handler",
      TelemetryEvents.cache_miss(),
      &TelemetryHandlers.handle_cache_miss_event/4,
      nil
    )
  end

  # Os handlers de telemetria foram movidos para o módulo TelemetryHandlers

  # Configura o EventBus
  defp configure_event_bus do
    Logger.info("Configurando EventBus", %{module: __MODULE__})

    # Registra todos os tópicos de eventos
    Enum.each(EventDefinitions.all_topics(), fn topic ->
      EventBus.register_topic(topic)
    end)

    # Registra todos os subscribers
    EventSubscribers.register_subscribers()

    :ok
  end
end
