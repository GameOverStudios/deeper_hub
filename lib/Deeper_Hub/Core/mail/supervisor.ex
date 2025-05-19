defmodule DeeperHub.Core.Mail.Supervisor do
  @moduledoc """
  Supervisor para o subsistema de email do DeeperHub.
  
  Este supervisor gerencia os componentes relacionados ao envio de emails,
  garantindo que sejam inicializados corretamente e supervisionados
  para tolerância a falhas.
  """
  
  use Supervisor
  
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  
  @doc """
  Inicia o supervisor de email.
  """
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end
  
  @doc """
  Inicializa o supervisor com os processos filhos.
  """
  @impl true
  def init(_init_arg) do
    Logger.info("Iniciando supervisor do subsistema de email...", module: __MODULE__)
    
    # Define os processos filhos
    children = [
      # Processo para gerenciamento da fila de emails
      DeeperHub.Core.Mail.Queue
    ]
    
    # Estratégia de supervisão
    Supervisor.init(children, strategy: :one_for_one)
  end
end
