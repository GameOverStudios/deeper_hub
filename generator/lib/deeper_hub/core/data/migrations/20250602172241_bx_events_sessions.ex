defmodule DeeperHub.Core.Data.Migrations.BxEventsSessions do
  @moduledoc """
  Migration para criar e remover a tabela bx_events_sessions.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_events_sessions.
  """
  def up do
    Logger.info("Criando tabela de bx_events_sessions...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_events_sessions (
id int(10) unsigned NOT NULL  auto_increment,
event_id int(10) unsigned NOT NULL DEFAULT 0,
added int(11) NOT NULL DEFAULT 0,
title varchar(255) NOT NULL DEFAULT,
description text NOT NULL,
date_start int(11) NULL,
date_end int(11) NULL,
order int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_events_sessions criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_events_sessions: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_events_sessions.
  """
  def down do
    Logger.info("Removendo tabela de bx_events_sessions...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_events_sessions
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_events_sessions removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_events_sessions: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
