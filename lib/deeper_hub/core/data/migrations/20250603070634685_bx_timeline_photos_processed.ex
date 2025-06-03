defmodule DeeperHub.Core.Data.Migrations.BxTimelinePhotosProcessed do
  @moduledoc """
  Migration para criar e remover a tabela bx_timeline_photos_processed.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_timeline_photos_processed.
  """
  def up do
    Logger.info("Criando tabela de bx_timeline_photos_processed...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_timeline_photos_processed (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER NOT NULL,
    remote_id TEXT NOT NULL,
    path TEXT NOT NULL,
    file_name TEXT NOT NULL,
    mime_type TEXT NOT NULL,
    ext TEXT NOT NULL,
    size INTEGER NOT NULL,
    added INTEGER NOT NULL,
    modified INTEGER NOT NULL,
    private INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_timeline_photos_processed criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_timeline_photos_processed: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_timeline_photos_processed: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_timeline_photos_processed.
  """
  def down do
    Logger.info("Removendo tabela de bx_timeline_photos_processed...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_timeline_photos_processed
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_timeline_photos_processed removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_timeline_photos_processed: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_timeline_photos_processed: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
