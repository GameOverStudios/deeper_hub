defmodule DeeperHub.Core.ConfigManager.Supervisor do
  @moduledoc """
  Supervisor para os processos do DeeperHub.Core.ConfigManager.

  Este supervisor é responsável por iniciar e monitorar todos os processos
  relacionados ao ConfigManager.
  """

  use Supervisor

  @doc """
  Inicia o supervisor do ConfigManager.
  """
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # O servidor principal do ConfigManager
      DeeperHub.Core.ConfigManager.Server

      # Aqui poderíamos adicionar outros processos relacionados, como:
      # - Um worker para fazer cache das configurações
      # - Um processo para persistir configurações em um banco de dados
      # - Um scheduler para recarregar configurações periodicamente
    ]

    # :one_for_one - Se um processo morrer, apenas ele é reiniciado
    # Isso é mais apropriado já que o EventBus é gerenciado separadamente
    Supervisor.init(children, strategy: :one_for_one)
  end
end
