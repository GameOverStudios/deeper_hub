defmodule DeeperHub.Core.Data.Migrations.BxAlbumsFiles2albums do
  @moduledoc """
  Migration para criar e remover a tabela bx_albums_files2albums.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_albums_files2albums.
  """
  def up do
    Logger.info("Criando tabela de bx_albums_files2albums...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_albums_files2albums (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    content_id INTEGER NOT NULL,
    file_id INTEGER NOT NULL,
    author INTEGER NOT NULL,
    title TEXT NOT NULL,
    views INTEGER NOT NULL,
    rate REAL NOT NULL,
    votes INTEGER NOT NULL,
    score INTEGER NOT NULL DEFAULT 0,
    sc_up INTEGER NOT NULL DEFAULT 0,
    sc_down INTEGER NOT NULL DEFAULT 0,
    favorites INTEGER NOT NULL DEFAULT 0,
    comments INTEGER NOT NULL,
    reports INTEGER NOT NULL DEFAULT 0,
    featured INTEGER NOT NULL DEFAULT 0,
    cf INTEGER NOT NULL DEFAULT 1,
    data TEXT NOT NULL,
    exif TEXT NOT NULL,
    "order" INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_albums_files2albums criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_albums_files2albums: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_albums_files2albums: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_albums_files2albums.
  """
  def down do
    Logger.info("Removendo tabela de bx_albums_files2albums...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_albums_files2albums
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_albums_files2albums removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_albums_files2albums: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_albums_files2albums: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
