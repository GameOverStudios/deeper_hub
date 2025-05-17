defmodule Deeper_Hub.Core.WebSockets.Handlers.ChannelHandler do
  @moduledoc """
  Handler para mensagens relacionadas a canais no WebSocket.
  
  Este módulo processa mensagens WebSocket relacionadas a canais,
  como criação de canais, inscrição em canais e envio de mensagens.
  """
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Communications.Channels.ChannelManager
  
  @doc """
  Processa uma mensagem WebSocket relacionada a canais.
  
  ## Parâmetros
  
    - `action`: Ação a ser executada
    - `payload`: Dados da mensagem
    - `state`: Estado da conexão WebSocket
  
  ## Retorno
  
    - `{:ok, response}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def handle_message(action, payload, state) do
    Logger.debug("Processando mensagem de canal", %{
      module: __MODULE__,
      action: action,
      user_id: state[:user_id]
    })
    
    case do_handle_message(action, payload, state) do
      {:ok, response} ->
        {:ok, response}
      {:error, reason} ->
        Logger.error("Erro ao processar mensagem de canal", %{
          module: __MODULE__,
          action: action,
          user_id: state[:user_id],
          error: reason
        })
        
        {:error, %{message: "Erro ao processar mensagem de canal: #{reason}"}}
    end
  end
  
  # Handlers específicos para cada tipo de ação
  
  # Cria um novo canal
  defp do_handle_message("create", payload, state) do
    user_id = state[:user_id]
    
    with {:ok, channel_name} <- validate_required(payload, "name"),
         {:ok, metadata} <- validate_optional(payload, "metadata", %{}),
         {:ok, channel_id} <- ChannelManager.create_channel(channel_name, user_id, metadata) do
      
      {:ok, %{
        channel_id: channel_id,
        channel_name: channel_name,
        message: "Canal criado com sucesso"
      }}
    else
      {:error, :channel_exists} ->
        {:error, "Canal já existe"}
      {:error, :missing_field, field} ->
        {:error, "Campo obrigatório ausente: #{field}"}
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # Inscreve o usuário em um canal
  defp do_handle_message("subscribe", payload, state) do
    user_id = state[:user_id]
    
    with {:ok, channel_name} <- validate_required(payload, "name"),
         :ok <- ChannelManager.subscribe(channel_name, user_id) do
      
      {:ok, %{
        channel_name: channel_name,
        message: "Inscrito no canal com sucesso"
      }}
    else
      {:error, :channel_not_found} ->
        {:error, "Canal não encontrado"}
      {:error, :missing_field, field} ->
        {:error, "Campo obrigatório ausente: #{field}"}
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # Cancela a inscrição do usuário em um canal
  defp do_handle_message("unsubscribe", payload, state) do
    user_id = state[:user_id]
    
    with {:ok, channel_name} <- validate_required(payload, "name"),
         :ok <- ChannelManager.unsubscribe(channel_name, user_id) do
      
      {:ok, %{
        channel_name: channel_name,
        message: "Inscrição cancelada com sucesso"
      }}
    else
      {:error, :channel_not_found} ->
        {:error, "Canal não encontrado"}
      {:error, :not_subscribed} ->
        {:error, "Usuário não está inscrito neste canal"}
      {:error, :missing_field, field} ->
        {:error, "Campo obrigatório ausente: #{field}"}
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # Publica uma mensagem em um canal
  defp do_handle_message("publish", payload, state) do
    user_id = state[:user_id]
    
    with {:ok, channel_name} <- validate_required(payload, "channel_name"),
         {:ok, content} <- validate_required(payload, "content"),
         {:ok, metadata} <- validate_optional(payload, "metadata", %{}),
         {:ok, message_id, recipient_count} <- ChannelManager.publish(channel_name, user_id, content, metadata) do
      
      {:ok, %{
        message_id: message_id,
        channel_name: channel_name,
        recipient_count: recipient_count,
        message: "Mensagem publicada com sucesso"
      }}
    else
      {:error, :channel_not_found} ->
        {:error, "Canal não encontrado"}
      {:error, :missing_field, field} ->
        {:error, "Campo obrigatório ausente: #{field}"}
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # Lista canais disponíveis
  defp do_handle_message("list", payload, state) do
    filter = Map.get(payload, "filter")
    
    case ChannelManager.list_channels(filter) do
      {:ok, channels} ->
        {:ok, %{
          channels: channels,
          count: length(channels)
        }}
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # Obtém informações sobre um canal
  defp do_handle_message("info", payload, _state) do
    with {:ok, channel_name} <- validate_required(payload, "name"),
         {:ok, channel} <- ChannelManager.get_channel_info(channel_name) do
      
      {:ok, %{
        channel: channel
      }}
    else
      {:error, :channel_not_found} ->
        {:error, "Canal não encontrado"}
      {:error, :missing_field, field} ->
        {:error, "Campo obrigatório ausente: #{field}"}
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # Lista inscritos em um canal
  defp do_handle_message("subscribers", payload, _state) do
    with {:ok, channel_name} <- validate_required(payload, "name"),
         {:ok, subscribers} <- ChannelManager.list_subscribers(channel_name) do
      
      {:ok, %{
        channel_name: channel_name,
        subscribers: subscribers,
        count: length(subscribers)
      }}
    else
      {:error, :channel_not_found} ->
        {:error, "Canal não encontrado"}
      {:error, :missing_field, field} ->
        {:error, "Campo obrigatório ausente: #{field}"}
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
