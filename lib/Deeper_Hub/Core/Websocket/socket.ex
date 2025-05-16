defmodule DeeperHub.Core.Websocket.Socket do
  @moduledoc """
  Socket WebSocket para o Deeper_Hub.
  
  Este socket:
  - Define os canais disponíveis
  - Gerencia autenticação
  - Configura o estado inicial da conexão
  """
  
  use Phoenix.Socket
  
  ## Channels
  channel "websocket", DeeperHub.Core.Websocket.Channel
  
  @impl true
  def connect(_params, socket, _connect_info) do
    # Sem autenticação temporariamente para testes
    user_id = "user_#{:rand.uniform(1000)}"
    socket = assign(socket, :user_id, user_id)
    {:ok, socket}
  end
  
  @impl true
  def id(socket), do: "socket:#{socket.assigns.user_id}"
end
