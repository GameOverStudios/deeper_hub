defmodule DeeperHub.Core.Data.Migrations.Initializer do
  @moduledoc """
  Módulo responsável por inicializar o banco de dados antes da execução das migrações.

  Este módulo garante que o diretório do banco de dados exista e que o arquivo do banco
  seja criado corretamente antes de executar qualquer migração.
  """

  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Inicializa o banco de dados, garantindo que o diretório exista e que o arquivo
  do banco seja criado corretamente.

  Retorna `:ok` se a inicialização foi bem-sucedida ou `{:error, reason}` se ocorreu algum erro.
  """
  @spec initialize() :: :ok | {:error, any()}
  def initialize do
    Logger.info("Inicializando banco de dados...", module: __MODULE__)

    # Obtém o caminho do banco de dados da configuração
    db_config = Application.get_env(:deeper_hub, DeeperHub.Core.Data.Repo, [])
    db_path = Keyword.get(db_config, :database, "databases/deeper_hub_dev.db")

    # Garante que o diretório do banco de dados exista
    with :ok <- ensure_db_directory(db_path),
         :ok <- ensure_db_file(db_path) do
      Logger.info("Banco de dados inicializado com sucesso em: #{db_path}", module: __MODULE__)
      :ok
    else
      {:error, reason} = error ->
        Logger.error("Falha ao inicializar banco de dados: #{inspect(reason)}",
          module: __MODULE__
        )

        error
    end
  end

  @doc """
  Garante que o diretório do banco de dados exista.
  Se o diretório não existir, tenta criá-lo.

  Retorna `:ok` se o diretório já existe ou foi criado com sucesso,
  ou `{:error, reason}` se ocorreu algum erro.
  """
  @spec ensure_db_directory(String.t()) :: :ok | {:error, any()}
  def ensure_db_directory(db_path) do
    db_dir = Path.dirname(db_path)

    Logger.debug("Verificando diretório do banco de dados: #{db_dir}", module: __MODULE__)

    case File.dir?(db_dir) do
      true ->
        Logger.debug("Diretório do banco de dados já existe: #{db_dir}", module: __MODULE__)
        :ok

      false ->
        Logger.info("Criando diretório do banco de dados: #{db_dir}", module: __MODULE__)

        case File.mkdir_p(db_dir) do
          :ok ->
            Logger.info("Diretório do banco de dados criado com sucesso: #{db_dir}",
              module: __MODULE__
            )

            :ok

          {:error, reason} = error ->
            Logger.error("Falha ao criar diretório do banco de dados: #{inspect(reason)}",
              module: __MODULE__
            )

            error
        end
    end
  end

  @doc """
  Garante que o arquivo do banco de dados exista.
  Se o arquivo não existir, tenta criá-lo.

  Retorna `:ok` se o arquivo já existe ou foi criado com sucesso,
  ou `{:error, reason}` se ocorreu algum erro.
  """
  @spec ensure_db_file(String.t()) :: :ok | {:error, any()}
  def ensure_db_file(db_path) do
    Logger.debug("Verificando arquivo do banco de dados: #{db_path}", module: __MODULE__)

    case File.exists?(db_path) do
      true ->
        Logger.debug("Arquivo do banco de dados já existe: #{db_path}", module: __MODULE__)
        :ok

      false ->
        Logger.info(
          "Arquivo do banco de dados não encontrado. Será criado e otimizado automaticamente.",
          module: __MODULE__
        )

        # Garantir que o diretório exista
        db_dir = Path.dirname(db_path)
        File.mkdir_p!(db_dir)

        # Criar o banco de dados com configurações otimizadas
        create_optimized_db(db_path)
    end
  end

  @doc """
  Cria um banco de dados SQLite otimizado com os pragmas recomendados para máximo desempenho.
  
  Aplica as seguintes otimizações:
  - journal_mode = WAL (Write-Ahead Logging para melhor concorrência)
  - synchronous = NORMAL (equilíbrio entre desempenho e segurança)
  - cache_size = -10000 (10MB de cache em memória)
  - temp_store = MEMORY (armazena tabelas temporárias na memória)
  - mmap_size = 30000000000 (30GB para memory mapping)
  - auto_vacuum = INCREMENTAL (mantém o arquivo compacto)
  - read_uncommitted = 1 (permite leituras mais rápidas)
  - foreign_keys = ON (habilita integridade referencial)
  """
  @spec create_optimized_db(String.t()) :: :ok | {:error, any()}
  def create_optimized_db(db_path) do
    Logger.info("Criando banco de dados SQLite otimizado: #{db_path}", module: __MODULE__)

    try do
      # Criar uma conexão temporária diretamente com o SQLite
      {:ok, conn} = Exqlite.Connection.connect(database: db_path)

      # Aplicar pragmas para otimização
      pragmas = [
        "PRAGMA journal_mode = WAL",
        "PRAGMA synchronous = NORMAL",
        "PRAGMA cache_size = -10000",
        "PRAGMA page_size = 4096",
        "PRAGMA foreign_keys = ON",
        "PRAGMA temp_store = MEMORY",
        "PRAGMA mmap_size = 30000000000",
        "PRAGMA auto_vacuum = INCREMENTAL",
        "PRAGMA read_uncommitted = 1",
        "PRAGMA busy_timeout = 5000"
      ]

      # Aplicar cada pragma e registrar o resultado
      Enum.each(pragmas, fn pragma ->
        case Exqlite.Connection.execute(conn, pragma, [], []) do
          {:ok, %{rows: [[result]]}} ->
            Logger.debug("Aplicado: #{pragma} => #{result}", module: __MODULE__)
          {:ok, _} ->
            Logger.debug("Aplicado: #{pragma}", module: __MODULE__)
          {:error, reason} ->
            Logger.warning("Erro ao aplicar #{pragma}: #{inspect(reason)}", module: __MODULE__)
        end
      end)

      # Fechar a conexão
      :ok = Exqlite.Connection.disconnect(nil, conn)
      
      Logger.info("Banco de dados criado e otimizado com sucesso: #{db_path}", module: __MODULE__)
      :ok
    rescue
      e ->
        Logger.error("Erro ao criar banco de dados otimizado: #{inspect(e)}", module: __MODULE__)
        {:error, e}
    end
  end
end
