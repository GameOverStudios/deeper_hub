defmodule DeeperHub.Core.Data.Migrations.BxTimelineVideos2events do
  @moduledoc """
  Migration para criar e remover a tabela bx_timeline_videos2events.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_timeline_videos2events.
  """
  def up do
    Logger.info("Criando tabela de bx_timeline_videos2events...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_timeline_videos2events (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    event_id INTEGER NOT NULL DEFAULT 0,
    media_id INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_timeline_videos2events criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_timeline_videos2events: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_timeline_videos2events: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_timeline_videos2events.
  """
  def down do
    Logger.info("Removendo tabela de bx_timeline_videos2events...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_timeline_videos2events
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_timeline_videos2events removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_timeline_videos2events: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_timeline_videos2events: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
