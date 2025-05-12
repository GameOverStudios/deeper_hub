defmodule DeeperHub.Application.Supervisor do
  @moduledoc """
  Supervisor principal da aplicação DeeperHub.

  Este módulo é responsável por iniciar e supervisionar todos os processos
  principais da aplicação.
  """

  use Supervisor

  @doc """
  Inicia o supervisor da aplicação.
  """
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Core Supervisor - gerencia os componentes principais
      {DeeperHub.Core.ConfigManager.Supervisor, []},
      {DeeperHub.Core.EventBus.Supervisor, []},

      # Aqui adicionaremos outros supervisores à medida que implementarmos mais módulos:
      # {DeeperHub.Core.Logger.Supervisor, []},
      # {DeeperHub.Core.Repo, []},
      # {DeeperHub.Core.Cache.Supervisor, []},
      # etc.
    ]

    # :one_for_one - Se um processo morrer, apenas ele é reiniciado
    Supervisor.init(children, strategy: :one_for_one)
  end
end
