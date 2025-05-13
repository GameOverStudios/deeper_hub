defmodule DeeperHub.Core.EventBus.Supervisor do
  @moduledoc """
  Supervisor para os processos relacionados ao EventBus.

  Este supervisor é responsável por iniciar e gerenciar o ciclo de vida
  dos processos do módulo EventBus.
  """

  use Supervisor
  alias DeeperHub.Core.Logger

  def start_link(init_arg) do
    Logger.info("Iniciando EventBus", %{module: __MODULE__})
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    Logger.debug("Configurando processos filhos do EventBus", %{})

    children = [
      # Inicia o servidor GenServer do EventBus
      {DeeperHub.Core.EventBus.Server, []}
    ]

    Logger.debug("Inicializando supervisor do EventBus", %{strategy: :one_for_one})
    Supervisor.init(children, strategy: :one_for_one)
  end
end
