# Migração gerada com ID único: V1748745504226 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysCronJobsTable do
  # Migração gerada com ID único: V1748745504226 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_cron_jobs.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_cron_jobs...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_cron_jobs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL DEFAULT '', -- Nome descritivo do job
      time TEXT NOT NULL DEFAULT '*', -- Expressão Cron (ex: '0 * * * *')
      class TEXT NOT NULL DEFAULT '', -- Classe PHP a ser chamada
      file TEXT NOT NULL DEFAULT '', -- Arquivo PHP a ser executado
      service_call TEXT NOT NULL DEFAULT '', -- Chamada de serviço serializada (formato UNA)
      ts INTEGER NOT NULL DEFAULT 0, -- Unix Timestamp da última execução
      timing REAL NOT NULL DEFAULT 0.0 -- Duração da última execução em segundos (FLOAT/REAL)
    );
    CREATE INDEX IF NOT EXISTS idx_sys_cron_jobs_name ON sys_cron_jobs(name);
    CREATE INDEX IF NOT EXISTS idx_sys_cron_jobs_ts ON sys_cron_jobs(ts);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_cron_jobs criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_cron_jobs: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_cron_jobs...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS sys_cron_jobs;"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_cron_jobs removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_cron_jobs: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end