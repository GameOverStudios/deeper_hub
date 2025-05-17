defmodule Deeper_Hub.Core.WebSockets.Supervisor do
  @moduledoc """
  Supervisor para o servidor WebSocket.
  
  Este supervisor é responsável por iniciar e supervisionar o servidor WebSocket,
  garantindo que ele seja reiniciado em caso de falha.
  """
  
  use Supervisor
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.WebSockets.WebSocketListener
  
  @doc """
  Inicia o supervisor.
  
  ## Parâmetros
  
    - `opts`: Opções para o supervisor
  
  ## Retorno
  
    - `{:ok, pid}` se o supervisor for iniciado com sucesso
    - `{:error, reason}` em caso de falha
  """
  def start_link(opts \\ []) do
    Logger.info("Iniciando supervisor do WebSocket", %{module: __MODULE__})
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Inicializa o supervisor com os componentes necessários.
  
  ## Parâmetros
  
    - `opts`: Opções para o supervisor
  
  ## Retorno
  
    - `{:ok, {supervisor_opts, children}}` com as opções do supervisor e os filhos
  """
  @impl true
  def init(opts) do
    Logger.debug("Inicializando componentes do WebSocket", %{module: __MODULE__})
    
    # Obtém a porta do servidor WebSocket das opções ou usa o padrão
    port = Keyword.get(opts, :port, 8080)
    
    # Cria a tabela ETS para conexões WebSocket
    WebSocketListener.create_connections_table()
    
    # Define os processos filhos
    children = [
      # Inicia o listener WebSocket
      {WebSocketListener, [port: port]}
    ]
    
    # Configura o supervisor para reiniciar os filhos individualmente
    Supervisor.init(children, strategy: :one_for_one)
  end
end
