defmodule DeeperHub.Core.Data.Migrations.BxNotificationsHandlers do
  @moduledoc """
  Migration para criar e remover a tabela bx_notifications_handlers.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_notifications_handlers.
  """
  def up do
    Logger.info("Criando tabela de bx_notifications_handlers...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_notifications_handlers (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "group" TEXT NOT NULL,
    "type" TEXT NOT NULL DEFAULT 'insert',
    alert_unit TEXT NOT NULL,
    alert_action TEXT NOT NULL,
    content TEXT NOT NULL,
    privacy TEXT NOT NULL,
    priority INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_notifications_handlers criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_notifications_handlers: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_notifications_handlers: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_notifications_handlers.
  """
  def down do
    Logger.info("Removendo tabela de bx_notifications_handlers...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_notifications_handlers
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_notifications_handlers removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_notifications_handlers: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_notifications_handlers: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
