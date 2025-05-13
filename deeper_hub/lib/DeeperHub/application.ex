defmodule DeeperHub.Application do
  @moduledoc """
  Módulo de aplicação principal do DeeperHub.

  Este módulo define a árvore de supervisão e inicia todos os componentes
  necessários para o funcionamento da aplicação.
  """

  use Application

  @impl true
  def start(_type, _args) do
    IO.puts("📝 Inicializando Sistema")
    children = [
      # Supervisores dos módulos Core
      {DeeperHub.Core.Logger.Supervisor, []},
      {DeeperHub.Core.ConfigManager.Supervisor, []},
      {DeeperHub.Core.EventBus.Supervisor, []},
      # Outros supervisores serão adicionados conforme necessário
    ]

    # Estratégia :one_for_one - se um processo filho falhar, apenas ele será reiniciado
    opts = [strategy: :one_for_one, name: DeeperHub.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
