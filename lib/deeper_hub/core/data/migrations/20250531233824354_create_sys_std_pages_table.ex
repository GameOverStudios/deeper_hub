# Migração gerada com ID único: V1748745504354 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysStdPagesTable do
  # Migração gerada com ID único: V1748745504354 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_std_pages.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_std_pages.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_std_pages...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_std_pages (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      "index" INTEGER NOT NULL DEFAULT 0,
      name TEXT NOT NULL UNIQUE,
      header TEXT,
      caption TEXT,
      icon TEXT
    );

    CREATE INDEX IF NOT EXISTS idx_sys_std_pages_name ON sys_std_pages(name);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_std_pages criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_std_pages: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_std_pages.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_std_pages...", module: __MODULE__)

    sql = "DROP TABLE IF EXISTS sys_std_pages;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_std_pages removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_std_pages: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end