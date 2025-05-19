defmodule DeeperHub.Core.HTTP.Supervisor do
  @moduledoc """
  Supervisor para o subsistema HTTP do DeeperHub.
  
  Este supervisor gerencia os componentes HTTP da aplicação,
  incluindo o servidor HTTP e os endpoints.
  """
  
  use Supervisor
  
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  
  @doc """
  Inicia o supervisor HTTP.
  """
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end
  
  @doc """
  Inicializa o supervisor com os processos filhos.
  """
  @impl true
  def init(_init_arg) do
    Logger.info("Iniciando supervisor do subsistema HTTP...", module: __MODULE__)
    
    # Obtém a porta do ambiente ou usa o valor padrão
    port = Application.get_env(:deeper_hub, :network, [])[:port] || 8080
    
    # Define os processos filhos
    children = [
      # Servidor HTTP usando Plug.Cowboy
      {Plug.Cowboy, 
        scheme: :http, 
        plug: DeeperHub.Core.HTTP.Endpoint, 
        options: [
          port: port,
          transport_options: [
            num_acceptors: 10,
            max_connections: 1000
          ]
        ]
      }
    ]
    
    Logger.info("Servidor HTTP iniciado na porta #{port}", module: __MODULE__)
    
    # Estratégia de supervisão
    Supervisor.init(children, strategy: :one_for_one)
  end
end
