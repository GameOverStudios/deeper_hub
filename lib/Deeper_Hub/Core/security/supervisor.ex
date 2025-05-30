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
    # Verificamos se o supervisor já está em execução para evitar duplicações
    case Process.whereis(__MODULE__) do
      nil -> Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
      pid when is_pid(pid) -> {:ok, pid}
    end
  end

  @doc """
  Inicializa o supervisor com os processos filhos.
  """
  @impl true
  def init(_init_arg) do
    Logger.info("Iniciando supervisor do subsistema de segurança...", module: __MODULE__)

    # Define os processos filhos de forma otimizada para evitar inicializações redundantes
    children = [
      # Uma única task para inicializar todo o subsistema de segurança
      # O DeeperHub.Core.Security.init() já chama DeeperHub.Core.Security.AuthAttack.init()
      # Então não precisamos de uma task separada para isso
      %{
        id: :security_init_task,
        start: {Task, :start_link, [fn -> DeeperHub.Core.Security.init() end]},
        restart: :temporary
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
