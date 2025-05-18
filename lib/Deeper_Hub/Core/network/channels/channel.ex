defmodule DeeperHub.Core.Network.Channels.Channel do
  @moduledoc """
  Gerencia um canal de comunicação temático.
  
  Este módulo implementa um GenServer que representa um canal de comunicação.
  Cada canal é um processo Erlang separado, permitindo alta concorrência e
  isolamento de falhas. O módulo é responsável por:
  
  - Gerenciar assinaturas de clientes ao canal
  - Distribuir mensagens para os assinantes
  - Manter o estado e configurações do canal
  - Aplicar regras de permissão e moderação
  """
  use GenServer
  
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Network.PubSub.Broker
  
  # Estrutura que representa o estado de um canal
  defstruct [
    :id,               # ID único do canal
    :name,             # Nome do canal
    :topic,            # Tópico principal do canal
    :owner_id,         # ID do usuário proprietário do canal
    :subscribers,      # Mapa de assinantes (connection_id => metadata)
    :options,          # Opções de configuração do canal
    :created_at,       # Timestamp de criação do canal
    :last_activity,    # Timestamp da última atividade
    :message_count     # Contador de mensagens
  ]
  
  @type t :: %__MODULE__{
    id: String.t(),
    name: String.t(),
    topic: String.t(),
    owner_id: String.t(),
    subscribers: map(),
    options: map(),
    created_at: DateTime.t(),
    last_activity: DateTime.t(),
    message_count: non_neg_integer()
  }
  
  @doc """
  Cria um novo canal de comunicação.
  
  ## Parâmetros
  
  - `name` - Nome do canal
  - `owner_id` - ID do usuário proprietário
  - `opts` - Opções adicionais
    - `:topic` - Tópico principal do canal
    - `:private` - Se o canal é privado (padrão: false)
    - `:persistent` - Se o canal deve persistir sem assinantes (padrão: false)
  
  ## Retorno
  
  - `{:ok, channel_id}` - Canal criado com sucesso
  - `{:error, reason}` - Falha ao criar o canal
  """
  def create(name, owner_id, opts \\ []) do
    # Gera um ID único para o canal
    channel_id = UUID.uuid4()
    
    # Prepara as opções do canal
    channel_opts = %{
      topic: Keyword.get(opts, :topic, name),
      private: Keyword.get(opts, :private, false),
      persistent: Keyword.get(opts, :persistent, false),
      max_subscribers: Keyword.get(opts, :max_subscribers, 10_000),
      message_ttl: Keyword.get(opts, :message_ttl, 3600) # 1 hora em segundos
    }
    
    # Inicia o processo do canal
    DynamicSupervisor.start_child(
      DeeperHub.Core.Network.Channels.ChannelSupervisor,
      {__MODULE__, [channel_id, name, owner_id, channel_opts]}
    )
    |> case do
      {:ok, _pid} -> 
        Logger.info("Canal criado: #{name} (#{channel_id})", module: __MODULE__)
        {:ok, channel_id}
      {:error, reason} -> 
        Logger.error("Falha ao criar canal #{name}: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
  
  @doc """
  Inicia um processo de canal.
  """
  def start_link([channel_id, channel_name, owner_id, opts]) do
    # Registra o processo com um nome único usando o Registry
    registry_name = {:via, Registry, {DeeperHub.Core.Network.Channels.Registry, channel_id}}
    
    # Inicia o GenServer com o nome registrado
    GenServer.start_link(__MODULE__, {channel_id, channel_name, owner_id, opts}, name: registry_name)
  end
  
  @doc """
  Obtém informações sobre um canal.
  
  ## Parâmetros
  
  - `channel_id` - ID do canal
  
  ## Retorno
  
  - `{:ok, info}` - Informações do canal
  - `{:error, reason}` - Falha ao obter informações
  """
  def info(channel_id) do
    case lookup_channel(channel_id) do
      {:ok, pid} -> GenServer.call(pid, :info)
      error -> error
    end
  end
  
  @doc """
  Assina um canal para receber mensagens.
  
  ## Parâmetros
  
  - `channel_id` - ID do canal
  - `connection_id` - ID da conexão do assinante
  - `metadata` - Metadados adicionais do assinante
  
  ## Retorno
  
  - `:ok` - Assinatura criada com sucesso
  - `{:error, reason}` - Falha ao criar a assinatura
  """
  def subscribe(channel_id, connection_id, metadata \\ %{}) do
    case lookup_channel(channel_id) do
      {:ok, pid} -> GenServer.call(pid, {:subscribe, connection_id, metadata})
      error -> error
    end
  end
  
  @doc """
  Cancela a assinatura de um canal.
  
  ## Parâmetros
  
  - `channel_id` - ID do canal
  - `connection_id` - ID da conexão do assinante
  
  ## Retorno
  
  - `:ok` - Assinatura cancelada com sucesso
  - `{:error, reason}` - Falha ao cancelar a assinatura
  """
  def unsubscribe(channel_id, connection_id) do
    case lookup_channel(channel_id) do
      {:ok, pid} -> GenServer.cast(pid, {:unsubscribe, connection_id})
      error -> error
    end
  end
  
  @doc """
  Publica uma mensagem em um canal.
  
  ## Parâmetros
  
  - `channel_id` - ID do canal
  - `sender_id` - ID do remetente da mensagem
  - `message` - Conteúdo da mensagem
  - `opts` - Opções adicionais
  
  ## Retorno
  
  - `{:ok, message_id}` - Mensagem publicada com sucesso
  - `{:error, reason}` - Falha ao publicar a mensagem
  """
  def publish(channel_id, sender_id, message, opts \\ []) do
    case lookup_channel(channel_id) do
      {:ok, pid} -> GenServer.call(pid, {:publish, sender_id, message, opts})
      error -> error
    end
  end
  
  # Callbacks do GenServer
  
  @impl true
  def init({channel_id, channel_name, owner_id, opts}) do
    Logger.debug("Iniciando canal: #{channel_name} (#{channel_id})", module: __MODULE__)
    
    # Inicializa o estado do canal
    state = %__MODULE__{
      id: channel_id,
      name: channel_name,
      topic: opts.topic,
      owner_id: owner_id,
      subscribers: %{},
      options: opts,
      created_at: DateTime.utc_now(),
      last_activity: DateTime.utc_now(),
      message_count: 0
    }
    
    # Assina o tópico PubSub correspondente ao canal
    Broker.subscribe(channel_id, self())
    
    {:ok, state}
  end
  
  @impl true
  def handle_call(:info, _from, state) do
    # Prepara informações do canal para retorno
    info = %{
      id: state.id,
      name: state.name,
      topic: state.topic,
      owner_id: state.owner_id,
      subscriber_count: map_size(state.subscribers),
      private: state.options.private,
      persistent: state.options.persistent,
      created_at: state.created_at,
      last_activity: state.last_activity,
      message_count: state.message_count
    }
    
    {:reply, {:ok, info}, state}
  end
  
  @impl true
  def handle_call({:subscribe, connection_id, metadata}, _from, state) do
    # Verifica se o canal atingiu o limite de assinantes
    if map_size(state.subscribers) >= state.options.max_subscribers do
      {:reply, {:error, :channel_full}, state}
    else
      # Adiciona o assinante ao canal
      metadata = Map.put(metadata, :joined_at, DateTime.utc_now())
      subscribers = Map.put(state.subscribers, connection_id, metadata)
      
      # Atualiza o estado do canal
      state = %{state | 
        subscribers: subscribers,
        last_activity: DateTime.utc_now()
      }
      
      # Notifica sobre a nova assinatura
      Logger.debug("Novo assinante no canal #{state.name}: #{connection_id}", module: __MODULE__)
      
      # Publica mensagem de sistema sobre o novo assinante
      system_message = %{
        type: "system",
        event: "user_joined",
        connection_id: connection_id,
        timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
      }
      
      # Distribui a mensagem para todos os assinantes (exceto o novo)
      distribute_message(state, system_message, [connection_id])
      
      {:reply, :ok, state}
    end
  end
  
  @impl true
  def handle_call({:publish, sender_id, message, opts}, _from, state) do
    # Gera um ID único para a mensagem
    message_id = UUID.uuid4()
    
    # Prepara a mensagem formatada
    formatted_message = %{
      id: message_id,
      channel_id: state.id,
      sender_id: sender_id,
      content: message,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
    
    # Adiciona metadados opcionais à mensagem
    formatted_message = 
      if type = Keyword.get(opts, :type) do
        Map.put(formatted_message, :type, type)
      else
        formatted_message
      end
    
    # Distribui a mensagem para todos os assinantes
    exclude_list = Keyword.get(opts, :exclude, [])
    distribute_message(state, formatted_message, exclude_list)
    
    # Atualiza o estado do canal
    state = %{state | 
      message_count: state.message_count + 1,
      last_activity: DateTime.utc_now()
    }
    
    {:reply, {:ok, message_id}, state}
  end
  
  @impl true
  def handle_cast({:unsubscribe, connection_id}, state) do
    # Remove o assinante do canal
    {_metadata, subscribers} = Map.pop(state.subscribers, connection_id)
    
    # Atualiza o estado do canal
    state = %{state | 
      subscribers: subscribers,
      last_activity: DateTime.utc_now()
    }
    
    # Notifica sobre o cancelamento da assinatura
    Logger.debug("Assinante removido do canal #{state.name}: #{connection_id}", module: __MODULE__)
    
    # Publica mensagem de sistema sobre o assinante removido
    system_message = %{
      type: "system",
      event: "user_left",
      connection_id: connection_id,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
    
    # Distribui a mensagem para todos os assinantes
    distribute_message(state, system_message, [])
    
    # Verifica se o canal deve ser encerrado
    if map_size(subscribers) == 0 and not state.options.persistent do
      Logger.debug("Canal #{state.name} sem assinantes e não persistente, encerrando...", module: __MODULE__)
      {:stop, :normal, state}
    else
      {:noreply, state}
    end
  end
  
  @impl true
  def handle_info({:pubsub_message, message}, state) do
    # Processa mensagem recebida do sistema PubSub
    Logger.debug("Mensagem PubSub recebida no canal #{state.name}: #{inspect(message)}", module: __MODULE__)
    
    # Distribui a mensagem para todos os assinantes
    distribute_message(state, message.payload, [])
    
    # Atualiza o estado do canal
    state = %{state | 
      message_count: state.message_count + 1,
      last_activity: DateTime.utc_now()
    }
    
    {:noreply, state}
  end
  
  @impl true
  def terminate(reason, state) do
    Logger.debug("Encerrando canal #{state.name}: #{inspect(reason)}", module: __MODULE__)
    
    # Cancela a assinatura do tópico PubSub
    Broker.unsubscribe(state.id, self())
    
    :ok
  end
  
  # Funções privadas
  
  # Localiza um canal pelo ID
  defp lookup_channel(channel_id) do
    case Registry.lookup(DeeperHub.Core.Network.Channels.Registry, channel_id) do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :channel_not_found}
    end
  end
  
  # Distribui uma mensagem para todos os assinantes do canal
  defp distribute_message(state, message, exclude_list) do
    # Para cada assinante, envia a mensagem
    Enum.each(state.subscribers, fn {connection_id, _metadata} ->
      # Pula assinantes na lista de exclusão
      unless connection_id in exclude_list do
        # Envia a mensagem para o assinante
        DeeperHub.Core.Network.Socket.Connection.send_message(connection_id, message)
      end
    end)
  end
end
