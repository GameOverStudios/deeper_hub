defmodule DeeperHub.Core.Data.Migrations.BxJobsData do
  @moduledoc """
  Migration para criar e remover a tabela bx_jobs_data.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_jobs_data.
  """
  def up do
    Logger.info("Criando tabela de bx_jobs_data...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_jobs_data (
id int(10) unsigned NOT NULL  auto_increment,
author int(10) unsigned NOT NULL,
added int(11) NOT NULL,
changed int(11) NOT NULL,
picture int(11) NOT NULL,
cover int(11) NOT NULL,
cover_data varchar(50) NOT NULL,
name varchar(255) NOT NULL,
cat int(11) NOT NULL,
desc text NOT NULL,
date_start int(11) NULL,
date_end int(11) NULL,
timezone varchar(255) NULL,
pay_hourly float NOT NULL DEFAULT 0,
pay_total float NOT NULL DEFAULT 0,
labels text NOT NULL,
location text NOT NULL,
members int(11) NOT NULL DEFAULT 0,
views int(11) NOT NULL DEFAULT 0,
rate float NOT NULL DEFAULT 0,
votes int(11) NOT NULL DEFAULT 0,
rrate float NOT NULL DEFAULT 0,
rvotes int(11) NOT NULL DEFAULT 0,
score int(11) NOT NULL DEFAULT 0,
sc_up int(11) NOT NULL DEFAULT 0,
sc_down int(11) NOT NULL DEFAULT 0,
favorites int(11) NOT NULL DEFAULT 0,
comments int(11) NOT NULL DEFAULT 0,
reports int(11) NOT NULL DEFAULT 0,
featured int(11) NOT NULL DEFAULT 0,
cf int(11) NOT NULL DEFAULT 1,
join_confirmation tinyint(4) NOT NULL DEFAULT 0,
allow_view_to varchar(16) NOT NULL DEFAULT 3,
allow_post_to varchar(16) NOT NULL DEFAULT 3,
status enum('active','awaiting','hidden') NOT NULL DEFAULT active,
status_admin enum('active','hidden','pending') NOT NULL DEFAULT active,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_jobs_data criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_jobs_data: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_jobs_data.
  """
  def down do
    Logger.info("Removendo tabela de bx_jobs_data...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_jobs_data
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_jobs_data removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_jobs_data: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
