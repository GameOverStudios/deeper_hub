defmodule Deeper_Hub.Core.Communications.Channels.ChannelManager do
  @moduledoc """
  Gerenciador de canais de comunicação.
  
  Este módulo gerencia canais de comunicação, permitindo que usuários
  se inscrevam em canais e recebam mensagens publicadas neles.
  """
  
  use GenServer
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Communications.ConnectionManager
  
  @doc """
  Inicia o gerenciador de canais.
  
  ## Retorno
  
    - `{:ok, pid}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def start_link(opts \\ []) do
    Logger.info("Iniciando gerenciador de canais", %{module: __MODULE__})
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Cria um novo canal.
  
  ## Parâmetros
  
    - `channel_name`: Nome do canal
    - `creator_id`: ID do usuário que está criando o canal
    - `metadata`: Metadados do canal (opcional)
  
  ## Retorno
  
    - `{:ok, channel_id}` em caso de sucesso
    - `{:error, :channel_exists}` se o canal já existir
    - `{:error, reason}` em caso de falha
  """
  def create_channel(channel_name, creator_id, metadata \\ %{}) do
    GenServer.call(__MODULE__, {:create_channel, channel_name, creator_id, metadata})
  end
  
  @doc """
  Inscreve um usuário em um canal.
  
  ## Parâmetros
  
    - `channel_name`: Nome do canal
    - `user_id`: ID do usuário
  
  ## Retorno
  
    - `:ok` em caso de sucesso
    - `{:error, :channel_not_found}` se o canal não existir
    - `{:error, reason}` em caso de falha
  """
  def subscribe(channel_name, user_id) do
    GenServer.call(__MODULE__, {:subscribe, channel_name, user_id})
  end
  
  @doc """
  Cancela a inscrição de um usuário em um canal.
  
  ## Parâmetros
  
    - `channel_name`: Nome do canal
    - `user_id`: ID do usuário
  
  ## Retorno
  
    - `:ok` em caso de sucesso
    - `{:error, :channel_not_found}` se o canal não existir
    - `{:error, :not_subscribed}` se o usuário não estiver inscrito
    - `{:error, reason}` em caso de falha
  """
  def unsubscribe(channel_name, user_id) do
    GenServer.call(__MODULE__, {:unsubscribe, channel_name, user_id})
  end
  
  @doc """
  Publica uma mensagem em um canal.
  
  ## Parâmetros
  
    - `channel_name`: Nome do canal
    - `sender_id`: ID do remetente
    - `content`: Conteúdo da mensagem
    - `metadata`: Metadados da mensagem (opcional)
  
  ## Retorno
  
    - `{:ok, message_id, recipient_count}` em caso de sucesso
    - `{:error, :channel_not_found}` se o canal não existir
    - `{:error, reason}` em caso de falha
  """
  def publish(channel_name, sender_id, content, metadata \\ %{}) do
    GenServer.call(__MODULE__, {:publish, channel_name, sender_id, content, metadata})
  end
  
  @doc """
  Lista os canais disponíveis.
  
  ## Parâmetros
  
    - `filter`: Filtro para os canais (opcional)
  
  ## Retorno
  
    - `{:ok, channels}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def list_channels(filter \\ nil) do
    GenServer.call(__MODULE__, {:list_channels, filter})
  end
  
  @doc """
  Obtém informações sobre um canal.
  
  ## Parâmetros
  
    - `channel_name`: Nome do canal
  
  ## Retorno
  
    - `{:ok, channel}` em caso de sucesso
    - `{:error, :channel_not_found}` se o canal não existir
    - `{:error, reason}` em caso de falha
  """
  def get_channel_info(channel_name) do
    GenServer.call(__MODULE__, {:get_channel_info, channel_name})
  end
  
  @doc """
  Lista os usuários inscritos em um canal.
  
  ## Parâmetros
  
    - `channel_name`: Nome do canal
  
  ## Retorno
  
    - `{:ok, users}` em caso de sucesso
    - `{:error, :channel_not_found}` se o canal não existir
    - `{:error, reason}` em caso de falha
  """
  def list_subscribers(channel_name) do
    GenServer.call(__MODULE__, {:list_subscribers, channel_name})
  end
  
  # Callbacks do GenServer
  
  @impl true
  def init(_opts) do
    # Estado: %{
    #   channels: %{
    #     "channel_name" => %{
    #       id: "channel_id",
    #       name: "channel_name",
    #       creator_id: "user_id",
    #       created_at: timestamp,
    #       metadata: %{},
    #       subscribers: MapSet.new(["user_id1", "user_id2", ...]),
    #       messages: ["message_id1", "message_id2", ...]
    #     }
    #   },
    #   user_subscriptions: %{
    #     "user_id" => ["channel_name1", "channel_name2", ...]
    #   }
    # }
    {:ok, %{channels: %{}, user_subscriptions: %{}}}
  end
  
  @impl true
  def handle_call({:create_channel, channel_name, creator_id, metadata}, _from, state) do
    Logger.debug("Criando canal", %{
      module: __MODULE__,
      channel_name: channel_name,
      creator_id: creator_id
    })
    
    if Map.has_key?(state.channels, channel_name) do
      {:reply, {:error, :channel_exists}, state}
    else
      # Gera um ID único para o canal
      channel_id = UUID.uuid4()
      timestamp = DateTime.utc_now() |> DateTime.to_iso8601()
      
      # Cria o canal
      channel = %{
        id: channel_id,
        name: channel_name,
        creator_id: creator_id,
        created_at: timestamp,
        metadata: metadata,
        subscribers: MapSet.new([creator_id]), # O criador é automaticamente inscrito
        messages: []
      }
      
      # Atualiza o estado
      new_channels = Map.put(state.channels, channel_name, channel)
      
      # Atualiza as inscrições do usuário
      user_subs = Map.get(state.user_subscriptions, creator_id, [])
      new_user_subs = [channel_name | user_subs]
      new_user_subscriptions = Map.put(state.user_subscriptions, creator_id, new_user_subs)
      
      new_state = %{
        channels: new_channels,
        user_subscriptions: new_user_subscriptions
      }
      
      # Publica evento de canal criado
      try do
        if Code.ensure_loaded?(Deeper_Hub.Core.EventBus) do
          Deeper_Hub.Core.EventBus.publish(:channel_created, %{
            channel_id: channel_id,
            channel_name: channel_name,
            creator_id: creator_id,
            timestamp: :os.system_time(:millisecond)
          })
        end
      rescue
        _ -> :ok
      end
      
      {:reply, {:ok, channel_id}, new_state}
    end
  end
  
  @impl true
  def handle_call({:subscribe, channel_name, user_id}, _from, state) do
    Logger.debug("Inscrevendo usuário em canal", %{
      module: __MODULE__,
      channel_name: channel_name,
      user_id: user_id
    })
    
    case Map.get(state.channels, channel_name) do
      nil ->
        {:reply, {:error, :channel_not_found}, state}
        
      channel ->
        # Adiciona o usuário aos inscritos do canal
        new_subscribers = MapSet.put(channel.subscribers, user_id)
        new_channel = %{channel | subscribers: new_subscribers}
        new_channels = Map.put(state.channels, channel_name, new_channel)
        
        # Atualiza as inscrições do usuário
        user_subs = Map.get(state.user_subscriptions, user_id, [])
        new_user_subs = if Enum.member?(user_subs, channel_name) do
          user_subs
        else
          [channel_name | user_subs]
        end
        new_user_subscriptions = Map.put(state.user_subscriptions, user_id, new_user_subs)
        
        new_state = %{
          channels: new_channels,
          user_subscriptions: new_user_subscriptions
        }
        
        # Publica evento de inscrição em canal
        try do
          if Code.ensure_loaded?(Deeper_Hub.Core.EventBus) do
            Deeper_Hub.Core.EventBus.publish(:channel_subscription, %{
              channel_name: channel_name,
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
  
  @impl true
  def handle_call({:unsubscribe, channel_name, user_id}, _from, state) do
    Logger.debug("Cancelando inscrição de usuário em canal", %{
      module: __MODULE__,
      channel_name: channel_name,
      user_id: user_id
    })
    
    case Map.get(state.channels, channel_name) do
      nil ->
        {:reply, {:error, :channel_not_found}, state}
        
      channel ->
        if not MapSet.member?(channel.subscribers, user_id) do
          {:reply, {:error, :not_subscribed}, state}
        else
          # Remove o usuário dos inscritos do canal
          new_subscribers = MapSet.delete(channel.subscribers, user_id)
          new_channel = %{channel | subscribers: new_subscribers}
          new_channels = Map.put(state.channels, channel_name, new_channel)
          
          # Atualiza as inscrições do usuário
          user_subs = Map.get(state.user_subscriptions, user_id, [])
          new_user_subs = Enum.filter(user_subs, fn name -> name != channel_name end)
          new_user_subscriptions = Map.put(state.user_subscriptions, user_id, new_user_subs)
          
          new_state = %{
            channels: new_channels,
            user_subscriptions: new_user_subscriptions
          }
          
          # Publica evento de cancelamento de inscrição
          try do
            if Code.ensure_loaded?(Deeper_Hub.Core.EventBus) do
              Deeper_Hub.Core.EventBus.publish(:channel_unsubscription, %{
                channel_name: channel_name,
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
  def handle_call({:publish, channel_name, sender_id, content, metadata}, _from, state) do
    Logger.debug("Publicando mensagem em canal", %{
      module: __MODULE__,
      channel_name: channel_name,
      sender_id: sender_id
    })
    
    case Map.get(state.channels, channel_name) do
      nil ->
        {:reply, {:error, :channel_not_found}, state}
        
      channel ->
        # Gera um ID único para a mensagem
        message_id = UUID.uuid4()
        timestamp = DateTime.utc_now() |> DateTime.to_iso8601()
        
        # Cria a mensagem
        message = %{
          id: message_id,
          channel_name: channel_name,
          sender_id: sender_id,
          content: content,
          metadata: metadata,
          timestamp: timestamp
        }
        
        # Atualiza o canal com a nova mensagem
        new_channel = %{channel | messages: [message_id | channel.messages]}
        new_channels = Map.put(state.channels, channel_name, new_channel)
        
        new_state = %{state | channels: new_channels}
        
        # Envia a mensagem para todos os inscritos online
        recipient_count = deliver_message_to_subscribers(channel, message)
        
        # Publica evento de mensagem publicada
        try do
          if Code.ensure_loaded?(Deeper_Hub.Core.EventBus) do
            Deeper_Hub.Core.EventBus.publish(:channel_message_published, %{
              channel_name: channel_name,
              message_id: message_id,
              sender_id: sender_id,
              recipient_count: recipient_count,
              timestamp: :os.system_time(:millisecond)
            })
          end
        rescue
          _ -> :ok
        end
        
        # Salva a mensagem no armazenamento persistente
        spawn(fn ->
          Deeper_Hub.Core.Communications.Channels.ChannelStorage.save_message(message)
        end)
        
        {:reply, {:ok, message_id, recipient_count}, new_state}
    end
  end
  
  @impl true
  def handle_call({:list_channels, filter}, _from, state) do
    Logger.debug("Listando canais", %{
      module: __MODULE__,
      filter: filter
    })
    
    channels = state.channels
    |> Enum.map(fn {name, channel} ->
      %{
        id: channel.id,
        name: name,
        creator_id: channel.creator_id,
        created_at: channel.created_at,
        metadata: channel.metadata,
        subscriber_count: MapSet.size(channel.subscribers)
      }
    end)
    |> filter_channels(filter)
    
    {:reply, {:ok, channels}, state}
  end
  
  @impl true
  def handle_call({:get_channel_info, channel_name}, _from, state) do
    Logger.debug("Obtendo informações do canal", %{
      module: __MODULE__,
      channel_name: channel_name
    })
    
    case Map.get(state.channels, channel_name) do
      nil ->
        {:reply, {:error, :channel_not_found}, state}
        
      channel ->
        channel_info = %{
          id: channel.id,
          name: channel.name,
          creator_id: channel.creator_id,
          created_at: channel.created_at,
          metadata: channel.metadata,
          subscriber_count: MapSet.size(channel.subscribers),
          message_count: length(channel.messages)
        }
        
        {:reply, {:ok, channel_info}, state}
    end
  end
  
  @impl true
  def handle_call({:list_subscribers, channel_name}, _from, state) do
    Logger.debug("Listando inscritos do canal", %{
      module: __MODULE__,
      channel_name: channel_name
    })
    
    case Map.get(state.channels, channel_name) do
      nil ->
        {:reply, {:error, :channel_not_found}, state}
        
      channel ->
        subscribers = MapSet.to_list(channel.subscribers)
        {:reply, {:ok, subscribers}, state}
    end
  end
  
  # Funções auxiliares
  
  # Entrega uma mensagem para todos os inscritos online
  defp deliver_message_to_subscribers(channel, message) do
    # Prepara a mensagem para envio
    ws_message = %{
      type: "channel.message",
      payload: %{
        id: message.id,
        channel_name: message.channel_name,
        sender_id: message.sender_id,
        content: message.content,
        metadata: message.metadata,
        timestamp: message.timestamp
      }
    }
    
    # Conta quantos usuários receberam a mensagem
    Enum.reduce(MapSet.to_list(channel.subscribers), 0, fn user_id, count ->
      case ConnectionManager.send_to_user(user_id, ws_message) do
        :ok -> count + 1
        _ -> count
      end
    end)
  end
  
  # Filtra canais com base em critérios
  defp filter_channels(channels, nil), do: channels
  defp filter_channels(channels, filter) when is_map(filter) do
    Enum.filter(channels, fn channel ->
      matches_filter(channel, filter)
    end)
  end
  
  # Verifica se um canal corresponde a um filtro
  defp matches_filter(channel, %{name: name}) when is_binary(name) do
    String.contains?(String.downcase(channel.name), String.downcase(name))
  end
  
  defp matches_filter(channel, %{creator_id: creator_id}) when is_binary(creator_id) do
    channel.creator_id == creator_id
  end
  
  defp matches_filter(channel, %{metadata: metadata}) when is_map(metadata) do
    Enum.all?(metadata, fn {key, value} ->
      Map.get(channel.metadata, key) == value
    end)
  end
  
  defp matches_filter(channel, filter) when is_map(filter) do
    Enum.all?(filter, fn {key, value} ->
      matches_filter(channel, %{key => value})
    end)
  end
end
