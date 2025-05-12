defmodule DeeperHub.Core.EventBus.Supervisor do
  @moduledoc """
  Supervisor para os processos do DeeperHub.Core.EventBus.

  Este supervisor é responsável por iniciar e monitorar todos os processos
  relacionados ao EventBus.
  """

  use Supervisor

  @doc """
  Inicia o supervisor do EventBus.
  """
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # O servidor principal do EventBus
      DeeperHub.Core.EventBus.Server

      # Aqui poderíamos adicionar outros processos relacionados, como:
      # - Um worker para processar eventos pendentes
      # - Um processo para limpar eventos antigos
      # - Um scheduler para tentar reenviar eventos que falharam
    ]

    # :one_for_one - Se um processo morrer, apenas ele é reiniciado
    Supervisor.init(children, strategy: :one_for_one)
  end
end
