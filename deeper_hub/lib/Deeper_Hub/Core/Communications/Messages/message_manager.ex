defmodule Deeper_Hub.Core.Communications.Messages.MessageManager do
  @moduledoc """
  Gerenciador de mensagens diretas entre usuários.
  
  Este módulo gerencia o envio, recebimento e armazenamento de mensagens
  diretas entre usuários.
  """
  
  use GenServer
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Communications.ConnectionManager
  
  @doc """
  Inicia o gerenciador de mensagens.
  
  ## Retorno
  
    - `{:ok, pid}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def start_link(opts \\ []) do
    Logger.info("Iniciando gerenciador de mensagens", %{module: __MODULE__})
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Envia uma mensagem direta para um usuário.
  
  ## Parâmetros
  
    - `sender_id`: ID do remetente
    - `recipient_id`: ID do destinatário
    - `content`: Conteúdo da mensagem
    - `metadata`: Metadados adicionais (opcional)
  
  ## Retorno
  
    - `{:ok, message_id}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def send_message(sender_id, recipient_id, content, metadata \\ %{}) do
    GenServer.call(__MODULE__, {:send_message, sender_id, recipient_id, content, metadata})
  end
  
  @doc """
  Marca uma mensagem como lida.
  
  ## Parâmetros
  
    - `message_id`: ID da mensagem
    - `user_id`: ID do usuário que leu a mensagem
  
  ## Retorno
  
    - `:ok` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def mark_as_read(message_id, user_id) do
    GenServer.call(__MODULE__, {:mark_as_read, message_id, user_id})
  end
  
  @doc """
  Obtém o histórico de mensagens entre dois usuários.
  
  ## Parâmetros
  
    - `user1_id`: ID do primeiro usuário
    - `user2_id`: ID do segundo usuário
    - `limit`: Número máximo de mensagens (opcional)
    - `offset`: Deslocamento para paginação (opcional)
  
  ## Retorno
  
    - `{:ok, messages}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def get_conversation(user1_id, user2_id, limit \\ 50, offset \\ 0) do
    GenServer.call(__MODULE__, {:get_conversation, user1_id, user2_id, limit, offset})
  end
  
  @doc """
  Obtém as conversas recentes de um usuário.
  
  ## Parâmetros
  
    - `user_id`: ID do usuário
    - `limit`: Número máximo de conversas (opcional)
  
  ## Retorno
  
    - `{:ok, conversations}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def get_recent_conversations(user_id, limit \\ 10) do
    GenServer.call(__MODULE__, {:get_recent_conversations, user_id, limit})
  end
  
  @doc """
  Obtém o número de mensagens não lidas para um usuário.
  
  ## Parâmetros
  
    - `user_id`: ID do usuário
  
  ## Retorno
  
    - `{:ok, count}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def get_unread_count(user_id) do
    GenServer.call(__MODULE__, {:get_unread_count, user_id})
  end
  
  @doc """
  Obtém uma mensagem específica pelo seu ID.
  
  ## Parâmetros
  
    - `message_id`: ID da mensagem
  
  ## Retorno
  
    - `{:ok, message}` em caso de sucesso
    - `{:error, :message_not_found}` se a mensagem não for encontrada
  """
  def get_message(message_id) do
    GenServer.call(__MODULE__, {:get_message, message_id})
  end
  
  # Callbacks do GenServer
  
  @impl true
  def init(_opts) do
    {:ok, %{
      messages: %{},
      conversations: %{},
      user_messages: %{}
    }}
    #       content: "texto da mensagem",
    #       metadata: %{},
    #       timestamp: timestamp,
    #       read: false,
    #       read_at: nil
    #     }
    #   },
    #   conversations: %{
    #     "user1_id-user2_id" => ["message_id1", "message_id2", ...]
    #   },
    #   user_messages: %{
    #     "user_id" => %{
    #       sent: ["message_id1", "message_id2", ...],
    #       received: ["message_id3", "message_id4", ...],
    #       unread: ["message_id3", "message_id4", ...]
    #     }
    #   }
    # }
    {:ok, %{messages: %{}, conversations: %{}, user_messages: %{}}}
  end
  
  @impl true
  def handle_call({:send_message, sender_id, recipient_id, content, metadata}, _from, state) do
    Logger.debug("Enviando mensagem direta", %{
      module: __MODULE__,
      sender_id: sender_id,
      recipient_id: recipient_id
    })
    
    # Gera um ID único para a mensagem
    message_id = UUID.uuid4()
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()
    
    # Cria a mensagem
    message = %{
      id: message_id,
      sender_id: sender_id,
      recipient_id: recipient_id,
      content: content,
      metadata: metadata,
      timestamp: timestamp,
      read: false,
      read_at: nil
    }
    
    # Atualiza o estado
    new_state = add_message_to_state(state, message)
    
    # Tenta entregar a mensagem se o destinatário estiver online
    case ConnectionManager.send_to_user(recipient_id, %{
      type: "message.received",
      payload: %{
        id: message_id,
        sender_id: sender_id,
        content: content,
        metadata: metadata,
        timestamp: timestamp
      }
    }) do
      :ok -> 
        # Mensagem entregue com sucesso
        Logger.debug("Mensagem entregue ao destinatário", %{
          module: __MODULE__,
          message_id: message_id,
          recipient_id: recipient_id
        })
        
      {:error, :user_not_connected} ->
        # Destinatário offline, a mensagem será entregue quando ele se conectar
        Logger.debug("Destinatário offline, mensagem será entregue posteriormente", %{
          module: __MODULE__,
          message_id: message_id,
          recipient_id: recipient_id
        })
        
      {:error, reason} ->
        Logger.error("Erro ao entregar mensagem", %{
          module: __MODULE__,
          message_id: message_id,
          recipient_id: recipient_id,
          error: reason
        })
    end
    
    # Publica evento de mensagem enviada
    try do
      if Code.ensure_loaded?(Deeper_Hub.Core.EventBus) do
        Deeper_Hub.Core.EventBus.publish(:direct_message_sent, %{
          message_id: message_id,
          sender_id: sender_id,
          recipient_id: recipient_id,
          timestamp: :os.system_time(:millisecond)
        })
      end
    rescue
      _ -> :ok
    end
    
    {:reply, {:ok, message_id}, new_state}
  end
  
  @impl true
  def handle_call({:mark_as_read, message_id, user_id}, _from, state) do
    case Map.get(state.messages, message_id) do
      nil ->
        # Mensagem não encontrada
        {:reply, {:error, :message_not_found}, state}
        
      message ->
        if message.recipient_id != user_id do
          # Apenas o destinatário pode marcar como lida
          {:reply, {:error, :not_recipient}, state}
        else
          # Marca a mensagem como lida
          read_at = DateTime.utc_now() |> DateTime.to_iso8601()
          updated_message = %{message | read: true, read_at: read_at}
          
          # Atualiza o estado
          new_messages = Map.put(state.messages, message_id, updated_message)
          
          # Remove da lista de não lidas
          user_messages = Map.get(state.user_messages, user_id, %{sent: [], received: [], unread: []})
          new_unread = Enum.filter(user_messages.unread, fn id -> id != message_id end)
          new_user_messages = %{user_messages | unread: new_unread}
          
          new_state = %{
            state | 
            messages: new_messages,
            user_messages: Map.put(state.user_messages, user_id, new_user_messages)
          }
          
          # Publica evento de mensagem lida
          try do
            if Code.ensure_loaded?(Deeper_Hub.Core.EventBus) do
              Deeper_Hub.Core.EventBus.publish(:direct_message_read, %{
                message_id: message_id,
                user_id: user_id,
                timestamp: :os.system_time(:millisecond)
              })
            end
          rescue
            _ -> :ok
          end
          
          {:reply, :ok, new_state}
        end
    end
  end
  
  @impl true
  def handle_call({:get_conversation, user1_id, user2_id, limit, offset}, _from, state) do
    # Obtém a chave de conversa (ordenada para garantir consistência)
    conversation_key = conversation_key(user1_id, user2_id)
    
    # Obtém os IDs das mensagens da conversa
    message_ids = Map.get(state.conversations, conversation_key, [])
    
    # Aplica paginação
    paginated_ids = message_ids
                    |> Enum.reverse() # Mais recentes primeiro
                    |> Enum.drop(offset)
                    |> Enum.take(limit)
    
    # Obtém as mensagens
    messages = Enum.map(paginated_ids, fn id -> 
      Map.get(state.messages, id)
    end)
    |> Enum.filter(fn message -> message != nil end)
    
    {:reply, {:ok, messages}, state}
  end
  
  @impl true
  def handle_call({:get_recent_conversations, user_id, limit}, _from, state) do
    # Obtém todas as conversas que envolvem o usuário
    conversations = Enum.filter(state.conversations, fn {key, _} ->
      String.contains?(key, user_id)
    end)
    
    # Obtém a última mensagem de cada conversa
    recent_conversations = Enum.map(conversations, fn {key, message_ids} ->
      # Extrai o ID do outro usuário da chave
      other_user_id = String.replace(key, user_id, "")
                      |> String.replace("-", "")
      
      # Obtém o ID da última mensagem
      last_message_id = List.last(message_ids)
      last_message = Map.get(state.messages, last_message_id)
      
      # Conta mensagens não lidas
      unread_count = Enum.count(Map.get(state.user_messages, user_id, %{unread: []}).unread, fn id ->
        message = Map.get(state.messages, id)
        message != nil && message.sender_id == other_user_id
      end)
      
      %{
        user_id: other_user_id,
        last_message: last_message,
        unread_count: unread_count
      }
    end)
    |> Enum.sort_by(fn conv -> 
      conv.last_message.timestamp
    end, {:desc, DateTime})
    |> Enum.take(limit)
    
    {:reply, {:ok, recent_conversations}, state}
  end
  
  @impl true
  def handle_call({:get_unread_count, user_id}, _from, state) do
    # Obtém a contagem de mensagens não lidas
    unread_count = length(Map.get(state.user_messages, user_id, %{unread: []}).unread)
    
    {:reply, {:ok, unread_count}, state}
  end
  
  @impl true
  def handle_call({:get_message, message_id}, _from, state) do
    # Busca a mensagem pelo ID
    case Map.get(state.messages, message_id) do
      nil ->
        {:reply, {:error, :message_not_found}, state}
        
      message ->
        {:reply, {:ok, message}, state}
    end
  end
  
  # Funções auxiliares
  
  # Adiciona uma mensagem ao estado
  defp add_message_to_state(state, message) do
    # Atualiza o mapa de mensagens
    new_messages = Map.put(state.messages, message.id, message)
    
    # Atualiza a conversa
    conversation_key = conversation_key(message.sender_id, message.recipient_id)
    conversation_messages = Map.get(state.conversations, conversation_key, [])
    new_conversations = Map.put(
      state.conversations, 
      conversation_key, 
      conversation_messages ++ [message.id]
    )
    
    # Atualiza as mensagens do remetente
    sender_messages = Map.get(state.user_messages, message.sender_id, %{sent: [], received: [], unread: []})
    new_sender_messages = %{
      sent: sender_messages.sent ++ [message.id],
      received: sender_messages.received,
      unread: sender_messages.unread
    }
    
    # Atualiza as mensagens do destinatário
    recipient_messages = Map.get(state.user_messages, message.recipient_id, %{sent: [], received: [], unread: []})
    new_recipient_messages = %{
      sent: recipient_messages.sent,
      received: recipient_messages.received ++ [message.id],
      unread: recipient_messages.unread ++ [message.id]
    }
    
    # Atualiza o estado
    %{
      state |
      messages: new_messages,
      conversations: new_conversations,
      user_messages: state.user_messages
                    |> Map.put(message.sender_id, new_sender_messages)
                    |> Map.put(message.recipient_id, new_recipient_messages)
    }
  end
  
  # Gera uma chave de conversa consistente
  defp conversation_key(user1_id, user2_id) do
    if user1_id <= user2_id do
      "#{user1_id}-#{user2_id}"
    else
      "#{user2_id}-#{user1_id}"
    end
  end
end
