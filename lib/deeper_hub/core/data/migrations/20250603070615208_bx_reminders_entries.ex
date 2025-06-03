defmodule DeeperHub.Core.Data.Migrations.BxRemindersEntries do
  @moduledoc """
  Migration para criar e remover a tabela bx_reminders_entries.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_reminders_entries.
  """
  def up do
    Logger.info("Criando tabela de bx_reminders_entries...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_reminders_entries (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    type_id INTEGER NOT NULL DEFAULT 0,
    rmd_pid INTEGER NOT NULL DEFAULT 0,
    cnt_pid INTEGER NOT NULL DEFAULT 0,
    params TEXT NOT NULL DEFAULT '''',
    notified TEXT NOT NULL DEFAULT '''',
    active INTEGER NOT NULL DEFAULT 0,
    visible INTEGER NOT NULL DEFAULT 0,
    added INTEGER NOT NULL,
    expired INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_reminders_entries criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_reminders_entries: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_reminders_entries: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_reminders_entries.
  """
  def down do
    Logger.info("Removendo tabela de bx_reminders_entries...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_reminders_entries
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_reminders_entries removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_reminders_entries: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_reminders_entries: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
