defmodule Deeper_Hub.Core.WebSockets.Handlers.MessageHandler do
  @moduledoc """
  Handler para mensagens diretas no WebSocket.
  
  Este módulo processa mensagens WebSocket relacionadas a mensagens diretas
  entre usuários, como envio, leitura e recuperação de histórico.
  """
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Communications.Messages.MessageManager
  
  @doc """
  Processa uma mensagem WebSocket relacionada a mensagens diretas.
  
  ## Parâmetros
  
    - `action`: Ação a ser executada
    - `payload`: Dados da mensagem
    - `state`: Estado da conexão WebSocket
  
  ## Retorno
  
    - `{:ok, response}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def handle_message(action, payload, state) do
    Logger.debug("Processando mensagem direta", %{
      module: __MODULE__,
      action: action,
      user_id: state[:user_id]
    })
    
    case do_handle_message(action, payload, state) do
      {:ok, response} ->
        {:ok, response}
      {:error, reason} ->
        Logger.error("Erro ao processar mensagem direta", %{
          module: __MODULE__,
          action: action,
          user_id: state[:user_id],
          error: reason
        })
        
        {:error, %{message: "Erro ao processar mensagem direta: #{reason}"}}
    end
  end
  
  # Handlers específicos para cada tipo de ação
  
  # Envia uma mensagem direta para outro usuário
  defp do_handle_message("send", payload, state) do
    sender_id = state[:user_id]
    
    with {:ok, recipient_id} <- validate_required(payload, "recipient_id"),
         {:ok, content} <- validate_required(payload, "content"),
         {:ok, metadata} <- validate_optional(payload, "metadata", %{}),
         {:ok, message_id} <- MessageManager.send_message(sender_id, recipient_id, content, metadata) do
      
      {:ok, %{
        message_id: message_id,
        recipient_id: recipient_id,
        message: "Mensagem enviada com sucesso"
      }}
    else
      {:error, :user_not_found} ->
        {:error, "Destinatário não encontrado"}
      {:error, :missing_field, field} ->
        {:error, "Campo obrigatório ausente: #{field}"}
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # Marca uma mensagem como lida
  defp do_handle_message("mark_read", payload, state) do
    user_id = state[:user_id]
    
    with {:ok, message_id} <- validate_required(payload, "message_id"),
         :ok <- MessageManager.mark_as_read(message_id, user_id) do
      
      {:ok, %{
        message_id: message_id,
        message: "Mensagem marcada como lida"
      }}
    else
      {:error, :message_not_found} ->
        {:error, "Mensagem não encontrada"}
      {:error, :not_recipient} ->
        {:error, "Você não é o destinatário desta mensagem"}
      {:error, :missing_field, field} ->
        {:error, "Campo obrigatório ausente: #{field}"}
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # Obtém o histórico de mensagens com outro usuário
  defp do_handle_message("history", payload, state) do
    user_id = state[:user_id]
    
    with {:ok, other_user_id} <- validate_required(payload, "user_id"),
         {:ok, limit} <- validate_optional(payload, "limit", 50),
         {:ok, offset} <- validate_optional(payload, "offset", 0),
         {:ok, messages} <- MessageManager.get_conversation(user_id, other_user_id, limit, offset) do
      
      {:ok, %{
        user_id: other_user_id,
        messages: messages,
        count: length(messages)
      }}
    else
      {:error, :missing_field, field} ->
        {:error, "Campo obrigatório ausente: #{field}"}
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # Obtém as conversas recentes do usuário
  defp do_handle_message("recent", payload, state) do
    user_id = state[:user_id]
    
    with {:ok, limit} <- validate_optional(payload, "limit", 20),
         {:ok, conversations} <- MessageManager.get_recent_conversations(user_id, limit) do
      
      {:ok, %{
        conversations: conversations,
        count: length(conversations)
      }}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # Obtém o número de mensagens não lidas
  defp do_handle_message("unread_count", _payload, state) do
    user_id = state[:user_id]
    
    case MessageManager.get_unread_count(user_id) do
      {:ok, count} ->
        {:ok, %{
          unread_count: count
        }}
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # Ação desconhecida
  defp do_handle_message(action, _payload, _state) do
    {:error, "Ação desconhecida: #{action}"}
  end
  
  # Funções auxiliares
  
  # Valida um campo obrigatório
  defp validate_required(payload, field) do
    case Map.get(payload, field) do
      nil -> {:error, :missing_field, field}
      value -> {:ok, value}
    end
  end
  
  # Valida um campo opcional
  defp validate_optional(payload, field, default) do
    {:ok, Map.get(payload, field, default)}
  end
end
