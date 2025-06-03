defmodule DeeperHub.Core.Data.Migrations.BxFilesBookmarks do
  @moduledoc """
  Migration para criar e remover a tabela bx_files_bookmarks.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_files_bookmarks.
  """
  def up do
    Logger.info("Criando tabela de bx_files_bookmarks...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_files_bookmarks (
    object_id INTEGER NOT NULL DEFAULT 0,
    profile_id INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (object_id, profile_id)
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_files_bookmarks criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_files_bookmarks: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_files_bookmarks: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_files_bookmarks.
  """
  def down do
    Logger.info("Removendo tabela de bx_files_bookmarks...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_files_bookmarks
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_files_bookmarks removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_files_bookmarks: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_files_bookmarks: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
