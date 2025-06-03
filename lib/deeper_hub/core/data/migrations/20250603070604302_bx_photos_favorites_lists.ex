defmodule DeeperHub.Core.Data.Migrations.BxPhotosFavoritesLists do
  @moduledoc """
  Migration para criar e remover a tabela bx_photos_favorites_lists.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_photos_favorites_lists.
  """
  def up do
    Logger.info("Criando tabela de bx_photos_favorites_lists...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_photos_favorites_lists (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    author_id INTEGER NOT NULL DEFAULT 0,
    date INTEGER NOT NULL DEFAULT 0,
    allow_view_favorite_list_to TEXT NOT NULL DEFAULT 3
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_photos_favorites_lists criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_photos_favorites_lists: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_photos_favorites_lists: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_photos_favorites_lists.
  """
  def down do
    Logger.info("Removendo tabela de bx_photos_favorites_lists...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_photos_favorites_lists
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_photos_favorites_lists removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_photos_favorites_lists: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_photos_favorites_lists: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
