defmodule DeeperHub.Core.Data.Migrations.SysStdPages do
  @moduledoc """
  Migration para criar e remover a tabela sys_std_pages.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_std_pages.
  """
  def up do
    Logger.info("Criando tabela de sys_std_pages...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_std_pages (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "index" INTEGER NOT NULL DEFAULT 0,
    name TEXT NOT NULL,
    header TEXT NOT NULL,
    caption TEXT NOT NULL,
    icon TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_std_pages criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_std_pages: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_std_pages: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_std_pages.
  """
  def down do
    Logger.info("Removendo tabela de sys_std_pages...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_std_pages
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_std_pages removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_std_pages: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_std_pages: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
