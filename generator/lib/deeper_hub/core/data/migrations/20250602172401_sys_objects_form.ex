defmodule DeeperHub.Core.Data.Migrations.SysObjectsForm do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_form.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_form.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_form...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_objects_form (
id int(11) NOT NULL  auto_increment,
object varchar(64) NOT NULL,
module varchar(32) NOT NULL,
title varchar(255) NOT NULL,
action varchar(255) NOT NULL,
form_attrs text NOT NULL,
submit_name varchar(255) NOT NULL,
table varchar(255) NOT NULL,
key varchar(255) NOT NULL,
uri varchar(255) NOT NULL,
uri_title varchar(255) NOT NULL,
params text NOT NULL,
deletable tinyint(4) NOT NULL DEFAULT 1,
active tinyint(4) NOT NULL DEFAULT 0,
parent_form varchar(64) NOT NULL DEFAULT,
override_class_name varchar(255) NOT NULL,
override_class_file varchar(255) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_form criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_form: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_form.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_form...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_form
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_form removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_form: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
