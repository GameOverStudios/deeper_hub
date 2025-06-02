defmodule DeeperHub.Core.Data.Migrations.BxTimelineEventsSlice do
  @moduledoc """
  Migration para criar e remover a tabela bx_timeline_events_slice.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_timeline_events_slice.
  """
  def up do
    Logger.info("Criando tabela de bx_timeline_events_slice...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_timeline_events_slice (
id int(11) NOT NULL  auto_increment,
owner_id int(11) NOT NULL DEFAULT 0,
system tinyint(4) NOT NULL DEFAULT 1,
type varchar(255) NOT NULL,
action varchar(255) NOT NULL,
object_id int(11) NOT NULL DEFAULT 0,
object_owner_id int(11) NOT NULL DEFAULT 0,
object_privacy_view varchar(16) NOT NULL DEFAULT 3,
object_cf int(11) NOT NULL DEFAULT 1,
content text NOT NULL,
source varchar(32) NOT NULL DEFAULT,
title varchar(255) NOT NULL,
description text NOT NULL,
labels text NOT NULL,
location text NOT NULL,
views int(11) unsigned NOT NULL DEFAULT 0,
rate float NOT NULL DEFAULT 0,
votes int(11) unsigned NOT NULL DEFAULT 0,
rrate float NOT NULL DEFAULT 0,
rvotes int(11) NOT NULL DEFAULT 0,
score int(11) NOT NULL DEFAULT 0,
sc_up int(11) NOT NULL DEFAULT 0,
sc_down int(11) NOT NULL DEFAULT 0,
comments int(11) unsigned NOT NULL DEFAULT 0,
reports int(11) unsigned NOT NULL DEFAULT 0,
reposts int(11) unsigned NOT NULL DEFAULT 0,
date int(11) NOT NULL DEFAULT 0,
published int(11) NOT NULL DEFAULT 0,
reacted int(11) NOT NULL DEFAULT 0,
status enum('active','awaiting','failed','hidden','deleted') NOT NULL DEFAULT active,
status_admin enum('active','hidden','pending') NOT NULL DEFAULT active,
active tinyint(4) NOT NULL DEFAULT 1,
pinned int(11) NOT NULL DEFAULT 0,
sticked int(11) NOT NULL DEFAULT 0,
promoted int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_timeline_events_slice criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_timeline_events_slice: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_timeline_events_slice.
  """
  def down do
    Logger.info("Removendo tabela de bx_timeline_events_slice...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_timeline_events_slice
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_timeline_events_slice removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_timeline_events_slice: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
