defmodule DeeperHub.Application do
  @moduledoc """
  Módulo de aplicação principal do DeeperHub.

  Este módulo é responsável por iniciar e configurar a aplicação Elixir.
  """

  use Application

  @doc """
  Inicializa a aplicação DeeperHub.
  """
  @impl true
  def start(_type, _args) do
    # Inicia o supervisor principal
    DeeperHub.Application.Supervisor.start_link()
  end
end
