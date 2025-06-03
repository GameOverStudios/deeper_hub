defmodule DeeperHub.Core.Data.Migrations.BxRemindersTypes do
  @moduledoc """
  Migration para criar e remover a tabela bx_reminders_types.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_reminders_types.
  """
  def up do
    Logger.info("Criando tabela de bx_reminders_types...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_reminders_types (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    author INTEGER NOT NULL DEFAULT 0,
    added INTEGER NOT NULL,
    changed INTEGER NOT NULL,
    name TEXT NOT NULL,
    title TEXT NOT NULL,
    text TEXT NOT NULL,
    link TEXT NOT NULL,
    "when" TEXT NOT NULL,
    show INTEGER NOT NULL DEFAULT 0,
    notify TEXT NOT NULL,
    personal INTEGER NOT NULL DEFAULT 0,
    active INTEGER NOT NULL DEFAULT 0,
    "order" INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_reminders_types criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_reminders_types: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_reminders_types: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_reminders_types.
  """
  def down do
    Logger.info("Removendo tabela de bx_reminders_types...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_reminders_types
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_reminders_types removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_reminders_types: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_reminders_types: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
