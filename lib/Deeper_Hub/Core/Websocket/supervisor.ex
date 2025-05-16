defmodule DeeperHub.Core.Websocket.Supervisor do
  @moduledoc """
  Supervisor para o sistema WebSocket do DeeperHub.

  Este supervisor:
  - Gerencia o endpoint WebSocket
  - Gerencia o presence
  - Gerencia pools de conexões
  """

  use Supervisor
  alias DeeperHub.Core.Websocket.Presence

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Endpoint WebSocket
      {DeeperHub.Core.Websocket.Endpoint, [
        http: [port: 4000],
        url: [host: "localhost"],
        websocket: [timeout: 45_000, compress: true],
        pubsub_server: DeeperHub.PubSub
      ]},

      # Presence
      {Presence, []},

      # Worker para monitoramento de conexões
      {DeeperHub.Core.Websocket.ConnectionMonitor, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
