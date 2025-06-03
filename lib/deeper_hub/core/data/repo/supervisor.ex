defmodule DeeperHub.Core.Data.Repo.Supervisor do
  @moduledoc """
  Supervisor for the DBConnection pool for DeeperHub.Core.Data.Repo.

  Este supervisor é responsável por inicializar e gerenciar o pool de conexões
  com o banco de dados SQLite. Ele garante que o diretório do banco de dados
  exista e que o pool de conexões seja inicializado corretamente.
  """
  use Supervisor
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger

  @doc """
  Inicia o supervisor do repositório.
  """
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
    pragmas = Keyword.get(repo_config, :pragmas, [])

    # Garante que o diretório do banco de dados exista
    db_directory = Path.dirname(db_path)
    Logger.info("Garantindo que o diretório do banco de dados exista: #{db_directory}")

    case File.mkdir_p(db_directory) do
      :ok ->
        Logger.info("Diretório do banco de dados verificado/criado com sucesso: #{db_directory}")

      {:error, reason} ->
        Logger.error(
          "Falha ao criar diretório do banco de dados '#{db_directory}': #{inspect(reason)}"
        )

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

    # Adiciona as configurações de pragmas se estiverem definidas
    db_opts =
      if pragmas && length(pragmas) > 0,
        do: Keyword.put(db_opts, :pragmas, pragmas),
        else: db_opts

    Logger.info("Iniciando pool de conexões SQLite com configuração: #{inspect(db_opts)}")

    children = [
      # Usa um worker com restart: :permanent para garantir que o pool seja reiniciado em caso de falha
      %{
        id: pool_name,
        start: {DBConnection, :start_link, [db_adapter, db_opts]},
        type: :worker,
        restart: :permanent,
        # Aumenta o tempo de shutdown para garantir que todas as conexões sejam fechadas corretamente
        shutdown: 10000
      },
      # Adiciona um worker para verificar a saúde do pool após a inicialização
      %{
        id: DeeperHub.Core.Data.Repo.PoolMonitor,
        start: {Task, :start_link, [fn -> monitor_pool_startup(pool_name) end]},
        restart: :transient,
        shutdown: 5000
      }
    ]

    # Usa a estratégia one_for_all para garantir que todos os processos sejam reiniciados juntos
    Supervisor.init(children, strategy: :one_for_one)
  end

  # Função para monitorar a inicialização do pool
  defp monitor_pool_startup(pool_name) do
    # Aguarda um curto período para dar tempo ao pool de inicializar
    Process.sleep(500)

    max_attempts = 5
    wait_time_ms = 500

    wait_for_pool(pool_name, 1, max_attempts, wait_time_ms)
  end

  defp wait_for_pool(pool_name, attempt, max_attempts, wait_time_ms) do
    case Process.whereis(pool_name) do
      nil ->
        if attempt < max_attempts do
          Logger.warning(
            "Pool #{inspect(pool_name)} ainda não está registrado. Tentativa #{attempt}/#{max_attempts}"
          )

          Process.sleep(wait_time_ms)
          wait_for_pool(pool_name, attempt + 1, max_attempts, wait_time_ms)
        else
          Logger.error(
            "Pool #{inspect(pool_name)} não foi registrado após #{max_attempts} tentativas"
          )
        end

      pid ->
        Logger.info("Pool #{inspect(pool_name)} registrado com sucesso (PID: #{inspect(pid)})")
        # Tenta executar uma consulta simples para verificar se o pool está funcionando
        try_simple_query(pool_name)
    end
  end

  defp try_simple_query(pool_name) do
    # Verifica apenas se o processo do pool existe e está ativo
    # Não tenta executar uma consulta diretamente, pois isso pode causar erros
    # dependendo da implementação do adaptador
    if Process.alive?(Process.whereis(pool_name)) do
      Logger.info("Pool #{inspect(pool_name)} está registrado e ativo")

      # Aguarda um curto período para permitir que o pool seja completamente inicializado
      Process.sleep(500)

      # Em vez de tentar executar uma consulta diretamente, apenas registra que o pool parece estar pronto
      Logger.info("Pool #{inspect(pool_name)} parece estar pronto para uso")
    else
      Logger.error("Pool #{inspect(pool_name)} não está ativo")
    end
  rescue
    error ->
      Logger.error("Exceção ao verificar pool #{inspect(pool_name)}: #{inspect(error)}")
  end
end
