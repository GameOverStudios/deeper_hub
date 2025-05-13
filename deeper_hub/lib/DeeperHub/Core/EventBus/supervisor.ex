defmodule DeeperHub.Core.EventBus.Supervisor do
  @moduledoc """
  Supervisor para os processos relacionados ao EventBus.

  Este supervisor é responsável por iniciar e gerenciar o ciclo de vida
  dos processos do módulo EventBus.
  """

  use Supervisor

  def start_link(init_arg) do
    IO.puts(" ⚙️  Iniciando EventBus")
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      # Inicia o servidor GenServer do EventBus
      {DeeperHub.Core.EventBus.Server, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
