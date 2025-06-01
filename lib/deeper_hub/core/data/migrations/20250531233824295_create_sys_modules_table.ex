# Migração gerada com ID único: V1748745504295 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysModulesTable do
  # Migração gerada com ID único: V1748745504295 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_modules.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_modules.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_modules...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_modules (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type TEXT NOT NULL DEFAULT 'module',
      subtypes INTEGER NOT NULL DEFAULT 0,
      name TEXT NOT NULL UNIQUE,
      title TEXT NOT NULL,
      vendor TEXT NOT NULL,
      version TEXT NOT NULL,
      help_url TEXT,
      path TEXT NOT NULL UNIQUE,
      uri TEXT NOT NULL UNIQUE,
      class_prefix TEXT NOT NULL UNIQUE,
      db_prefix TEXT NOT NULL UNIQUE,
      lang_category TEXT NOT NULL,
      dependencies TEXT,
      date INTEGER NOT NULL, -- Unix Timestamp
      enabled INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      pending_uninstall INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      hash TEXT,
      updated INTEGER -- Unix Timestamp
    );

    CREATE INDEX IF NOT EXISTS idx_sys_modules_name ON sys_modules(name);
    CREATE INDEX IF NOT EXISTS idx_sys_modules_uri ON sys_modules(uri);
    CREATE INDEX IF NOT EXISTS idx_sys_modules_enabled ON sys_modules(enabled);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_modules criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_modules: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_modules.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_modules...", module: __MODULE__)

    sql = "DROP TABLE IF EXISTS sys_modules;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_modules removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_modules: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end