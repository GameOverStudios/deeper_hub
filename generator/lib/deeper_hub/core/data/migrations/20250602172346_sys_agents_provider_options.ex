defmodule DeeperHub.Core.Data.Migrations.SysAgentsProviderOptions do
  @moduledoc """
  Migration para criar e remover a tabela sys_agents_provider_options.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_agents_provider_options.
  """
  def up do
    Logger.info("Criando tabela de sys_agents_provider_options...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_agents_provider_options (
id int(11) NOT NULL  auto_increment,
provider_type_id int(11) NOT NULL DEFAULT 0,
name varchar(64) NOT NULL DEFAULT,
type varchar(64) NOT NULL DEFAULT text,
title varchar(255) NOT NULL DEFAULT,
description text NOT NULL DEFAULT '',
extra varchar(255) NOT NULL DEFAULT,
check_type varchar(64) NOT NULL DEFAULT,
check_params varchar(128) NOT NULL DEFAULT,
check_error varchar(128) NOT NULL DEFAULT,
order tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_provider_options criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_agents_provider_options: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_agents_provider_options.
  """
  def down do
    Logger.info("Removendo tabela de sys_agents_provider_options...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_agents_provider_options
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_provider_options removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_agents_provider_options: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
