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
      {"20250518000003", DeeperHub.Core.Data.Migrations.CreateChannelsTable}
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
