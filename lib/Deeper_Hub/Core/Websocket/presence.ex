defmodule DeeperHub.Core.Websocket.Presence do
  @moduledoc """
  Gerenciador de presence para o WebSocket.

  Este módulo:
  - Rastreia usuários conectados
  - Gerencia estados de conexão
  - Implementa broadcast de presence
  """

  use Phoenix.Presence, otp_app: :deeper_hub, pubsub_server: DeeperHub.PubSub
  import Phoenix.Channel

  def init(_opts) do
    {:ok, %{}}
  end

  def on_mount(:default, _params, socket, _connect_info) do
    # Rastreia a conexão
    {:ok, socket}
  end

  def handle_in("presence", %{event: "track"}, socket) do
    # Rastreia o usuário
    {:ok, socket}
  end

  def handle_in("presence", %{event: "untrack"}, socket) do
    # Para de rastrear o usuário
    {:ok, socket}
  end

  def handle_out("presence", %{event: "track"}, socket) do
    # Broadcast de presence
    {:noreply, socket}
  end

  def handle_out("presence", %{event: "untrack"}, socket) do
    # Broadcast de presence
    {:noreply, socket}
  end

  def broadcast_presence(socket, event, data) do
    broadcast!(socket, "presence", %{event: event, data: data})
  end
end
