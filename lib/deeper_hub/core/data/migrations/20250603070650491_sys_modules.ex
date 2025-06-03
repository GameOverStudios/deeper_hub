defmodule DeeperHub.Core.Data.Migrations.SysModules do
  @moduledoc """
  Migration para criar e remover a tabela sys_modules.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_modules.
  """
  def up do
    Logger.info("Criando tabela de sys_modules...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_modules (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "type" TEXT NOT NULL DEFAULT 'module',
    subtypes INTEGER NOT NULL DEFAULT 0,
    name TEXT NOT NULL,
    title TEXT NOT NULL,
    vendor TEXT NOT NULL,
    version TEXT NOT NULL,
    help_url TEXT NOT NULL,
    path TEXT NOT NULL,
    uri TEXT NOT NULL,
    class_prefix TEXT NOT NULL,
    db_prefix TEXT NOT NULL,
    lang_category TEXT NOT NULL,
    dependencies TEXT NOT NULL,
    date INTEGER NOT NULL DEFAULT 0,
    enabled INTEGER NOT NULL DEFAULT 0,
    pending_uninstall INTEGER NOT NULL,
    hash TEXT NOT NULL,
    updated INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_modules criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_modules: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_modules: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_modules.
  """
  def down do
    Logger.info("Removendo tabela de sys_modules...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_modules
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_modules removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_modules: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_modules: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
