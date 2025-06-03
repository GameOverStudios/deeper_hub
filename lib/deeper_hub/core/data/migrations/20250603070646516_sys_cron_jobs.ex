defmodule DeeperHub.Core.Data.Migrations.SysCronJobs do
  @moduledoc """
  Migration para criar e remover a tabela sys_cron_jobs.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_cron_jobs.
  """
  def up do
    Logger.info("Criando tabela de sys_cron_jobs...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_cron_jobs (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    time TEXT NOT NULL DEFAULT '*',
    class TEXT NOT NULL,
    file TEXT NOT NULL,
    service_call TEXT NOT NULL DEFAULT '''',
    ts INTEGER NOT NULL,
    timing REAL NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_cron_jobs criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_cron_jobs: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_cron_jobs: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_cron_jobs.
  """
  def down do
    Logger.info("Removendo tabela de sys_cron_jobs...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_cron_jobs
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_cron_jobs removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_cron_jobs: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_cron_jobs: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
