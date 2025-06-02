defmodule DeeperHub.Core.Data.Migrations.SysAgentsModels do
  @moduledoc """
  Migration para criar e remover a tabela sys_agents_models.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_agents_models.
  """
  def up do
    Logger.info("Criando tabela de sys_agents_models...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_agents_models (
id int(11) NOT NULL  auto_increment,
name varchar(32) NOT NULL DEFAULT,
title varchar(64) NOT NULL DEFAULT,
key varchar(64) NOT NULL DEFAULT,
params text NOT NULL,
for_asst tinyint(4) NOT NULL DEFAULT 0,
active tinyint(4) NOT NULL DEFAULT 1,
hidden tinyint(4) NOT NULL DEFAULT 0,
class_name varchar(128) NOT NULL DEFAULT,
class_file varchar(255) NOT NULL DEFAULT,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_models criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_agents_models: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_agents_models.
  """
  def down do
    Logger.info("Removendo tabela de sys_agents_models...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_agents_models
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_models removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_agents_models: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
