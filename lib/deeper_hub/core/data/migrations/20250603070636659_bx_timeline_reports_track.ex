defmodule DeeperHub.Core.Data.Migrations.BxTimelineReportsTrack do
  @moduledoc """
  Migration para criar e remover a tabela bx_timeline_reports_track.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_timeline_reports_track.
  """
  def up do
    Logger.info("Criando tabela de bx_timeline_reports_track...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_timeline_reports_track (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object_id INTEGER NOT NULL DEFAULT 0,
    author_id INTEGER NOT NULL DEFAULT 0,
    author_nip INTEGER NOT NULL DEFAULT 0,
    "type" TEXT NOT NULL,
    text TEXT NOT NULL DEFAULT '''',
    date INTEGER NOT NULL DEFAULT 0,
    checked_by INTEGER NOT NULL DEFAULT 0,
    status INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_timeline_reports_track criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_timeline_reports_track: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_timeline_reports_track: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_timeline_reports_track.
  """
  def down do
    Logger.info("Removendo tabela de bx_timeline_reports_track...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_timeline_reports_track
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_timeline_reports_track removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_timeline_reports_track: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_timeline_reports_track: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
