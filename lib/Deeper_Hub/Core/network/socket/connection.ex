defmodule DeeperHub.Core.Network.Socket.Connection do
  @moduledoc """
  Gerencia uma conexão WebSocket individual.
  
  Este módulo implementa um GenServer que representa uma conexão WebSocket ativa.
  Cada conexão é um processo Erlang separado, permitindo alta concorrência e isolamento
  de falhas. O módulo é responsável por:
  
  - Processar mensagens recebidas do cliente
  - Enviar mensagens para o cliente
  - Gerenciar o estado da conexão
  - Lidar com desconexões e reconexões
  """
  use GenServer
  
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  
  # Estrutura que representa o estado de uma conexão
  defstruct [
    :id,           # ID único da conexão
    :user_id,      # ID do usuário associado (se autenticado)
    :socket,       # Referência ao socket Cowboy
    :subscriptions, # Lista de canais/tópicos assinados
    :metadata,     # Metadados adicionais (ex: informações do cliente)
    :last_activity # Timestamp da última atividade
  ]
  
  @type t :: %__MODULE__{
    id: String.t(),
    user_id: String.t() | nil,
    socket: reference(),
    subscriptions: list(String.t()),
    metadata: map(),
    last_activity: DateTime.t()
  }
  
  @doc """
  Inicia um novo processo de conexão WebSocket.
  
  ## Parâmetros
  
  - `socket`: Referência ao socket Cowboy
  - `opts`: Opções adicionais para a conexão
  
  ## Retorno
  
  - `{:ok, pid}`: Processo iniciado com sucesso
  - `{:error, reason}`: Falha ao iniciar o processo
  """
  def start_link(socket, opts \\ []) do
    connection_id = UUID.uuid4()
    
    # Registra o processo com um nome único usando o Registry
    name = {:via, Registry, {DeeperHub.Core.Network.Socket.Registry, connection_id}}
    
    # Inicia o GenServer com o nome registrado
    GenServer.start_link(__MODULE__, {connection_id, socket, opts}, name: name)
  end
  
  @doc """
  Envia uma mensagem para um cliente WebSocket.
  
  ## Parâmetros
  
  - `connection_id`: ID da conexão
  - `message`: Mensagem a ser enviada (será codificada como JSON)
  
  ## Retorno
  
  - `:ok`: Mensagem enviada com sucesso
  - `{:error, reason}`: Falha ao enviar a mensagem
  """
  def send_message(connection_id, message) do
    case Registry.lookup(DeeperHub.Core.Network.Socket.Registry, connection_id) do
      [{pid, _}] -> GenServer.cast(pid, {:send, message})
      [] -> {:error, :connection_not_found}
    end
  end
  
  @doc """
  Fecha uma conexão WebSocket.
  
  ## Parâmetros
  
  - `connection_id`: ID da conexão
  - `reason`: Motivo do fechamento (opcional)
  
  ## Retorno
  
  - `:ok`: Conexão fechada com sucesso
  - `{:error, reason}`: Falha ao fechar a conexão
  """
  def close(connection_id, reason \\ :normal) do
    case Registry.lookup(DeeperHub.Core.Network.Socket.Registry, connection_id) do
      [{pid, _}] -> GenServer.cast(pid, {:close, reason})
      [] -> {:error, :connection_not_found}
    end
  end
  
  # Callbacks do GenServer
  
  @impl true
  def init({connection_id, socket, opts}) do
    Logger.debug("Iniciando conexão WebSocket: #{connection_id}", module: __MODULE__)
    
    # Inicializa o estado da conexão
    state = %__MODULE__{
      id: connection_id,
      user_id: Keyword.get(opts, :user_id),
      socket: socket,
      subscriptions: [],
      metadata: Keyword.get(opts, :metadata, %{}),
      last_activity: DateTime.utc_now()
    }
    
    # Registra a conexão no sistema de presença (será implementado posteriormente)
    # DeeperHub.Core.Network.Presence.register(connection_id, state.user_id)
    
    {:ok, state}
  end
  
  @impl true
  def handle_cast({:send, message}, state) do
    # Aqui implementaremos o envio real da mensagem via WebSocket
    # Usando a API do Cowboy (será implementado posteriormente)
    Logger.debug("Enviando mensagem para #{state.id}: #{inspect(message)}", module: __MODULE__)
    
    # Atualiza o timestamp de última atividade
    state = %{state | last_activity: DateTime.utc_now()}
    
    {:noreply, state}
  end
  
  @impl true
  def handle_cast({:close, reason}, state) do
    Logger.debug("Fechando conexão WebSocket #{state.id}: #{inspect(reason)}", module: __MODULE__)
    
    # Aqui implementaremos o fechamento real da conexão WebSocket
    # Usando a API do Cowboy (será implementado posteriormente)
    
    # Cancela o registro no sistema de presença
    # DeeperHub.Core.Network.Presence.unregister(state.id)
    
    # Encerra o processo
    {:stop, :normal, state}
  end
  
  @impl true
  def handle_info({:websocket_message, message}, state) do
    Logger.debug("Mensagem recebida de #{state.id}: #{inspect(message)}", module: __MODULE__)
    
    # Processa a mensagem recebida (será implementado posteriormente)
    # process_message(message, state)
    
    # Atualiza o timestamp de última atividade
    state = %{state | last_activity: DateTime.utc_now()}
    
    {:noreply, state}
  end
  
  @impl true
  def handle_info({:websocket_close, reason}, state) do
    Logger.debug("Conexão WebSocket #{state.id} fechada: #{inspect(reason)}", module: __MODULE__)
    
    # Cancela o registro no sistema de presença
    # DeeperHub.Core.Network.Presence.unregister(state.id)
    
    # Encerra o processo
    {:stop, :normal, state}
  end
  
  @impl true
  def terminate(reason, state) do
    Logger.debug("Terminando conexão WebSocket #{state.id}: #{inspect(reason)}", module: __MODULE__)
    
    # Cancela o registro no sistema de presença (garantia adicional)
    # DeeperHub.Core.Network.Presence.unregister(state.id)
    
    :ok
  end
end
