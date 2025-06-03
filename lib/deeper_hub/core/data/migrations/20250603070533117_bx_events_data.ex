defmodule DeeperHub.Core.Data.Migrations.BxEventsData do
  @moduledoc """
  Migration para criar e remover a tabela bx_events_data.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_events_data.
  """
  def up do
    Logger.info("Criando tabela de bx_events_data...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_events_data (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    author INTEGER NOT NULL,
    added INTEGER NOT NULL,
    changed INTEGER NOT NULL,
    published INTEGER NOT NULL,
    picture INTEGER NOT NULL,
    cover INTEGER NOT NULL,
    cover_data TEXT NOT NULL,
    event_name TEXT NOT NULL,
    event_cat INTEGER NOT NULL,
    event_desc TEXT NOT NULL,
    hashtag TEXT NOT NULL,
    date_start INTEGER NULL,
    date_end INTEGER NULL,
    date_max INTEGER NULL,
    timezone TEXT NULL,
    labels TEXT NOT NULL,
    location TEXT NOT NULL,
    threshold INTEGER NOT NULL DEFAULT 0,
    members INTEGER NOT NULL DEFAULT 0,
    views INTEGER NOT NULL DEFAULT 0,
    rate REAL NOT NULL DEFAULT 0,
    votes INTEGER NOT NULL DEFAULT 0,
    rrate REAL NOT NULL DEFAULT 0,
    rvotes INTEGER NOT NULL DEFAULT 0,
    score INTEGER NOT NULL DEFAULT 0,
    sc_up INTEGER NOT NULL DEFAULT 0,
    sc_down INTEGER NOT NULL DEFAULT 0,
    favorites INTEGER NOT NULL DEFAULT 0,
    comments INTEGER NOT NULL DEFAULT 0,
    reports INTEGER NOT NULL DEFAULT 0,
    featured INTEGER NOT NULL DEFAULT 0,
    cf INTEGER NOT NULL DEFAULT 1,
    join_confirmation INTEGER NOT NULL DEFAULT 0,
    reminder INTEGER NOT NULL DEFAULT 1,
    allow_view_to TEXT NOT NULL DEFAULT 3,
    allow_post_to TEXT NOT NULL DEFAULT 3,
    status TEXT NOT NULL DEFAULT 'active',
    status_admin TEXT NOT NULL DEFAULT 'active'
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_events_data criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_events_data: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_events_data: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_events_data.
  """
  def down do
    Logger.info("Removendo tabela de bx_events_data...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_events_data
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_events_data removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_events_data: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_events_data: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
