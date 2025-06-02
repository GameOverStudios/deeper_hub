defmodule DeeperHub.Core.Data.Migrations.SysPrivacyGroups do
  @moduledoc """
  Migration para criar e remover a tabela sys_privacy_groups.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_privacy_groups.
  """
  def up do
    Logger.info("Criando tabela de sys_privacy_groups...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_privacy_groups (
id int(11) unsigned NOT NULL  auto_increment,
title varchar(255) NOT NULL DEFAULT,
check text NOT NULL DEFAULT '',
active tinyint(4) NOT NULL DEFAULT 1,
visible tinyint(4) NOT NULL DEFAULT 1,
order int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_privacy_groups criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_privacy_groups: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_privacy_groups.
  """
  def down do
    Logger.info("Removendo tabela de sys_privacy_groups...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_privacy_groups
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_privacy_groups removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_privacy_groups: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
