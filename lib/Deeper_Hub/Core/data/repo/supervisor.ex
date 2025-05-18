defmodule DeeperHub.Core.Data.Repo.Supervisor do
  @moduledoc """
  Supervisor for the DBConnection pool for DeeperHub.Core.Data.Repo.
  """
  use Supervisor
  require DeeperHub.Core.Logger # Assuming Logger is still at DeeperHub.Core.Logger

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    # Busca a configuração do repositório
    repo_config = Application.get_env(:deeper_hub, DeeperHub.Core.Data.Repo, [])

    # Obtém os parâmetros de configuração
    db_adapter = Keyword.get(repo_config, :adapter, Exqlite.Connection)
    db_path = Keyword.get(repo_config, :database, "databases/deeper_hub_dev.db")
    pool_name = Keyword.get(repo_config, :pool_name, DeeperHub.DBConnectionPool)
    pool_size = Keyword.get(repo_config, :pool_size, 5)
    
    # Obtém outras opções de configuração
    journal_mode = Keyword.get(repo_config, :journal_mode, :wal)
    busy_timeout = Keyword.get(repo_config, :busy_timeout, 5000)
    show_sensitive_data = Keyword.get(repo_config, :show_sensitive_data_on_connection_error, true)
    timeout = Keyword.get(repo_config, :timeout, 15_000)
    idle_interval = Keyword.get(repo_config, :idle_interval, 15_000)

    # Garante que o diretório do banco de dados exista
    db_directory = Path.dirname(db_path)
    DeeperHub.Core.Logger.info("Garantindo que o diretório do banco de dados exista: #{db_directory}")
    
    case File.mkdir_p(db_directory) do
      :ok ->
        DeeperHub.Core.Logger.info("Diretório do banco de dados verificado/criado com sucesso: #{db_directory}")
      {:error, reason} ->
        DeeperHub.Core.Logger.error("Falha ao criar diretório do banco de dados '#{db_directory}': #{inspect(reason)}")
        raise "Falha ao criar diretório do banco de dados: #{inspect(reason)}"
    end
    
    # Configuração completa para o adaptador SQLite
    db_opts = [
      name: pool_name,
      database: db_path,
      pool_size: pool_size,
      journal_mode: journal_mode,
      busy_timeout: busy_timeout,
      show_sensitive_data_on_connection_error: show_sensitive_data,
      timeout: timeout,
      idle_interval: idle_interval
    ]
    
    DeeperHub.Core.Logger.info("Iniciando pool de conexões SQLite com configuração: #{inspect(db_opts)}")
    
    children = [
      %{
        id: pool_name, 
        start: {DBConnection, :start_link, [db_adapter, db_opts]},
        type: :worker, 
        restart: :permanent,
        shutdown: 5000
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
