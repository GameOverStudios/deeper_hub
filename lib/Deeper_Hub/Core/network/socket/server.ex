defmodule DeeperHub.Core.Network.Socket.Server do
  @moduledoc """
  Servidor HTTP/WebSocket usando Cowboy.
  
  Este módulo implementa um servidor HTTP/WebSocket de alta performance usando
  o Cowboy. Ele é responsável por:
  
  - Iniciar e gerenciar o servidor HTTP/WebSocket
  - Configurar rotas para endpoints WebSocket
  - Gerenciar o ciclo de vida do servidor
  
  O servidor é otimizado para alta concorrência, podendo lidar com milhares
  de conexões simultâneas, como em um servidor de jogos online.
  """
  use GenServer
  
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Network.Socket.Handler
  
  # Porta padrão para o servidor WebSocket
  @default_port 8080
  
  @doc """
  Inicia o servidor WebSocket.
  
  ## Opções
  
  - `:port` - Porta para o servidor (padrão: 8080)
  - `:max_connections` - Número máximo de conexões simultâneas (padrão: 100000)
  - `:backlog` - Tamanho da fila de conexões pendentes (padrão: 1024)
  
  ## Retorno
  
  - `{:ok, pid}` - Servidor iniciado com sucesso
  - `{:error, reason}` - Falha ao iniciar o servidor
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @impl true
  def init(opts) do
    Logger.info("Iniciando servidor WebSocket...", module: __MODULE__)
    
    # Obtém a porta do servidor das opções ou usa o valor padrão
    port = Keyword.get(opts, :port, @default_port)
    
    # Configurações para alta concorrência
    max_connections = Keyword.get(opts, :max_connections, 100_000)
    backlog = Keyword.get(opts, :backlog, 1024)
    
    # Define as rotas do servidor
    dispatch = :cowboy_router.compile([
      # Rota padrão para todas as hosts
      {:_, [
        # Rota para WebSocket
        {"/ws", Handler, %{}},
        # Rota para verificação de saúde do servidor
        {"/health", DeeperHub.Core.Network.Socket.HealthHandler, %{}},
        # Fallback para outras rotas
        {"/[...]", DeeperHub.Core.Network.Socket.NotFoundHandler, %{}}
      ]}
    ])
    
    # Configurações do servidor HTTP
    transport_opts = %{
      socket_opts: [
        port: port,
        # Configurações para alta concorrência
        backlog: backlog,
        max_connections: max_connections,
        # Configurações de socket
        nodelay: true,
        linger: {true, 30},
        send_timeout: 30_000,
        send_timeout_close: true
      ]
    }
    
    # Configurações do protocolo
    protocol_opts = %{
      env: %{dispatch: dispatch},
      # Configurações para alta concorrência
      max_keepalive: 1_000,
      timeout: 60_000,
      idle_timeout: 60_000 * 30, # 30 minutos
      inactivity_timeout: 60_000 * 60 # 1 hora
    }
    
    # Inicia o servidor HTTP/WebSocket
    case :cowboy.start_clear(:deeperhub_http, transport_opts, protocol_opts) do
      {:ok, _pid} ->
        Logger.info("Servidor WebSocket iniciado na porta #{port}", module: __MODULE__)
        # Estado inicial do servidor
        state = %{
          port: port,
          max_connections: max_connections,
          start_time: DateTime.utc_now(),
          connections: 0
        }
        {:ok, state}
        
      {:error, reason} ->
        Logger.error("Falha ao iniciar servidor WebSocket: #{inspect(reason)}", module: __MODULE__)
        {:stop, reason}
    end
  end
  
  @impl true
  def handle_call(:stats, _from, state) do
    # Calcula estatísticas do servidor
    uptime_seconds = DateTime.diff(DateTime.utc_now(), state.start_time)
    
    stats = %{
      port: state.port,
      max_connections: state.max_connections,
      current_connections: state.connections,
      uptime_seconds: uptime_seconds
    }
    
    {:reply, stats, state}
  end
  
  @impl true
  def handle_cast({:connection_opened, _connection_id}, state) do
    # Incrementa o contador de conexões
    {:noreply, %{state | connections: state.connections + 1}}
  end
  
  @impl true
  def handle_cast({:connection_closed, _connection_id}, state) do
    # Decrementa o contador de conexões
    connections = max(0, state.connections - 1)
    {:noreply, %{state | connections: connections}}
  end
  
  @impl true
  def terminate(_reason, _state) do
    Logger.info("Parando servidor WebSocket...", module: __MODULE__)
    :cowboy.stop_listener(:deeperhub_http)
    :ok
  end
  
  # API pública
  
  @doc """
  Obtém estatísticas do servidor WebSocket.
  
  ## Retorno
  
  Um mapa contendo estatísticas do servidor, como:
  
  - `:port` - Porta do servidor
  - `:max_connections` - Número máximo de conexões
  - `:current_connections` - Número atual de conexões
  - `:uptime_seconds` - Tempo de atividade em segundos
  """
  def stats do
    GenServer.call(__MODULE__, :stats)
  end
  
  @doc """
  Notifica o servidor sobre uma nova conexão.
  
  ## Parâmetros
  
  - `connection_id` - ID da conexão
  """
  def connection_opened(connection_id) do
    GenServer.cast(__MODULE__, {:connection_opened, connection_id})
  end
  
  @doc """
  Notifica o servidor sobre o fechamento de uma conexão.
  
  ## Parâmetros
  
  - `connection_id` - ID da conexão
  """
  def connection_closed(connection_id) do
    GenServer.cast(__MODULE__, {:connection_closed, connection_id})
  end
end
