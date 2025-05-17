defmodule Deeper_Hub.Core.WebSockets.WebSocketRouter do
  @moduledoc """
  Router para mensagens WebSocket.

  Este módulo direciona mensagens para os handlers apropriados com base no tipo.
  """

  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.WebSockets.Handlers.EchoHandler
  alias Deeper_Hub.Core.WebSockets.Handlers.UserHandler
  alias Deeper_Hub.Core.WebSockets.Handlers.ChannelHandler
  alias Deeper_Hub.Core.WebSockets.Handlers.MessageHandler

  @doc """
  Roteia uma mensagem para o handler apropriado com base no tipo.

  ## Parâmetros

    - `type`: O tipo da mensagem
    - `payload`: O payload da mensagem

  ## Retorno

    - `{:ok, response}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def route(type, payload) do
    Logger.debug("Roteando mensagem", %{
      module: __MODULE__,
      type: type,
      payload: payload
    })

    # Publica evento de mensagem recebida
    try do
      if Code.ensure_loaded?(Deeper_Hub.Core.EventBus) do
        Deeper_Hub.Core.EventBus.publish(:websocket_message_received, %{
          type: type,
          timestamp: :os.system_time(:millisecond)
        })
      end
    rescue
      _ -> :ok
    end

    # Roteia a mensagem para o handler apropriado
    result = do_route(type, payload)

    # Publica evento de mensagem processada
    try do
      if Code.ensure_loaded?(Deeper_Hub.Core.EventBus) do
        case result do
          {:ok, _} ->
            Deeper_Hub.Core.EventBus.publish(:websocket_message_processed, %{
              type: type,
              success: true,
              timestamp: :os.system_time(:millisecond)
            })

          {:error, reason} ->
            Deeper_Hub.Core.EventBus.publish(:websocket_message_processed, %{
              type: type,
              success: false,
              error: reason,
              timestamp: :os.system_time(:millisecond)
            })
        end
      end
    rescue
      _ -> :ok
    end

    result
  end

  # Implementação do roteamento
  defp do_route("echo", payload) do
    EchoHandler.handle(payload)
  end

  defp do_route("user.get", payload) do
    UserHandler.get(payload)
  end

  defp do_route("user.create", payload) do
    UserHandler.create(payload)
  end

  defp do_route("user.update", payload) do
    UserHandler.update(payload)
  end

  defp do_route("user.delete", payload) do
    UserHandler.delete(payload)
  end

  # Rotas para mensagens de canais
  defp do_route("channel." <> action, payload) do
    ChannelHandler.handle_message(action, payload, Process.get(:websocket_state, %{}))
  end
  
  # Rotas para mensagens diretas
  defp do_route("message." <> action, payload) do
    MessageHandler.handle_message(action, payload, Process.get(:websocket_state, %{}))
  end

  # Rota padrão para tipos desconhecidos
  defp do_route(type, _payload) do
    Logger.warning("Tipo de mensagem desconhecido", %{
      module: __MODULE__,
      type: type
    })

    {:error, :unknown_message_type}
  end
end
