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

  # Rotas para mensagens de usuários (formato prefixado)
  defp do_route("user." <> action, payload) do
    UserHandler.handle_message(action, payload, Process.get(:websocket_state, %{}))
  end

  # Rotas para mensagens de canais (formato prefixado)
  defp do_route("channel." <> action, payload) do
    ChannelHandler.handle_message(action, payload, Process.get(:websocket_state, %{}))
  end

  # Rotas para mensagens diretas (formato prefixado)
  defp do_route("message." <> action, payload) do
    # Garante que o estado seja sempre um mapa válido
    state = case Process.get(:websocket_state) do
      nil -> %{}
      state when is_map(state) -> state
      _ -> %{}
    end
    
    MessageHandler.handle_message(action, payload, state)
  end
  
  # Suporte para formato simples usado pelo cliente C++
  defp do_route("user", %{"action" => action} = payload) when is_binary(action) do
    # Garante que o estado seja sempre um mapa válido
    state = case Process.get(:websocket_state) do
      nil -> %{}
      state when is_map(state) -> state
      _ -> %{}
    end
    
    UserHandler.handle_message(action, payload, state)
  end
  
  defp do_route("channel", %{"action" => action} = payload) when is_binary(action) do
    # Garante que o estado seja sempre um mapa válido
    state = case Process.get(:websocket_state) do
      nil -> %{}
      state when is_map(state) -> state
      _ -> %{}
    end
    
    ChannelHandler.handle_message(action, payload, state)
  end
  
  # Handler para mensagens de autenticação
  defp do_route("auth", %{"user_id" => user_id} = _payload) when is_binary(user_id) do
    Logger.info("Autenticação de usuário", %{user_id: user_id})
    
    # Armazena o ID do usuário no estado da conexão
    # Garante que o estado seja sempre um mapa válido
    state = case Process.get(:websocket_state) do
      nil -> %{}
      state when is_map(state) -> state
      _ -> %{}
    end
    
    # Atualiza o estado com o ID do usuário
    state = Map.put(state, :user_id, user_id)
    Process.put(:websocket_state, state)
    
    # Retorna uma resposta de sucesso
    {:ok, %{type: "auth_success", payload: %{user_id: user_id}}}
  end
  
  defp do_route("message", %{"action" => action} = payload) when is_binary(action) do
    # Garante que o estado seja sempre um mapa válido
    state = case Process.get(:websocket_state) do
      nil -> %{}
      state when is_map(state) -> state
      _ -> %{}
    end
    
    MessageHandler.handle_message(action, payload, state)
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
