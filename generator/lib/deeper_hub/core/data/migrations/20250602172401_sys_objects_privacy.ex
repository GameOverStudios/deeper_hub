defmodule DeeperHub.Core.Data.Migrations.SysObjectsPrivacy do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_privacy.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_privacy.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_privacy...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_objects_privacy (
id int(11) NOT NULL  auto_increment,
object varchar(64) NOT NULL DEFAULT,
module varchar(64) NOT NULL DEFAULT,
action varchar(255) NOT NULL DEFAULT,
title varchar(255) NOT NULL DEFAULT,
default_group varchar(255) NOT NULL DEFAULT 1,
spaces varchar(255) NOT NULL DEFAULT all,
table varchar(255) NOT NULL DEFAULT,
table_field_id varchar(255) NOT NULL DEFAULT,
table_field_author varchar(255) NOT NULL DEFAULT,
override_class_name varchar(255) NOT NULL DEFAULT,
override_class_file varchar(255) NOT NULL DEFAULT,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_privacy criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_privacy: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_privacy.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_privacy...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_privacy
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_privacy removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_privacy: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
