# lib/deeper_hub/application.ex
defmodule DeeperHub.Application do
  @moduledoc """
  O callback da aplicação para o DeeperHub.
  Este módulo é responsável por iniciar e supervisionar os processos
  principais da aplicação.
  """
  use Application

  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Config.SystemConfig

  @impl true
  def start(_type, _args) do
    DeeperHub.Core.Logger.info("Iniciando o sistema DeeperHub...")

    # Aplica configurações do sistema antes de inicializar qualquer serviço
    :ok = SystemConfig.apply_system_config()

    # Valida configurações
    case SystemConfig.validate_config() do
      :ok ->
        DeeperHub.Core.Logger.info("Configurações validadas com sucesso")

        # Inicializa apenas o repositório
        init_repo_result = init_repository()

        case init_repo_result do
          {:ok, _repo_pid} ->
            DeeperHub.Core.Logger.info("Repositório inicializado. Executando migrações...")

            # Executar migrações de forma síncrona antes de iniciar outros serviços
            case DeeperHub.Core.Data.Migrations.initialize() do
              :ok ->
                DeeperHub.Core.Logger.info("Migrações aplicadas com sucesso. Inicializando demais serviços.")
                
                # Sistema inicializado com sucesso
                DeeperHub.Core.Logger.info("Sistema DeeperHub completamente inicializado.")
                {:ok, self()}

              {:error, reason} ->
                DeeperHub.Core.Logger.error("Falha ao inicializar migrações: #{inspect(reason)}")
                {:error, reason}
            end

          {:error, reason} ->
            DeeperHub.Core.Logger.error("Falha ao inicializar repositório: #{inspect(reason)}")
            {:error, reason}
        end

      {:error, missing} ->
        DeeperHub.Core.Logger.error("Configurações inválidas: #{inspect(missing)}")
        {:error, {:invalid_config, missing}}
    end
  end

  # Inicializa apenas o repositório para garantir que o banco de dados esteja disponível
  defp init_repository do
    repo_children = [
      # Inicia o supervisor do repositório para gerenciar o pool de conexões do banco de dados
      {DeeperHub.Core.Data.Repo.Supervisor, []}
    ]

    # Configuração do supervisor do repositório
    opts = [strategy: :one_for_one, name: DeeperHub.RepoSupervisor]
    Supervisor.start_link(repo_children, opts)
  end
end
