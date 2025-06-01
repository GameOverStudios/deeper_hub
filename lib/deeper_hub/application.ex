# lib/deeper_hub/application.ex
defmodule DeeperHub.Application do
  @moduledoc """
  O callback da aplicação para o DeeperHub.
  Este módulo é responsável por iniciar e supervisionar os processos
  principais da aplicação.
  """
  use Application

  # alias DeeperHub.Core.Logger # Removido para depuração
  require DeeperHub.Core.Logger

  @impl true
  def start(_type, _args) do
    DeeperHub.Core.Logger.info("Iniciando o sistema DeeperHub...")

    # Inicializa primeiro apenas o repositório para garantir que o banco de dados esteja disponível
    # antes de qualquer outra operação
    init_repo_result = init_repository()

    case init_repo_result do
      {:ok, _repo_pid} ->
        DeeperHub.Core.Logger.info("Repositório inicializado. Executando migrações...")

        # Executar migrações de forma síncrona antes de iniciar outros serviços
        case DeeperHub.Core.Data.Migrations.initialize() do
          :ok ->
            DeeperHub.Core.Logger.info(
              "Migrações aplicadas com sucesso. Inicializando demais serviços."
            )

            init_main_supervisors()

          {:error, reason} ->
            DeeperHub.Core.Logger.error("Falha ao inicializar migrações: #{inspect(reason)}")
            {:error, reason}
        end

      {:error, reason} ->
        DeeperHub.Core.Logger.error("Falha ao inicializar repositório: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Inicializa apenas o repositório para garantir que o banco de dados esteja disponível
  defp init_repository do
    repo_children = [
      # Inicia o supervisor do repositório para gerenciar o pool de conexões do banco de dados
      {DeeperHub.Core.Data.Repo.Supervisor, []},
      {Plug.Cowboy, scheme: :http, plug: DeeperHub.WebInterface.Router, options: [port: 4000]}
    ]

    # Configuração do supervisor do repositório
    opts = [strategy: :one_for_one, name: DeeperHub.RepoSupervisor]
    Supervisor.start_link(repo_children, opts)
  end

  # Inicializa o restante dos supervisores após as migrações serem aplicadas com sucesso
  defp init_main_supervisors do
    # Define a árvore de supervisão principal da aplicação
    children = [
      # Inicia o gerenciador de sessões de terminal
      {DeeperHub.Core.Terminal.SessionManager, []},
      # Inicia o gerenciador de console
      {DeeperHub.Core.Console.ConsoleManager, []}
    ]

    # Configuração do supervisor principal
    # Obtém configurações de resiliência do ambiente
    supervisor_config = Application.get_env(:deeper_hub, :supervisor, [])

    # Define opções do supervisor com valores padrão caso não estejam configurados
    opts = [
      strategy: Keyword.get(supervisor_config, :strategy, :one_for_one),
      name: DeeperHub.Supervisor,
      max_restarts: Keyword.get(supervisor_config, :max_restarts, 3),
      max_seconds: Keyword.get(supervisor_config, :max_seconds, 5)
    ]

    # Inicia o supervisor principal
    result = Supervisor.start_link(children, opts)

    # Processa o resultado da inicialização do supervisor
    case result do
      {:ok, pid} ->
        DeeperHub.Core.Logger.info("Supervisor principal iniciado com sucesso.")
        DeeperHub.Core.Logger.info("Sistema DeeperHub completamente inicializado.")
        {:ok, pid}

      {:error, reason} ->
        DeeperHub.Core.Logger.error("Falha ao iniciar o sistema DeeperHub: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
