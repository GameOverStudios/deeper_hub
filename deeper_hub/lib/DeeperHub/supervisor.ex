defmodule DeeperHub.Supervisor do
  @moduledoc """
  Supervisor principal da aplicação DeeperHub.

  Este supervisor é responsável por gerenciar os supervisores de cada subsistema
  da aplicação.
  """

  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      # Lista de supervisores de subsistemas
      # Vazia porque os supervisores estão sendo iniciados diretamente no Application
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
