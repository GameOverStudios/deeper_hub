defmodule DeeperHub.Core.Data.Migrations.BxNotificationsEvents do
  @moduledoc """
  Migration para criar e remover a tabela bx_notifications_events.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_notifications_events.
  """
  def up do
    Logger.info("Criando tabela de bx_notifications_events...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_notifications_events (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    owner_id INTEGER NOT NULL DEFAULT 0,
    "type" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    object_id TEXT NOT NULL,
    object_owner_id INTEGER NOT NULL DEFAULT 0,
    object_privacy_view TEXT NOT NULL DEFAULT 3,
    subobject_id INTEGER NOT NULL DEFAULT 0,
    content TEXT NOT NULL,
    source TEXT NOT NULL,
    allow_view_event_to TEXT NOT NULL DEFAULT 3,
    date INTEGER NOT NULL DEFAULT 0,
    processed INTEGER NOT NULL DEFAULT 0,
    active INTEGER NOT NULL DEFAULT 1
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_notifications_events criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_notifications_events: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_notifications_events: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_notifications_events.
  """
  def down do
    Logger.info("Removendo tabela de bx_notifications_events...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_notifications_events
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_notifications_events removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_notifications_events: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_notifications_events: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
