defmodule DeeperHub.Core.Data.Migrations.BxTimelineEfVideos do
  @moduledoc """
  Migration para criar e remover a tabela bx_timeline_ef_videos.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_timeline_ef_videos.
  """
  def up do
    Logger.info("Criando tabela de bx_timeline_ef_videos...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_timeline_ef_videos (
    event_id INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (event_id)
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_timeline_ef_videos criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_timeline_ef_videos: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_timeline_ef_videos: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_timeline_ef_videos.
  """
  def down do
    Logger.info("Removendo tabela de bx_timeline_ef_videos...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_timeline_ef_videos
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_timeline_ef_videos removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_timeline_ef_videos: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_timeline_ef_videos: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
