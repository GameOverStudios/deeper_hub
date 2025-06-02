defmodule DeeperHub.Core.Data.Migrations.BxTasksTasks do
  @moduledoc """
  Migration para criar e remover a tabela bx_tasks_tasks.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_tasks_tasks.
  """
  def up do
    Logger.info("Criando tabela de bx_tasks_tasks...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_tasks_tasks (
id int(10) unsigned NOT NULL  auto_increment,
author int(11) NOT NULL,
added int(11) NOT NULL,
changed int(11) NOT NULL,
published int(11) NOT NULL,
thumb int(11) NOT NULL,
title varchar(255) NOT NULL,
cat int(11) NOT NULL,
multicat text NOT NULL,
text mediumtext NOT NULL,
labels text NOT NULL,
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
due_date int(11) NOT NULL,
tasks_list int(11) NOT NULL,
completed tinyint(4) NOT NULL DEFAULT 0,
expired tinyint(4) NOT NULL DEFAULT 0,
cf int(11) NOT NULL DEFAULT 1,
allow_view_to varchar(16) NOT NULL DEFAULT 3,
allow_comments tinyint(4) NOT NULL DEFAULT 1,
status enum('active','awaiting','failed','hidden') NOT NULL DEFAULT active,
status_admin enum('active','hidden','pending') NOT NULL DEFAULT active,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_tasks_tasks criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_tasks_tasks: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_tasks_tasks.
  """
  def down do
    Logger.info("Removendo tabela de bx_tasks_tasks...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_tasks_tasks
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_tasks_tasks removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_tasks_tasks: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
