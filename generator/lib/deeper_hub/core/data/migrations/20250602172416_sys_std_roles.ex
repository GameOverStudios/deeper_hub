defmodule DeeperHub.Core.Data.Migrations.SysStdRoles do
  @moduledoc """
  Migration para criar e remover a tabela sys_std_roles.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_std_roles.
  """
  def up do
    Logger.info("Criando tabela de sys_std_roles...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_std_roles (
id int(11) unsigned NOT NULL  auto_increment,
name varchar(64) NOT NULL DEFAULT,
title varchar(255) NOT NULL,
description varchar(255) NOT NULL DEFAULT,
active tinyint(4) NOT NULL DEFAULT 1,
order int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_std_roles criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_std_roles: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_std_roles.
  """
  def down do
    Logger.info("Removendo tabela de sys_std_roles...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_std_roles
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_std_roles removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_std_roles: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
