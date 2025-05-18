defmodule Deeper_Hub.Core.Communications.ConnectionManager do
  @moduledoc """
  Gerenciador de conexões WebSocket.
  
  Este módulo rastreia conexões ativas de usuários e permite enviar mensagens
  para usuários específicos.
  """
  
  use GenServer
  
  alias Deeper_Hub.Core.Logger
  
  @doc """
  Inicia o gerenciador de conexões.
  
  ## Retorno
  
    - `{:ok, pid}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def start_link(opts \\ []) do
    Logger.info("Iniciando gerenciador de conexões", %{module: __MODULE__})
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Registra uma conexão de usuário.
  
  ## Parâmetros
  
    - `user_id`: ID do usuário
    - `pid`: PID do processo de conexão WebSocket
  
  ## Retorno
  
    - `:ok` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def register(user_id, pid) do
    GenServer.call(__MODULE__, {:register, user_id, pid})
  end
  
  @doc """
  Envia uma mensagem para um usuário específico.
  
  ## Parâmetros
  
    - `user_id`: ID do usuário destinatário
    - `message`: Mensagem a ser enviada (mapa ou string JSON)
  
  ## Retorno
  
    - `:ok` em caso de sucesso
    - `{:error, :user_not_connected}` se o usuário não estiver conectado
    - `{:error, reason}` em caso de falha
  """
  def send_to_user(user_id, message) do
    GenServer.call(__MODULE__, {:send_to_user, user_id, message})
  end
  
  @doc """
  Verifica se um usuário está online.
  
  ## Parâmetros
  
    - `user_id`: ID do usuário
  
  ## Retorno
  
    - `{:ok, true}` se o usuário estiver online
    - `{:ok, false}` se o usuário não estiver online
  """
  def is_online?(user_id) do
    GenServer.call(__MODULE__, {:is_online, user_id})
  end
  
  @doc """
  Obtém a conexão de um usuário específico.
  
  ## Parâmetros
  
    - `user_id`: ID do usuário
  
  ## Retorno
  
    - `{:ok, pid}` se o usuário estiver conectado
    - `{:error, :not_connected}` se o usuário não estiver conectado
  """
  def get_user_connection(user_id) do
    GenServer.call(__MODULE__, {:get_connection, user_id})
  end
  
  @doc """
  Obtém a lista de usuários online.
  
  ## Retorno
  
    - `{:ok, [user_id]}` lista de IDs de usuários online
  """
  def online_users do
    GenServer.call(__MODULE__, :online_users)
  end
  
  @doc """
  Remove um usuário do registro de conexões.
  
  ## Parâmetros
  
    - `user_id`: ID do usuário
  
  ## Retorno
  
    - `:ok` em caso de sucesso
  """
  def unregister(user_id) do
    GenServer.cast(__MODULE__, {:unregister, user_id})
  end
  
  # Callbacks do GenServer
  
  @impl true
  def init(_opts) do
    # Estado: %{
    #   users: %{"user_id" => pid},  # Mapa de usuários para PIDs
    #   pids: %{pid => "user_id"}    # Mapa reverso para facilitar a limpeza
    # }
    {:ok, %{users: %{}, pids: %{}}}
  end
  
  @impl true
  def handle_call({:register, user_id, pid}, _from, state) do
    Logger.debug("Registrando conexão de usuário", %{
      module: __MODULE__,
      user_id: user_id,
      pid: inspect(pid)
    })
    
    # Monitora o processo para detectar desconexões
    Process.monitor(pid)
    
    # Atualiza o estado
    new_state = %{
      users: Map.put(state.users, user_id, pid),
      pids: Map.put(state.pids, pid, user_id)
    }
    
    # Publica evento de usuário conectado
    try do
      if Code.ensure_loaded?(Deeper_Hub.Core.EventBus) do
        Deeper_Hub.Core.EventBus.publish(:user_connected, %{
          user_id: user_id,
          timestamp: :os.system_time(:millisecond)
        })
      end
    rescue
      _ -> :ok
    end
    
    {:reply, :ok, new_state}
  end
  
  @impl true
  def handle_call({:send_to_user, user_id, message}, _from, state) do
    case Map.get(state.users, user_id) do
      nil -> 
        Logger.debug("Tentativa de enviar mensagem para usuário não conectado", %{
          module: __MODULE__,
          user_id: user_id
        })
        
        {:reply, {:error, :user_not_connected}, state}
        
      pid -> 
        Logger.debug("Enviando mensagem para usuário", %{
          module: __MODULE__,
          user_id: user_id,
          pid: inspect(pid)
        })
        
        # Envia a mensagem para o processo WebSocket
        send(pid, {:send, message})
        
        {:reply, :ok, state}
    end
  end
  
  @impl true
  def handle_call({:is_online, user_id}, _from, state) do
    is_online = Map.has_key?(state.users, user_id)
    {:reply, {:ok, is_online}, state}
  end
  
  @impl true
  def handle_call({:get_connection, user_id}, _from, state) do
    case Map.get(state.users, user_id) do
      nil -> 
        {:reply, {:error, :not_connected}, state}
        
      pid -> 
        {:reply, {:ok, pid}, state}
    end
  end
  
  @impl true
  def handle_call(:online_users, _from, state) do
    users = Map.keys(state.users)
    {:reply, {:ok, users}, state}
  end
  
  @impl true
  def handle_cast({:unregister, user_id}, state) do
    Logger.debug("Removendo registro de usuário", %{
      module: __MODULE__,
      user_id: user_id
    })
    
    case Map.get(state.users, user_id) do
      nil -> 
        # Usuário já não está registrado
        {:noreply, state}
        
      pid -> 
        # Remove o usuário dos mapas
        new_state = %{
          users: Map.delete(state.users, user_id),
          pids: Map.delete(state.pids, pid)
        }
        
        # Publica evento de usuário desconectado
        try do
          if Code.ensure_loaded?(Deeper_Hub.Core.EventBus) do
            Deeper_Hub.Core.EventBus.publish(:user_disconnected, %{
              user_id: user_id,
              timestamp: :os.system_time(:millisecond)
            })
          end
        rescue
          _ -> :ok
        end
        
        {:noreply, new_state}
    end
  end
  
  # Manipula notificações de processos terminados
  @impl true
  def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
    Logger.debug("Processo de conexão encerrado", %{
      module: __MODULE__,
      pid: inspect(pid),
      reason: reason
    })
    
    case Map.get(state.pids, pid) do
      nil -> 
        # PID não está registrado
        {:noreply, state}
        
      user_id -> 
        # Remove o usuário dos mapas
        new_state = %{
          users: Map.delete(state.users, user_id),
          pids: Map.delete(state.pids, pid)
        }
        
        # Publica evento de usuário desconectado
        try do
          if Code.ensure_loaded?(Deeper_Hub.Core.EventBus) do
            Deeper_Hub.Core.EventBus.publish(:user_disconnected, %{
              user_id: user_id,
              reason: reason,
              timestamp: :os.system_time(:millisecond)
            })
          end
        rescue
          _ -> :ok
        end
        
        {:noreply, new_state}
    end
  end
  
  @impl true
  def handle_info(_info, state) do
    {:noreply, state}
  end
end
