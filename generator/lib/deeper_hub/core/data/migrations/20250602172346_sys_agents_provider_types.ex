defmodule DeeperHub.Core.Data.Migrations.SysAgentsProviderTypes do
  @moduledoc """
  Migration para criar e remover a tabela sys_agents_provider_types.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_agents_provider_types.
  """
  def up do
    Logger.info("Criando tabela de sys_agents_provider_types...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_agents_provider_types (
id int(11) NOT NULL  auto_increment,
name varchar(64) NOT NULL DEFAULT,
title varchar(128) NOT NULL DEFAULT,
option_prefix varchar(32) NOT NULL DEFAULT,
active tinyint(4) NOT NULL DEFAULT 0,
order tinyint(4) NOT NULL DEFAULT 0,
class_name varchar(128) NOT NULL DEFAULT,
class_file varchar(255) NOT NULL DEFAULT,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_provider_types criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_agents_provider_types: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_agents_provider_types.
  """
  def down do
    Logger.info("Removendo tabela de sys_agents_provider_types...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_agents_provider_types
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_provider_types removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_agents_provider_types: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
