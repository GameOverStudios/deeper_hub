defmodule DeeperHub.Core.Data.Migrations do
  @moduledoc """
  Módulo responsável por gerenciar migrações de banco de dados para o DeeperHub.
  
  Este módulo é responsável por verificar e executar migrações de banco de dados
  automaticamente durante a inicialização da aplicação, garantindo que o esquema
  do banco de dados esteja sempre atualizado.
  
  Ele interage com o DeeperHub.Core.Data.Repo para executar as migrações
  e gerencia o controle de versão das migrações aplicadas.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Inicializa o sistema de migrações e executa todas as migrações pendentes.
  Esta função deve ser chamada durante a inicialização da aplicação.
  
  Retorna `:ok` se todas as migrações foram aplicadas com sucesso ou
  `{:error, reason}` se ocorreu algum erro.
  """
  @spec initialize() :: :ok | {:error, any()}
  def initialize do
    Logger.info("Inicializando sistema de migrações...", module: __MODULE__)
    
    # Aguarda até que o pool de conexões esteja disponível antes de prosseguir
    # Aumenta o número de tentativas e o tempo de espera para garantir que o pool esteja pronto
    max_attempts = 10
    wait_time_ms = 1000
    
    case wait_for_pool(max_attempts, wait_time_ms) do
      :ok ->
        Logger.info("Pool de conexões disponível. Prosseguindo com as migrações.", module: __MODULE__)
        
        # Primeiro, inicializa o banco de dados (garante que o diretório e arquivo existam)
        with :ok <- DeeperHub.Core.Data.Migrations.Initializer.initialize(),
             :ok <- ensure_migrations_table(),
             {:ok, applied_versions} <- get_applied_migrations(),
             {:ok, available_migrations} <- get_available_migrations(),
             pending_migrations = filter_pending_migrations(available_migrations, applied_versions),
             :ok <- apply_migrations(pending_migrations) do
      
          Logger.info("Sistema de migrações inicializado com sucesso.", module: __MODULE__)
          :ok
        else
          {:error, reason} = error ->
            Logger.error("Falha ao inicializar sistema de migrações: #{inspect(reason)}", module: __MODULE__)
            error
        end
      {:error, :pool_not_found} ->
        Logger.error("Pool de conexões não está disponível para executar migrações após #{max_attempts} tentativas", module: __MODULE__)
        {:error, :pool_not_found}
    end
  end
  
  # Função auxiliar para aguardar até que o pool de conexões esteja disponível
  @spec wait_for_pool(integer(), integer()) :: :ok | {:error, :pool_not_found}
  defp wait_for_pool(max_attempts, wait_time_ms) do
    wait_for_pool(1, max_attempts, wait_time_ms)
  end
  
  defp wait_for_pool(attempt, max_attempts, wait_time_ms) do
    Logger.debug("Verificando disponibilidade do pool de conexões (tentativa #{attempt}/#{max_attempts})...", module: __MODULE__)
    
    # Verifica se o processo do pool existe e está registrado
    pool_name = Application.get_env(:deeper_hub, DeeperHub.Core.Data.Repo, [])
                |> Keyword.get(:pool_name, DeeperHub.DBConnectionPool)
    
    pool_pid = Process.whereis(pool_name)
    
    cond do
      # Se o processo existe e está vivo
      is_pid(pool_pid) and Process.alive?(pool_pid) ->
        # Tenta executar uma consulta simples para verificar se o pool está realmente funcional
        try_test_query(pool_name, attempt, max_attempts, wait_time_ms)
      
      # Se o processo não existe ou não está vivo
      true ->
        if attempt < max_attempts do
          Logger.warn("Pool de conexões #{inspect(pool_name)} não encontrado ou não está ativo. Aguardando #{wait_time_ms}ms antes da próxima tentativa...", module: __MODULE__)
          Process.sleep(wait_time_ms)
          wait_for_pool(attempt + 1, max_attempts, wait_time_ms)
        else
          Logger.error("Pool de conexões #{inspect(pool_name)} não encontrado ou não está ativo após #{max_attempts} tentativas.", module: __MODULE__)
          {:error, :pool_not_found}
        end
    end
  end
  
  # Tenta executar uma consulta simples para verificar se o pool está realmente funcional
  defp try_test_query(pool_name, attempt, max_attempts, wait_time_ms) do
    # Em vez de tentar executar uma consulta diretamente com DBConnection.execute,
    # vamos usar o módulo Repo que já está configurado corretamente
    try do
      # Verifica se o processo do pool existe e está ativo
      if Process.alive?(Process.whereis(pool_name)) do
        Logger.info("Pool de conexões #{inspect(pool_name)} está registrado e ativo.", module: __MODULE__)
        
        # Aguarda um curto período para permitir que o pool seja completamente inicializado
        Process.sleep(500)
        
        # Tenta executar uma consulta simples usando o módulo Repo
        case DeeperHub.Core.Data.Repo.query("SELECT 1 AS test;") do
          {:ok, _rows} ->
            Logger.info("Pool de conexões #{inspect(pool_name)} está funcional.", module: __MODULE__)
            :ok
          {:error, error} ->
            Logger.warn("Erro ao executar consulta de teste via Repo: #{inspect(error)}", module: __MODULE__)
            retry_or_fail(attempt, max_attempts, wait_time_ms)
        end
      else
        Logger.warn("Pool de conexões #{inspect(pool_name)} não está ativo.", module: __MODULE__)
        retry_or_fail(attempt, max_attempts, wait_time_ms)
      end
    rescue
      error ->
        Logger.warn("Exceção ao verificar pool de conexões: #{inspect(error)}", module: __MODULE__)
        retry_or_fail(attempt, max_attempts, wait_time_ms)
    end
  end
  
  # Função auxiliar para decidir se deve tentar novamente ou falhar
  defp retry_or_fail(attempt, max_attempts, wait_time_ms) do
    if attempt < max_attempts do
      Logger.warn("Tentando novamente em #{wait_time_ms}ms (tentativa #{attempt}/#{max_attempts})...", module: __MODULE__)
      Process.sleep(wait_time_ms)
      wait_for_pool(attempt + 1, max_attempts, wait_time_ms)
    else
      Logger.error("Falha ao verificar funcionalidade do pool após #{max_attempts} tentativas.", module: __MODULE__)
      {:error, :pool_not_found}
    end
  end

  @doc """
  Garante que a tabela de controle de migrações exista no banco de dados.
  Se a tabela não existir, ela será criada.
  
  Retorna `:ok` se a tabela já existe ou foi criada com sucesso,
  ou `{:error, reason}` se ocorreu algum erro.
  """
  @spec ensure_migrations_table() :: :ok | {:error, any()}
  def ensure_migrations_table do
    sql = """
    CREATE TABLE IF NOT EXISTS schema_migrations (
      version TEXT PRIMARY KEY,
      inserted_at TEXT NOT NULL
    );
    """
    
    case Repo.execute(sql) do
      {:ok, _} -> 
        Logger.debug("Tabela de migrações verificada/criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} -> 
        Logger.error("Falha ao criar tabela de migrações: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Obtém a lista de migrações já aplicadas no banco de dados.
  
  Retorna `{:ok, [version]}` com a lista de versões aplicadas,
  ou `{:error, reason}` se ocorreu algum erro.
  """
  @spec get_applied_migrations() :: {:ok, [String.t()]} | {:error, any()}
  def get_applied_migrations do
    sql = "SELECT version FROM schema_migrations ORDER BY version;"
    
    case Repo.query(sql) do
      {:ok, rows} -> 
        # O Exqlite retorna os resultados como listas, não como mapas
        # Cada linha é uma lista onde o primeiro elemento é o valor da coluna 'version'
        versions = Enum.map(rows, fn [version] -> version end)
        Logger.debug("Migrações aplicadas: #{inspect(versions)}", module: __MODULE__)
        {:ok, versions}
      {:error, reason} -> 
        Logger.error("Falha ao obter migrações aplicadas: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Obtém a lista de migrações disponíveis no sistema.
  
  Retorna `{:ok, [{version, module}]}` com a lista de versões e módulos disponíveis,
  ou `{:error, reason}` se ocorreu algum erro.
  """
  @spec get_available_migrations() :: {:ok, [{String.t(), module()}]} | {:error, any()}
  def get_available_migrations do
    # Lista de migrações disponíveis
    # Cada migração é representada por uma tupla {versão, módulo}
    migrations = [
      {"20250518000001", DeeperHub.Core.Data.Migrations.CreateUsersTable},
      {"20250518000002", DeeperHub.Core.Data.Migrations.CreateMessagesTable},
      {"20250518000003", DeeperHub.Core.Data.Migrations.CreateChannelsTable},
      {"20250519000001", DeeperHub.Core.Data.Migrations.CreateSecurityEventsTable},
      {"20250519000002", DeeperHub.Core.Data.Migrations.CreateRevokedTokensTable},
      {"20250519000003", DeeperHub.Core.Data.Migrations.CreateUserSessionsTable},
      {"20250519000004", DeeperHub.Core.Data.Migrations.CreateEmailVerificationsTable}
    ]
    
    Logger.debug("Migrações disponíveis: #{inspect(migrations)}", module: __MODULE__)
    {:ok, migrations}
  end

  @doc """
  Filtra as migrações pendentes, comparando as migrações disponíveis com as já aplicadas.
  
  Retorna uma lista de tuplas `{version, module}` com as migrações pendentes.
  """
  @spec filter_pending_migrations([{String.t(), module()}], [String.t()]) :: [{String.t(), module()}]
  def filter_pending_migrations(available_migrations, applied_versions) do
    pending = Enum.filter(available_migrations, fn {version, _module} -> 
      not Enum.member?(applied_versions, version)
    end)
    
    Logger.info("Migrações pendentes: #{length(pending)}", module: __MODULE__)
    pending
  end

  @doc """
  Aplica as migrações pendentes em ordem crescente de versão.
  
  Retorna `:ok` se todas as migrações foram aplicadas com sucesso,
  ou `{:error, reason}` se ocorreu algum erro.
  """
  @spec apply_migrations([{String.t(), module()}]) :: :ok | {:error, any()}
  def apply_migrations([]) do
    Logger.info("Nenhuma migração pendente para aplicar.", module: __MODULE__)
    :ok
  end
  
  def apply_migrations(pending_migrations) do
    # Ordena as migrações por versão
    sorted_migrations = Enum.sort_by(pending_migrations, fn {version, _} -> version end)
    
    Enum.reduce_while(sorted_migrations, :ok, fn {version, module}, _acc ->
      Logger.info("Aplicando migração #{version} (#{inspect(module)})...", module: __MODULE__)
      
      result = Repo.transaction(fn _conn ->
        case apply(module, :up, []) do
          :ok ->
            # Registra a migração como aplicada
            timestamp = DateTime.utc_now() |> DateTime.to_iso8601()
            insert_sql = "INSERT INTO schema_migrations (version, inserted_at) VALUES (?, ?);"
            case Repo.execute(insert_sql, [version, timestamp]) do
              {:ok, _} -> :ok
              {:error, reason} -> {:error, reason}
            end
          {:error, _reason} = error -> error
        end
      end)
      
      case result do
        {:ok, :ok} ->
          Logger.info("Migração #{version} aplicada com sucesso.", module: __MODULE__)
          {:cont, :ok}
        {:error, reason} ->
          Logger.error("Falha ao aplicar migração #{version}: #{inspect(reason)}", module: __MODULE__)
          {:halt, {:error, reason}}
      end
    end)
  end
end
