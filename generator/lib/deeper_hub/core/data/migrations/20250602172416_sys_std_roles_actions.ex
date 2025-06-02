defmodule DeeperHub.Core.Data.Migrations.SysStdRolesActions do
  @moduledoc """
  Migration para criar e remover a tabela sys_std_roles_actions.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_std_roles_actions.
  """
  def up do
    Logger.info("Criando tabela de sys_std_roles_actions...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_std_roles_actions (
id int(11) unsigned NOT NULL  auto_increment,
name varchar(64) NOT NULL DEFAULT,
title varchar(255) NOT NULL,
description varchar(255) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_std_roles_actions criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_std_roles_actions: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_std_roles_actions.
  """
  def down do
    Logger.info("Removendo tabela de sys_std_roles_actions...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_std_roles_actions
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_std_roles_actions removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_std_roles_actions: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
