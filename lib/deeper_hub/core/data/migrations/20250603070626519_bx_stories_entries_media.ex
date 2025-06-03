defmodule DeeperHub.Core.Data.Migrations.BxStoriesEntriesMedia do
  @moduledoc """
  Migration para criar e remover a tabela bx_stories_entries_media.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_stories_entries_media.
  """
  def up do
    Logger.info("Criando tabela de bx_stories_entries_media...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_stories_entries_media (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    content_id INTEGER NOT NULL,
    file_id INTEGER NOT NULL,
    author INTEGER NOT NULL,
    title TEXT NOT NULL,
    cf INTEGER NOT NULL DEFAULT 1,
    data TEXT NOT NULL,
    "order" INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_stories_entries_media criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_stories_entries_media: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_stories_entries_media: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_stories_entries_media.
  """
  def down do
    Logger.info("Removendo tabela de bx_stories_entries_media...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_stories_entries_media
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_stories_entries_media removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_stories_entries_media: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_stories_entries_media: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
