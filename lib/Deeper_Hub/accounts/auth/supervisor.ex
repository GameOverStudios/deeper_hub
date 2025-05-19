defmodule DeeperHub.Accounts.Auth.Supervisor do
  @moduledoc """
  Supervisor para o subsistema de autenticação do DeeperHub.
  
  Este módulo é responsável por iniciar e supervisionar os processos
  relacionados à autenticação, como o sistema de autenticação em duas etapas.
  """
  
  use Supervisor
  
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  
  @doc """
  Inicia o supervisor do subsistema de autenticação.
  """
  def start_link(opts \\ []) do
    Logger.info("Iniciando supervisor do subsistema de autenticação...", module: __MODULE__)
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @impl true
  def init(_opts) do
    Logger.info("Inicializando subsistema de autenticação...", module: __MODULE__)
    
    # Define os processos filhos a serem supervisionados
    children = [
      # Adicione aqui outros processos relacionados à autenticação, se necessário
    ]
    
    # Inicializa o sistema de autenticação em duas etapas
    # Isso não é um processo GenServer, então não é supervisionado diretamente
    # Mas precisamos garantir que seja inicializado
    case DeeperHub.Accounts.Auth.TwoFactor.init() do
      :ok ->
        Logger.info("Sistema de autenticação em duas etapas inicializado com sucesso.", module: __MODULE__)
        
      {:error, reason} ->
        Logger.error("Falha ao inicializar sistema de autenticação em duas etapas: #{inspect(reason)}", 
          module: __MODULE__
        )
    end
    
    # Configuração do supervisor
    opts = [strategy: :one_for_one]
    
    # Inicia o supervisor
    Supervisor.init(children, opts)
  end
end
