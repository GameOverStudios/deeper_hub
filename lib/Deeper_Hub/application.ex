defmodule DeeperHub.Application do
  @moduledoc """
  Módulo de aplicação principal para o DeeperHub.
  Responsável por gerenciar a inicialização e supervisão dos processos da aplicação.
  """
  use Application

  @impl true
  def start(_type, _args) do
    # Inicializa o banco de dados Mnesia
    :ok = Deeper_Hub.Core.Data.Database.init()

    children = [
      # Adicione aqui os supervisores e processos iniciais da aplicação
      {Deeper_Hub.Core.Data.Cache, []}
    ]

    opts = [strategy: :one_for_one, name: DeeperHub.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
