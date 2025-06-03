defmodule DeeperHub.Core.Data.Migrations.SysObjectsChart do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_chart.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_chart.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_chart...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_objects_chart (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object TEXT NOT NULL,
    title TEXT NOT NULL,
    "table" TEXT NOT NULL,
    field_date_ts TEXT NOT NULL,
    field_date_dt TEXT NOT NULL,
    field_status TEXT NOT NULL,
    column_date INTEGER NOT NULL DEFAULT 0,
    column_count INTEGER NOT NULL DEFAULT 1,
    "type" TEXT NOT NULL,
    options TEXT NOT NULL,
    "query" TEXT NOT NULL,
    active INTEGER NOT NULL DEFAULT 1,
    "order" INTEGER NOT NULL,
    class_name TEXT NOT NULL,
    class_file TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_chart criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_objects_chart: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_chart: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_chart.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_chart...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_chart
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_chart removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_objects_chart: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_chart: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
