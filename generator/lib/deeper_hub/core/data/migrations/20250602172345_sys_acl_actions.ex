defmodule DeeperHub.Core.Data.Migrations.SysAclActions do
  @moduledoc """
  Migration para criar e remover a tabela sys_acl_actions.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_acl_actions.
  """
  def up do
    Logger.info("Criando tabela de sys_acl_actions...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_acl_actions (
ID int(10) unsigned NOT NULL  auto_increment,
Module varchar(32) NOT NULL,
Name varchar(255) NOT NULL DEFAULT,
AdditionalParamName varchar(80) NULL,
Title varchar(255) NOT NULL,
Desc varchar(255) NOT NULL,
Countable tinyint(4) NOT NULL DEFAULT 0,
DisabledForLevels int(10) unsigned NOT NULL DEFAULT 3,
  PRIMARY KEY (ID)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_acl_actions criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_acl_actions: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_acl_actions.
  """
  def down do
    Logger.info("Removendo tabela de sys_acl_actions...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_acl_actions
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_acl_actions removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_acl_actions: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
