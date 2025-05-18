defmodule Deeper_Hub.Core.WebSockets.Handlers.WebSocketHandler do
  @moduledoc """
  Handler principal para mensagens WebSocket.
  
  Este módulo é responsável por rotear mensagens para os handlers específicos
  com base no tipo de mensagem recebida.
  """
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.WebSockets.Handlers.{
    EchoHandler,
    UserHandler,
    ChannelHandler,
    MessageHandler
  }
  
  @doc """
  Processa uma mensagem WebSocket e a encaminha para o handler apropriado.
  
  ## Parâmetros
  
    - `type`: Tipo da mensagem
    - `payload`: Conteúdo da mensagem
    - `state`: Estado da conexão WebSocket
  
  ## Retorno
  
    - `{:ok, response}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def handle_message(type, payload, state) do
    Logger.debug("Processando mensagem WebSocket", %{
      module: __MODULE__,
      type: type,
      user_id: state[:user_id]
    })
    
    case do_handle_message(type, payload, state) do
      {:ok, response} ->
        {:ok, response}
      {:error, reason} ->
        Logger.error("Erro ao processar mensagem WebSocket", %{
          module: __MODULE__,
          type: type,
          user_id: state[:user_id],
          error: reason
        })
        
        {:error, %{message: "Erro ao processar mensagem: #{reason}"}}
    end
  end
  
  # Encaminha a mensagem para o handler apropriado com base no tipo
  defp do_handle_message("echo", payload, _state) do
    EchoHandler.handle(payload)
  end
  
  defp do_handle_message("user", payload, state) do
    case Map.get(payload, "action") do
      action when is_binary(action) ->
        UserHandler.handle_message(action, payload, state)
      _ ->
        {:error, "Ação de usuário não especificada"}
    end
  end
  
  defp do_handle_message("channel", payload, state) do
    case Map.get(payload, "action") do
      action when is_binary(action) ->
        ChannelHandler.handle_message(action, payload, state)
      _ ->
        {:error, "Ação de canal não especificada"}
    end
  end
  
  defp do_handle_message("message", payload, state) do
    case Map.get(payload, "action") do
      action when is_binary(action) ->
        MessageHandler.handle_message(action, payload, state)
      _ ->
        {:error, "Ação de mensagem não especificada"}
    end
  end
  
  defp do_handle_message(type, _payload, _state) do
    {:error, "Tipo de mensagem desconhecido: #{type}"}
  end
end
