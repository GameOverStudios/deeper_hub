defmodule DeeperHub.Core.Data.Migrations.BxEventsIntervals do
  @moduledoc """
  Migration para criar e remover a tabela bx_events_intervals.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_events_intervals.
  """
  def up do
    Logger.info("Criando tabela de bx_events_intervals...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_events_intervals (
    interval_id INTEGER NOT NULL,
    event_id INTEGER NOT NULL,
    repeat_year INTEGER NOT NULL,
    repeat_month INTEGER NOT NULL,
    repeat_week_of_month INTEGER NOT NULL,
    repeat_day_of_month INTEGER NOT NULL,
    repeat_day_of_week INTEGER NOT NULL,
    repeat_stop INTEGER NOT NULL,
      PRIMARY KEY (interval_id)
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_events_intervals criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_events_intervals: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_events_intervals: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_events_intervals.
  """
  def down do
    Logger.info("Removendo tabela de bx_events_intervals...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_events_intervals
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_events_intervals removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_events_intervals: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_events_intervals: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
