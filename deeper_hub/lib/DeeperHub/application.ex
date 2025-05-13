defmodule DeeperHub.Application do
  @moduledoc """
  Módulo de aplicação principal do DeeperHub.

  Este módulo define a árvore de supervisão e inicia todos os componentes
  necessários para o funcionamento da aplicação.
  """

  use Application
  require Logger # Usamos o Logger padrão do Elixir aqui já que nosso Logger ainda não foi inicializado

  @impl true
  def start(_type, _args) do
    Logger.info("Inicializando Sistema DeeperHub")

    # Definimos a lista de supervisores em ordem de inicialização
    children = [
      # Inicia o supervisor do Logger primeiro para garantir que os logs estejam disponíveis
      DeeperHub.Core.Logger.Supervisor,

      # Inicia outros supervisores
      DeeperHub.Core.ConfigManager.Supervisor,
      DeeperHub.Core.EventBus.Supervisor

      # Outros módulos do sistema...
    ]

    # Ver https://hexdocs.pm/elixir/Supervisor.html
    # para outras estratégias e opções de supervisão
    opts = [strategy: :one_for_one, name: DeeperHub.Supervisor]

    # Iniciar supervisor
    result = Supervisor.start_link(children, opts)

    Logger.info("Todos os supervisores iniciados")
    result
  end
end
