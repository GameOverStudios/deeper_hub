defmodule DeeperHub.Core.ConfigManager.Supervisor do
  @moduledoc """
  Supervisor para os processos relacionados ao ConfigManager.

  Este supervisor é responsável por iniciar e gerenciar o ciclo de vida
  dos processos do módulo ConfigManager.
  """

  use Supervisor

  def start_link(init_arg) do
    IO.puts(" ⚙️  Iniciando ConfigManager")
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      # Inicia o servidor GenServer do ConfigManager
      {DeeperHub.Core.ConfigManager.Server, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
