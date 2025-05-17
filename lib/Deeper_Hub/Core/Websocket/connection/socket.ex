defmodule Deeper_Hub.Core.Websocket.Socket do
  @moduledoc """
  Socket WebSocket para o Deeper_Hub.

  Este socket:
  - Define os canais disponíveis
  - Gerencia autenticação
  - Configura o estado inicial da conexão
  """

  use Phoenix.Socket

  ## Channels
  channel "websocket", Deeper_Hub.Core.Websocket.Channel

  @impl true
  def connect(_params, socket, _connect_info) do
    # Sem autenticação temporariamente para testes
    user_id = "user_#{:rand.uniform(1000)}"
    socket = assign(socket, :user_id, user_id)
    {:ok, socket}
  end

  @impl true
  def id(socket), do: "socket:#{socket.assigns.user_id}"
  
  @doc """
  Verifica se um socket é válido e ativo.
  
  ## Parâmetros
  
  - `socket`: Socket Phoenix a ser verificado
  
  ## Retorno
  
  - `true`: Socket válido e ativo
  - `false`: Socket inválido ou inativo
  """
  def valid?(socket) do
    is_struct(socket, Phoenix.Socket) && 
    Map.has_key?(socket.assigns, :user_id) && 
    socket.assigns.user_id != nil
  end
end
