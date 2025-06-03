defmodule DeeperHub.Core.Data.Migrations.BxNotificationsSettings do
  @moduledoc """
  Migration para criar e remover a tabela bx_notifications_settings.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_notifications_settings.
  """
  def up do
    Logger.info("Criando tabela de bx_notifications_settings...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_notifications_settings (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "group" TEXT NOT NULL,
    handler_id INTEGER NOT NULL DEFAULT 0,
    delivery TEXT NOT NULL DEFAULT 'site',
    "type" TEXT NOT NULL DEFAULT 'personal',
    title TEXT NOT NULL,
    value INTEGER NOT NULL DEFAULT 1,
    active INTEGER NOT NULL DEFAULT 1,
    "order" INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_notifications_settings criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_notifications_settings: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_notifications_settings: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_notifications_settings.
  """
  def down do
    Logger.info("Removendo tabela de bx_notifications_settings...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_notifications_settings
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_notifications_settings removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_notifications_settings: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_notifications_settings: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
