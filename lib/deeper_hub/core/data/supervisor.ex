defmodule DeeperHub.Core.Data.Migrations.Supervisor do
  @moduledoc """
  Supervisor responsável por inicializar e gerenciar o sistema de migrações.

  Este supervisor é iniciado durante a inicialização da aplicação e garante
  que todas as migrações pendentes sejam executadas antes que o restante
  da aplicação comece a funcionar.
  """

  use Supervisor
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Inicia o supervisor de migrações.
  """
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    Logger.info("Iniciando supervisor de migrações...", module: __MODULE__)

    # Executa as migrações antes de iniciar os filhos
    case DeeperHub.Core.Data.Migrations.initialize() do
      :ok ->
        Logger.info("Migrações executadas com sucesso.", module: __MODULE__)
        # Não há filhos para supervisionar, as migrações são executadas apenas uma vez
        children = []
        Supervisor.init(children, strategy: :one_for_one)

      {:error, reason} ->
        Logger.error("Falha ao executar migrações: #{inspect(reason)}", module: __MODULE__)
        # Retorna {:error, reason} para falhar a inicialização do supervisor
        # e consequentemente da aplicação, já que as migrações são essenciais
        {:error, reason}
    end
  end
end
