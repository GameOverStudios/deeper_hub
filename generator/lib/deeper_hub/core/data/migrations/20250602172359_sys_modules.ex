defmodule DeeperHub.Core.Data.Migrations.SysModules do
  @moduledoc """
  Migration para criar e remover a tabela sys_modules.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_modules.
  """
  def up do
    Logger.info("Criando tabela de sys_modules...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_modules (
id int(11) unsigned NOT NULL  auto_increment,
type varchar(16) NOT NULL DEFAULT module,
subtypes int(11) unsigned NOT NULL DEFAULT 0,
name varchar(32) NOT NULL DEFAULT,
title varchar(255) NOT NULL DEFAULT,
vendor varchar(64) NOT NULL DEFAULT,
version varchar(32) NOT NULL DEFAULT,
help_url varchar(128) NOT NULL DEFAULT,
path varchar(255) NOT NULL DEFAULT,
uri varchar(32) NOT NULL DEFAULT,
class_prefix varchar(32) NOT NULL DEFAULT,
db_prefix varchar(32) NOT NULL DEFAULT,
lang_category varchar(64) NOT NULL DEFAULT,
dependencies varchar(255) NOT NULL DEFAULT,
date int(11) unsigned NOT NULL DEFAULT 0,
enabled tinyint(1) NOT NULL DEFAULT 0,
pending_uninstall tinyint(4) NOT NULL,
hash varchar(32) NOT NULL DEFAULT,
updated int(11) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_modules criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_modules: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_modules.
  """
  def down do
    Logger.info("Removendo tabela de sys_modules...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_modules
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_modules removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_modules: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
