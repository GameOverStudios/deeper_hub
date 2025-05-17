defmodule Deeper_Hub.Core.WebSockets.WebSocketListener do
  @moduledoc """
  Listener para o servidor WebSocket.
  
  Este módulo é responsável por iniciar e gerenciar o listener WebSocket,
  que aceita conexões e inicia o protocolo WebSocket para cada conexão.
  """
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.WebSockets.WebSocketProtocol
  alias Deeper_Hub.Core.EventBus
  
  # Nome da tabela ETS para armazenar as conexões ativas
  @connections_table :websocket_connections
  
  @doc """
  Retorna a especificação do processo filho para o supervisor.
  
  ## Parâmetros
  
    - `opts`: Opções para o listener
  
  ## Retorno
  
    - Especificação do processo filho
  """
  def child_spec(opts) do
    # Obtém as opções de configuração
    port = Keyword.get(opts, :port, 8080)
    max_connections = Keyword.get(opts, :max_connections, 1000)
    
    # Constrói as opções do transporte
    transport_opts = %{
      socket_opts: [
        port: port
      ],
      max_connections: max_connections
    }
    
    # Cria a especificação do processo filho para o Ranch
    %{
      id: __MODULE__,
      start: {:ranch_listener_sup, :start_link, [
        __MODULE__,           # Nome do listener
        :ranch_tcp,           # Módulo de transporte
        transport_opts,       # Opções do transporte
        WebSocketProtocol,    # Módulo de protocolo
        []                    # Opções do protocolo
      ]},
      type: :supervisor,
      shutdown: :infinity,
      restart: :permanent
    }
  end
  
  @doc """
  Inicia o listener WebSocket.
  
  ## Parâmetros
  
    - `opts`: Opções para o listener
  
  ## Opções
  
    - `:port` - Porta para o servidor (padrão: 8080)
    - `:max_connections` - Número máximo de conexões (padrão: 1000)
  
  ## Retorno
  
    - `{:ok, pid}` - Se o listener for iniciado com sucesso
    - `{:error, reason}` - Em caso de falha
  """
  # Cria a tabela ETS para armazenar as conexões ativas.
  # Esta função deve ser chamada antes de iniciar o listener.
  def create_connections_table do
    # Verifica se a tabela já existe
    case :ets.info(@connections_table) do
      :undefined ->
        # Cria a tabela ETS para armazenar as conexões ativas
        :ets.new(@connections_table, [:set, :public, :named_table])
        Logger.info("Tabela de conexões WebSocket criada", %{module: __MODULE__})
      _ ->
        Logger.debug("Tabela de conexões WebSocket já existe", %{module: __MODULE__})
    end
  end
  
  def start_link(opts \\ []) do
    # Garante que a tabela ETS existe
    create_connections_table()
    
    # Obtém as opções de configuração
    port = Keyword.get(opts, :port, 8080)
    max_connections = Keyword.get(opts, :max_connections, 1000)
    
    # Constrói as opções do transporte
    transport_opts = %{
      socket_opts: [
        port: port
      ],
      max_connections: max_connections
    }
    
    # Inicia o listener
    case :ranch.start_listener(
      __MODULE__,           # Nome do listener
      :ranch_tcp,           # Módulo de transporte
      transport_opts,       # Opções do transporte
      WebSocketProtocol,    # Módulo de protocolo
      []                    # Opções do protocolo
    ) do
      {:ok, _pid} = result ->
        Logger.info("Servidor WebSocket iniciado", %{
          module: __MODULE__,
          port: port,
          max_connections: max_connections
        })
        result
        
      error ->
        Logger.error("Falha ao iniciar servidor WebSocket", %{
          module: __MODULE__,
          error: error
        })
        error
    end
  end
  
  @doc """
  Para o listener WebSocket.
  
  ## Retorno
  
    - `:ok` - Se o listener for parado com sucesso
    - `{:error, reason}` - Em caso de falha
  """
  def stop do
    Logger.info("Parando servidor WebSocket", %{module: __MODULE__})
    :ranch.stop_listener(__MODULE__)
  end
  
  @doc """
  Envia uma mensagem para todos os clientes conectados.
  
  ## Parâmetros
  
    - `message`: A mensagem a ser enviada (será codificada como JSON)
  
  ## Retorno
  
    - `:ok` - Se a mensagem for enviada com sucesso
  """
  def broadcast(message) do
    # Registra a intenção de broadcast
    Logger.info("Broadcast de mensagem", %{
      module: __MODULE__,
      message: message
    })
    
    # Converte a mensagem para JSON
    json_message = Jason.encode!(message)
    
    # Obtém todas as conexões ativas
    connections = :ets.tab2list(@connections_table)
    
    # Envia a mensagem para cada conexão
    Enum.each(connections, fn {client_id, {socket, transport}} ->
      # Envia a mensagem para o cliente
      case WebSocketProtocol.send_text(socket, transport, json_message) do
        :ok ->
          # Publica evento de mensagem enviada
          EventBus.publish(:websocket_message_sent, %{
            client: client_id,
            message: message
          })
          
        {:error, reason} ->
          # Registra o erro
          Logger.error("Erro ao enviar mensagem para cliente", %{
            module: __MODULE__,
            client: client_id,
            reason: reason
          })
          
          # Publica evento de erro
          EventBus.publish(:websocket_error, %{
            client: client_id,
            error: reason
          })
      end
    end)
    
    :ok
  end
  
  @doc """
  Envia uma mensagem para um cliente específico.
  
  ## Parâmetros
  
    - `client_id`: O ID do cliente
    - `message`: A mensagem a ser enviada (será codificada como JSON)
  
  ## Retorno
  
    - `:ok` - Se a mensagem for enviada com sucesso
    - `{:error, :not_found}` - Se o cliente não for encontrado
    - `{:error, reason}` - Se ocorrer um erro ao enviar a mensagem
  """
  def send_to_client(client_id, message) do
    # Registra a intenção de enviar mensagem
    Logger.info("Enviando mensagem para cliente", %{
      module: __MODULE__,
      client: client_id,
      message: message
    })
    
    # Converte a mensagem para JSON
    json_message = Jason.encode!(message)
    
    # Busca a conexão do cliente
    case :ets.lookup(@connections_table, client_id) do
      [{^client_id, {socket, transport}}] ->
        # Envia a mensagem para o cliente
        case WebSocketProtocol.send_text(socket, transport, json_message) do
          :ok ->
            # Publica evento de mensagem enviada
            EventBus.publish(:websocket_message_sent, %{
              client: client_id,
              message: message
            })
            
            :ok
            
          {:error, reason} = error ->
            # Registra o erro
            Logger.error("Erro ao enviar mensagem para cliente", %{
              module: __MODULE__,
              client: client_id,
              reason: reason
            })
            
            # Publica evento de erro
            EventBus.publish(:websocket_error, %{
              client: client_id,
              error: reason
            })
            
            error
        end
        
      [] ->
        # Cliente não encontrado
        Logger.warning("Cliente não encontrado", %{
          module: __MODULE__,
          client: client_id
        })
        
        {:error, :not_found}
    end
  end
  
  @doc """
  Registra uma conexão ativa.
  
  ## Parâmetros
  
    - `client_id`: O ID do cliente
    - `socket`: O socket da conexão
    - `transport`: O módulo de transporte
  
  ## Retorno
  
    - `:ok` - Se a conexão for registrada com sucesso
  """
  def register_connection(client_id, socket, transport) do
    # Registra a conexão na tabela ETS
    :ets.insert(@connections_table, {client_id, {socket, transport}})
    
    # Registra a conexão no log
    Logger.info("Cliente conectado", %{
      module: __MODULE__,
      client: client_id
    })
    
    # Publica evento de conexão
    EventBus.publish(:websocket_connected, %{
      client: client_id
    })
    
    :ok
  end
  
  @doc """
  Remove uma conexão ativa.
  
  ## Parâmetros
  
    - `client_id`: O ID do cliente
    - `reason`: O motivo da desconexão
  
  ## Retorno
  
    - `:ok` - Se a conexão for removida com sucesso
  """
  def unregister_connection(client_id, reason) do
    # Remove a conexão da tabela ETS
    :ets.delete(@connections_table, client_id)
    
    # Registra a desconexão no log
    Logger.info("Cliente desconectado", %{
      module: __MODULE__,
      client: client_id,
      reason: reason
    })
    
    # Publica evento de desconexão
    EventBus.publish(:websocket_disconnected, %{
      client: client_id,
      reason: reason
    })
    
    :ok
  end
  
  @doc """
  Obtém todas as conexões ativas.
  
  ## Retorno
  
    - `[{client_id, {socket, transport}}]` - Lista de conexões ativas
  """
  def get_connections do
    :ets.tab2list(@connections_table)
  end
  
  @doc """
  Obtém o número de conexões ativas.
  
  ## Retorno
  
    - `integer` - Número de conexões ativas
  """
  def count_connections do
    :ets.info(@connections_table, :size)
  end
end
