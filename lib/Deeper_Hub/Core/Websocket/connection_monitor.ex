defmodule DeeperHub.Core.Websocket.ConnectionMonitor do
  @moduledoc """
  Monitor de conexões WebSocket.
  
  Este módulo:
  - Monitora conexões ativas
  - Detecta conexões zumbis
  - Emite métricas de conexão
  - Implementa health checks
  """

  use GenServer
  require Logger
  alias Deeper_Hub.Core.Telemetry.TelemetryEvents
  alias Deeper_Hub.Core.EventBus.EventDefinitions
  alias Deeper_Hub.Core.Cache.CacheManager

  @check_interval 60_000 # 1 minuto
  @zombie_timeout 300_000 # 5 minutos
  @cache_ttl 3600 # 1 hora

  # API Pública

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def register_connection(socket_id, metadata) do
    GenServer.cast(__MODULE__, {:register, socket_id, metadata})
  end

  def unregister_connection(socket_id) do
    GenServer.cast(__MODULE__, {:unregister, socket_id})
  end

  def get_connection_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  def get_active_connections do
    GenServer.call(__MODULE__, :get_active)
  end

  # Callbacks do GenServer

  @impl true
  def init(_opts) do
    # Inicializa o estado
    state = %{
      connections: %{},
      stats: %{
        total: 0,
        active: 0,
        zombie: 0
      },
      last_check: DateTime.utc_now()
    }

    # Agenda verificação periódica
    schedule_check()

    # Recupera estatísticas do cache, se disponíveis
    state = case CacheManager.get(:default_cache, "websocket:stats") do
      {:ok, cached_stats} when not is_nil(cached_stats) ->
        %{state | stats: cached_stats}
      _ ->
        state
    end

    # Emite evento de inicialização
    EventDefinitions.emit(
      EventDefinitions.websocket_monitor_started(),
      %{},
      source: "#{__MODULE__}"
    )

    # Emite métrica de inicialização
    TelemetryEvents.execute_websocket_monitor(
      %{count: 1},
      %{event: :start, module: __MODULE__}
    )

    {:ok, state}
  end

  @impl true
  def handle_cast({:register, socket_id, metadata}, state) do
    # Registra nova conexão
    connections = Map.put(state.connections, socket_id, %{
      connected_at: DateTime.utc_now(),
      last_activity: DateTime.utc_now(),
      metadata: metadata
    })

    # Atualiza estatísticas
    stats = %{
      state.stats |
      total: state.stats.total + 1,
      active: state.stats.active + 1
    }

    # Emite evento de conexão
    EventDefinitions.emit(
      EventDefinitions.websocket_connection(),
      %{socket_id: socket_id, metadata: metadata},
      source: "#{__MODULE__}"
    )

    # Emite métrica de conexão
    TelemetryEvents.execute_websocket_connection(
      %{count: 1},
      %{socket_id: socket_id, module: __MODULE__}
    )

    # Atualiza o cache
    CacheManager.put(:default_cache, "websocket:stats", stats, ttl: @cache_ttl)

    {:noreply, %{state | connections: connections, stats: stats}}
  end

  @impl true
  def handle_cast({:unregister, socket_id}, state) do
    # Verifica se a conexão existe
    case Map.get(state.connections, socket_id) do
      nil ->
        # Conexão não encontrada
        {:noreply, state}

      _connection ->
        # Remove a conexão
        connections = Map.delete(state.connections, socket_id)

        # Atualiza estatísticas
        stats = %{
          state.stats |
          active: state.stats.active - 1
        }

        # Emite evento de desconexão
        EventDefinitions.emit(
          EventDefinitions.websocket_disconnection(),
          %{socket_id: socket_id},
          source: "#{__MODULE__}"
        )

        # Emite métrica de desconexão
        TelemetryEvents.execute_websocket_disconnection(
          %{count: 1},
          %{socket_id: socket_id, module: __MODULE__}
        )

        # Atualiza o cache
        CacheManager.put(:default_cache, "websocket:stats", stats, ttl: @cache_ttl)

        {:noreply, %{state | connections: connections, stats: stats}}
    end
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    {:reply, state.stats, state}
  end

  @impl true
  def handle_call(:get_active, _from, state) do
    active = state.connections
    |> Enum.filter(fn {_id, conn} ->
      DateTime.diff(DateTime.utc_now(), conn.last_activity, :millisecond) < @zombie_timeout
    end)
    |> Enum.map(fn {id, _conn} -> id end)

    {:reply, active, state}
  end

  @impl true
  def handle_info(:check_connections, state) do
    now = DateTime.utc_now()
    
    # Identifica conexões zumbis
    {active_connections, zombie_connections} = 
      Enum.split_with(state.connections, fn {_id, conn} ->
        DateTime.diff(now, conn.last_activity, :millisecond) < @zombie_timeout
      end)

    # Fecha conexões zumbis
    for {socket_id, _conn} <- zombie_connections do
      # Emite evento de conexão zumbi
      EventDefinitions.emit(
        EventDefinitions.websocket_zombie_connection(),
        %{socket_id: socket_id},
        source: "#{__MODULE__}"
      )

      # Emite métrica de conexão zumbi
      TelemetryEvents.execute_websocket_zombie(
        %{count: 1},
        %{socket_id: socket_id, module: __MODULE__}
      )

      # Tenta fechar a conexão
      try do
        DeeperHub.Core.Websocket.Channel.terminate_by_id(socket_id, :zombie)
      rescue
        _ -> :ok
      end
    end

    # Atualiza estatísticas
    stats = %{
      state.stats |
      active: length(active_connections),
      zombie: length(zombie_connections)
    }

    # Emite métrica de verificação
    TelemetryEvents.execute_websocket_monitor(
      %{
        active: length(active_connections),
        zombie: length(zombie_connections),
        total: state.stats.total
      },
      %{event: :check, module: __MODULE__}
    )

    # Atualiza o cache
    CacheManager.put(:default_cache, "websocket:stats", stats, ttl: @cache_ttl)

    # Agenda próxima verificação
    schedule_check()

    # Atualiza o estado
    {:noreply, %{
      state |
      connections: Map.new(active_connections),
      stats: stats,
      last_check: now
    }}
  end

  defp schedule_check do
    Process.send_after(self(), :check_connections, @check_interval)
  end
end
