defmodule DeeperHub.Core.Data.Migrations.SysObjectsContentInfo do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_content_info.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_content_info.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_content_info...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_objects_content_info (
id int(11) NOT NULL  auto_increment,
name varchar(64) NOT NULL,
title varchar(128) NOT NULL,
alert_unit varchar(32) NOT NULL,
alert_action_add varchar(32) NOT NULL,
alert_action_update varchar(32) NOT NULL,
alert_action_delete varchar(32) NOT NULL,
class_name varchar(32) NOT NULL DEFAULT,
class_file varchar(256) NOT NULL DEFAULT,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_content_info criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_content_info: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_content_info.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_content_info...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_content_info
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_content_info removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_content_info: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
