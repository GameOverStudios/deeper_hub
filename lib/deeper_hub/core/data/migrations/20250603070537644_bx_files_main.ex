defmodule DeeperHub.Core.Data.Migrations.BxFilesMain do
  @moduledoc """
  Migration para criar e remover a tabela bx_files_main.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_files_main.
  """
  def up do
    Logger.info("Criando tabela de bx_files_main...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_files_main (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    author INTEGER NOT NULL,
    added INTEGER NOT NULL,
    changed INTEGER NOT NULL,
    file_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    cat INTEGER NOT NULL,
    "desc" TEXT NOT NULL,
    data TEXT NOT NULL,
    data_processed INTEGER NOT NULL DEFAULT 0,
    labels TEXT NOT NULL,
    location TEXT NOT NULL,
    views INTEGER NOT NULL DEFAULT 0,
    rate REAL NOT NULL DEFAULT 0,
    votes INTEGER NOT NULL DEFAULT 0,
    rrate REAL NOT NULL DEFAULT 0,
    rvotes INTEGER NOT NULL DEFAULT 0,
    score INTEGER NOT NULL DEFAULT 0,
    sc_up INTEGER NOT NULL DEFAULT 0,
    sc_down INTEGER NOT NULL DEFAULT 0,
    favorites INTEGER NOT NULL DEFAULT 0,
    comments INTEGER NOT NULL DEFAULT 0,
    reports INTEGER NOT NULL DEFAULT 0,
    featured INTEGER NOT NULL DEFAULT 0,
    cf INTEGER NOT NULL DEFAULT 1,
    allow_view_to TEXT NOT NULL DEFAULT 3,
    status TEXT NOT NULL DEFAULT 'active',
    status_admin TEXT NOT NULL DEFAULT 'active',
    "type" TEXT NOT NULL DEFAULT 'file',
    parent_folder_id INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_files_main criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_files_main: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_files_main: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_files_main.
  """
  def down do
    Logger.info("Removendo tabela de bx_files_main...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_files_main
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_files_main removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_files_main: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_files_main: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
