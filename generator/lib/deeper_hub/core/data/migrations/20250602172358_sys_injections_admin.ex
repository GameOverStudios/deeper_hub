defmodule DeeperHub.Core.Data.Migrations.SysInjectionsAdmin do
  @moduledoc """
  Migration para criar e remover a tabela sys_injections_admin.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_injections_admin.
  """
  def up do
    Logger.info("Criando tabela de sys_injections_admin...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_injections_admin (
id int(11) unsigned NOT NULL  auto_increment,
name varchar(128) NOT NULL DEFAULT,
page_index int(11) NOT NULL DEFAULT 0,
key varchar(128) NOT NULL DEFAULT,
type enum('text','service') NOT NULL DEFAULT text,
data text NOT NULL,
replace tinyint(4) NOT NULL DEFAULT 0,
active tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_injections_admin criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_injections_admin: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_injections_admin.
  """
  def down do
    Logger.info("Removendo tabela de sys_injections_admin...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_injections_admin
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_injections_admin removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_injections_admin: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
