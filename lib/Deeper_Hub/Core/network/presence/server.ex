defmodule DeeperHub.Core.Network.Presence.Server do
  @moduledoc """
  Servidor de rastreamento de presença online.
  
  Este módulo implementa um sistema de rastreamento de presença que mantém
  informações sobre quais usuários estão online e em quais canais estão ativos.
  
  O servidor de presença é otimizado para alta concorrência, utilizando ETS
  para armazenamento eficiente e rápido acesso aos dados de presença.
  """
  use GenServer
  
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  
  # Nome da tabela ETS para armazenamento de dados de presença
  @presence_table :deeperhub_presence
  
  # Intervalo para verificação de heartbeats (30 segundos)
  @heartbeat_interval 30_000
  
  # Tempo limite para considerar um usuário offline (2 minutos)
  @presence_timeout 120_000
  
  # Estrutura que representa o estado do servidor
  defstruct [
    :table_ref,      # Referência para a tabela ETS
    :timer_ref,      # Referência para o timer de heartbeat
    :user_count,     # Contador de usuários online
    :start_time      # Timestamp de início do servidor
  ]
  
  @doc """
  Inicia o servidor de presença.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Registra a presença de um usuário.
  
  ## Parâmetros
  
  - `connection_id` - ID da conexão
  - `user_id` - ID do usuário (opcional)
  - `metadata` - Metadados adicionais
  
  ## Retorno
  
  - `:ok` - Presença registrada com sucesso
  """
  def register(connection_id, user_id \\ nil, metadata \\ %{}) do
    GenServer.cast(__MODULE__, {:register, connection_id, user_id, metadata})
  end
  
  @doc """
  Atualiza a presença de um usuário.
  
  ## Parâmetros
  
  - `connection_id` - ID da conexão
  - `metadata` - Metadados adicionais a serem atualizados
  
  ## Retorno
  
  - `:ok` - Presença atualizada com sucesso
  """
  def update(connection_id, metadata) do
    GenServer.cast(__MODULE__, {:update, connection_id, metadata})
  end
  
  @doc """
  Cancela o registro de presença de um usuário.
  
  ## Parâmetros
  
  - `connection_id` - ID da conexão
  
  ## Retorno
  
  - `:ok` - Registro cancelado com sucesso
  """
  def unregister(connection_id) do
    GenServer.cast(__MODULE__, {:unregister, connection_id})
  end
  
  @doc """
  Verifica se um usuário está online.
  
  ## Parâmetros
  
  - `user_id` - ID do usuário
  
  ## Retorno
  
  - `{:ok, connection_ids}` - Lista de IDs de conexão associados ao usuário
  - `{:error, :not_found}` - Usuário não encontrado
  """
  def user_online?(user_id) do
    GenServer.call(__MODULE__, {:user_online, user_id})
  end
  
  @doc """
  Lista todos os usuários online.
  
  ## Retorno
  
  - `{:ok, users}` - Lista de usuários online com seus metadados
  """
  def list_online_users do
    GenServer.call(__MODULE__, :list_online_users)
  end
  
  @doc """
  Obtém estatísticas do servidor de presença.
  
  ## Retorno
  
  - `{:ok, stats}` - Estatísticas do servidor
  """
  def stats do
    GenServer.call(__MODULE__, :stats)
  end
  
  # Callbacks do GenServer
  
  @impl true
  def init(_opts) do
    Logger.info("Iniciando servidor de presença...", module: __MODULE__)
    
    # Cria a tabela ETS para armazenamento de dados de presença
    table_ref = :ets.new(@presence_table, [:set, :protected, :named_table])
    
    # Inicia o timer para verificação periódica de heartbeats
    timer_ref = Process.send_after(self(), :check_heartbeats, @heartbeat_interval)
    
    # Inicializa o estado do servidor
    state = %__MODULE__{
      table_ref: table_ref,
      timer_ref: timer_ref,
      user_count: 0,
      start_time: DateTime.utc_now()
    }
    
    {:ok, state}
  end
  
  @impl true
  def handle_cast({:register, connection_id, user_id, metadata}, state) do
    now = DateTime.utc_now()
    
    # Prepara os dados de presença
    presence_data = %{
      connection_id: connection_id,
      user_id: user_id,
      metadata: metadata,
      first_seen: now,
      last_heartbeat: now
    }
    
    # Insere os dados na tabela ETS
    :ets.insert(@presence_table, {connection_id, presence_data})
    
    # Se o user_id estiver definido, também cria um índice secundário
    if user_id do
      :ets.insert(@presence_table, {{:user, user_id}, connection_id})
    end
    
    # Atualiza o contador de usuários
    user_count = state.user_count + 1
    
    Logger.debug("Presença registrada: #{connection_id} (Usuário: #{user_id || "anônimo"})", module: __MODULE__)
    
    {:noreply, %{state | user_count: user_count}}
  end
  
  @impl true
  def handle_cast({:update, connection_id, metadata}, state) do
    # Busca os dados de presença existentes
    case :ets.lookup(@presence_table, connection_id) do
      [{^connection_id, presence_data}] ->
        # Atualiza os metadados e o timestamp de heartbeat
        updated_metadata = Map.merge(presence_data.metadata, metadata)
        updated_data = %{presence_data | 
          metadata: updated_metadata,
          last_heartbeat: DateTime.utc_now()
        }
        
        # Atualiza a tabela ETS
        :ets.insert(@presence_table, {connection_id, updated_data})
        
        Logger.debug("Presença atualizada: #{connection_id}", module: __MODULE__)
        
      [] ->
        Logger.warn("Tentativa de atualizar presença inexistente: #{connection_id}", module: __MODULE__)
    end
    
    {:noreply, state}
  end
  
  @impl true
  def handle_cast({:unregister, connection_id}, state) do
    # Busca os dados de presença
    case :ets.lookup(@presence_table, connection_id) do
      [{^connection_id, presence_data}] ->
        # Remove a entrada principal
        :ets.delete(@presence_table, connection_id)
        
        # Se o user_id estiver definido, também remove o índice secundário
        if presence_data.user_id do
          :ets.delete(@presence_table, {:user, presence_data.user_id})
        end
        
        # Atualiza o contador de usuários
        user_count = max(0, state.user_count - 1)
        
        Logger.debug("Presença removida: #{connection_id}", module: __MODULE__)
        
        {:noreply, %{state | user_count: user_count}}
        
      [] ->
        Logger.warn("Tentativa de remover presença inexistente: #{connection_id}", module: __MODULE__)
        {:noreply, state}
    end
  end
  
  @impl true
  def handle_call({:user_online, user_id}, _from, state) do
    # Busca todas as conexões associadas ao usuário
    connections = :ets.match(@presence_table, {{:user, user_id}, :"$1"})
    
    if connections != [] do
      # Extrai os IDs de conexão da lista de tuplas
      connection_ids = Enum.map(connections, fn [connection_id] -> connection_id end)
      {:reply, {:ok, connection_ids}, state}
    else
      {:reply, {:error, :not_found}, state}
    end
  end
  
  @impl true
  def handle_call(:list_online_users, _from, state) do
    # Busca todos os usuários online (com user_id definido)
    users = :ets.match(@presence_table, {{:user, :"$1"}, :"$2"})
    
    # Formata os resultados
    user_list = Enum.map(users, fn [user_id, connection_id] ->
      [{^connection_id, presence_data}] = :ets.lookup(@presence_table, connection_id)
      
      %{
        user_id: user_id,
        connection_id: connection_id,
        metadata: presence_data.metadata,
        first_seen: presence_data.first_seen,
        last_heartbeat: presence_data.last_heartbeat
      }
    end)
    
    {:reply, {:ok, user_list}, state}
  end
  
  @impl true
  def handle_call(:stats, _from, state) do
    # Calcula estatísticas do servidor
    now = DateTime.utc_now()
    uptime_seconds = DateTime.diff(now, state.start_time)
    
    # Conta o número total de conexões (incluindo anônimas)
    connection_count = :ets.info(@presence_table, :size) - state.user_count
    
    stats = %{
      user_count: state.user_count,
      connection_count: connection_count,
      uptime_seconds: uptime_seconds,
      start_time: state.start_time
    }
    
    {:reply, {:ok, stats}, state}
  end
  
  @impl true
  def handle_info(:check_heartbeats, state) do
    Logger.debug("Verificando heartbeats de presença...", module: __MODULE__)
    
    now = DateTime.utc_now()
    timeout_threshold = DateTime.add(now, -@presence_timeout, :millisecond)
    
    # Busca todas as conexões com heartbeat expirado
    expired_connections = :ets.match(@presence_table, {:"$1", %{last_heartbeat: :"$2"}})
    |> Enum.filter(fn [_connection_id, last_heartbeat] ->
      DateTime.compare(last_heartbeat, timeout_threshold) == :lt
    end)
    |> Enum.map(fn [connection_id, _] -> connection_id end)
    
    # Remove as conexões expiradas
    Enum.each(expired_connections, fn connection_id ->
      case :ets.lookup(@presence_table, connection_id) do
        [{^connection_id, presence_data}] ->
          # Remove a entrada principal
          :ets.delete(@presence_table, connection_id)
          
          # Se o user_id estiver definido, também remove o índice secundário
          if presence_data.user_id do
            :ets.delete(@presence_table, {:user, presence_data.user_id})
          end
          
          Logger.debug("Presença expirada removida: #{connection_id}", module: __MODULE__)
          
        [] ->
          :ok
      end
    end)
    
    # Atualiza o contador de usuários
    user_count = max(0, state.user_count - length(expired_connections))
    
    # Agenda a próxima verificação
    timer_ref = Process.send_after(self(), :check_heartbeats, @heartbeat_interval)
    
    {:noreply, %{state | user_count: user_count, timer_ref: timer_ref}}
  end
  
  @impl true
  def terminate(_reason, state) do
    Logger.info("Encerrando servidor de presença...", module: __MODULE__)
    
    # Cancela o timer de heartbeat
    if state.timer_ref do
      Process.cancel_timer(state.timer_ref)
    end
    
    # Limpa a tabela ETS
    :ets.delete(@presence_table)
    
    :ok
  end
end
