defmodule DeeperHub.Core.Data.Migrations.BxClassesClasses do
  @moduledoc """
  Migration para criar e remover a tabela bx_classes_classes.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_classes_classes.
  """
  def up do
    Logger.info("Criando tabela de bx_classes_classes...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_classes_classes (
id int(10) unsigned NOT NULL  auto_increment,
author int(11) NOT NULL,
added int(11) NOT NULL,
changed int(11) NOT NULL,
published int(11) NOT NULL,
module_id int(10) unsigned NOT NULL,
order int(11) NOT NULL,
start_date int(11) NOT NULL,
end_date int(11) NOT NULL,
thumb int(11) NOT NULL,
title varchar(255) NOT NULL,
avail int(11) NOT NULL,
cmts int(11) NOT NULL,
completed_when int(11) NOT NULL,
text mediumtext NOT NULL,
labels text NOT NULL,
location text NOT NULL,
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
allow_view_to varchar(16) NOT NULL DEFAULT 3,
status enum('active','awaiting','failed','hidden') NOT NULL DEFAULT active,
status_admin enum('active','hidden','pending') NOT NULL DEFAULT active,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_classes_classes criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_classes_classes: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_classes_classes.
  """
  def down do
    Logger.info("Removendo tabela de bx_classes_classes...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_classes_classes
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_classes_classes removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_classes_classes: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
