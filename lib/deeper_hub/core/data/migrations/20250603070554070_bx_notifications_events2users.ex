defmodule DeeperHub.Core.Data.Migrations.BxNotificationsEvents2users do
  @moduledoc """
  Migration para criar e remover a tabela bx_notifications_events2users.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_notifications_events2users.
  """
  def up do
    Logger.info("Criando tabela de bx_notifications_events2users...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_notifications_events2users (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL DEFAULT 0,
    event_id INTEGER NOT NULL DEFAULT 0,
    clicked INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_notifications_events2users criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_notifications_events2users: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_notifications_events2users: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_notifications_events2users.
  """
  def down do
    Logger.info("Removendo tabela de bx_notifications_events2users...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_notifications_events2users
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_notifications_events2users removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_notifications_events2users: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_notifications_events2users: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
