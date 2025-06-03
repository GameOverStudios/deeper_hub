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
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    owner_id INTEGER NOT NULL DEFAULT 0,
    system INTEGER NOT NULL DEFAULT 1,
    "type" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    object_id INTEGER NOT NULL DEFAULT 0,
    object_owner_id INTEGER NOT NULL DEFAULT 0,
    object_privacy_view TEXT NOT NULL DEFAULT 3,
    object_cf INTEGER NOT NULL DEFAULT 1,
    content TEXT NOT NULL,
    source TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    labels TEXT NOT NULL,
    location TEXT NOT NULL,
    views INTEGER NOT NULL DEFAULT 0,
    rate REAL NOT NULL DEFAULT 0,
    votes INTEGER NOT NULL DEFAULT 0,
    rrate REAL NOT NULL DEFAULT 0,
    rvotes INTEGER NOT NULL DEFAULT 0,
    score INTEGER NOT NULL DEFAULT 0,
    sc_up INTEGER NOT NULL DEFAULT 0,
    sc_down INTEGER NOT NULL DEFAULT 0,
    comments INTEGER NOT NULL DEFAULT 0,
    reports INTEGER NOT NULL DEFAULT 0,
    reposts INTEGER NOT NULL DEFAULT 0,
    date INTEGER NOT NULL DEFAULT 0,
    published INTEGER NOT NULL DEFAULT 0,
    reacted INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'active',
    status_admin TEXT NOT NULL DEFAULT 'active',
    active INTEGER NOT NULL DEFAULT 1,
    pinned INTEGER NOT NULL DEFAULT 0,
    sticked INTEGER NOT NULL DEFAULT 0,
    promoted INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_timeline_events_slice criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_timeline_events_slice: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_timeline_events_slice: #{inspect(reason)}", module: __MODULE__)
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

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_timeline_events_slice: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_timeline_events_slice: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
