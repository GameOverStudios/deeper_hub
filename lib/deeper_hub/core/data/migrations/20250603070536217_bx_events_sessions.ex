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
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    event_id INTEGER NOT NULL DEFAULT 0,
    added INTEGER NOT NULL DEFAULT 0,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    date_start INTEGER NULL,
    date_end INTEGER NULL,
    "order" INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_events_sessions criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_events_sessions: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_events_sessions: #{inspect(reason)}", module: __MODULE__)
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

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_events_sessions: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_events_sessions: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
