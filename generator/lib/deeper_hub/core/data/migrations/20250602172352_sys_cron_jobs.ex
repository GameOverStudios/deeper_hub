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
id int(11) unsigned NOT NULL  auto_increment,
name varchar(128) NOT NULL DEFAULT,
time varchar(128) NOT NULL DEFAULT *,
class varchar(128) NOT NULL DEFAULT,
file varchar(255) NOT NULL DEFAULT,
service_call text NOT NULL DEFAULT '',
ts int(11) NOT NULL,
timing float NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_cron_jobs criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_cron_jobs: #{reason}", module: __MODULE__)
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

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_cron_jobs: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
