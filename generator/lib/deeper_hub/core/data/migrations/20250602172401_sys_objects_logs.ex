defmodule DeeperHub.Core.Data.Migrations.SysObjectsLogs do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_logs.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_logs.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_logs...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_objects_logs (
id int(11) NOT NULL  auto_increment,
object varchar(64) NOT NULL,
module varchar(32) NOT NULL,
logs_storage varchar(32) NOT NULL,
title varchar(255) NOT NULL,
active tinyint(4) NOT NULL DEFAULT 1,
class_name varchar(255) NOT NULL,
class_file varchar(255) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_logs criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_logs: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_logs.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_logs...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_logs
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_logs removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_logs: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
