defmodule DeeperHub.Core.Data.Migrations.SysObjectsLiveUpdates do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_live_updates.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_live_updates.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_live_updates...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_objects_live_updates (
id int(11) unsigned NOT NULL  auto_increment,
name varchar(50) NOT NULL DEFAULT,
init tinyint(4) NOT NULL DEFAULT 0,
frequency tinyint(4) NOT NULL DEFAULT 1,
service_call text NOT NULL DEFAULT '',
active tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_live_updates criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_live_updates: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_live_updates.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_live_updates...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_live_updates
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_live_updates removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_live_updates: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
