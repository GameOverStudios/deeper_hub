defmodule DeeperHub.Core.Data.Migrations.BxTimelineRepostsTrack do
  @moduledoc """
  Migration para criar e remover a tabela bx_timeline_reposts_track.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_timeline_reposts_track.
  """
  def up do
    Logger.info("Criando tabela de bx_timeline_reposts_track...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_timeline_reposts_track (
id int(11) NOT NULL  auto_increment,
event_id int(11) NOT NULL DEFAULT 0,
author_id int(11) NOT NULL DEFAULT 0,
author_nip int(11) unsigned NOT NULL DEFAULT 0,
reposted_id int(11) NOT NULL DEFAULT 0,
date int(11) NOT NULL DEFAULT 0,
active tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_timeline_reposts_track criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_timeline_reposts_track: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_timeline_reposts_track.
  """
  def down do
    Logger.info("Removendo tabela de bx_timeline_reposts_track...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_timeline_reposts_track
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_timeline_reposts_track removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_timeline_reposts_track: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
