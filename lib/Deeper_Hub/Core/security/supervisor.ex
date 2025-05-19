defmodule DeeperHub.Core.Security.Supervisor do
  @moduledoc """
  Supervisor para o subsistema de segurança do DeeperHub.
  
  Este supervisor gerencia os componentes de segurança da aplicação,
  incluindo proteção contra ataques, autenticação, autorização,
  detecção de anomalias, sistema de reputação de IPs e alertas de segurança.
  """
  
  use Supervisor
  
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  
  @doc """
  Inicia o supervisor de segurança.
  """
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end
  
  @doc """
  Inicializa o supervisor com os processos filhos.
  """
  @impl true
  def init(_init_arg) do
    Logger.info("Iniciando supervisor do subsistema de segurança...", module: __MODULE__)
    
    # Define os processos filhos
    children = [
      # Inicializa o subsistema de segurança principal
      %{
        id: :security_init_task,
        start: {Task, :start_link, [fn -> DeeperHub.Core.Security.init() end]}
      },
      
      # Inicializa o módulo de proteção contra ataques de autenticação
      %{
        id: :auth_attack_init_task,
        start: {Task, :start_link, [fn -> DeeperHub.Core.Security.AuthAttack.init() end]}
      },
      
      # Inicia o detector de anomalias
      DeeperHub.Core.Security.AnomalyDetector,
      
      # Inicia o sistema de reputação de IPs
      DeeperHub.Core.Security.IPReputation,
      
      # Inicia o sistema de alertas
      DeeperHub.Core.Security.AlertSystem
    ]
    
    # Estratégia de supervisão
    Supervisor.init(children, strategy: :one_for_one)
  end
end
