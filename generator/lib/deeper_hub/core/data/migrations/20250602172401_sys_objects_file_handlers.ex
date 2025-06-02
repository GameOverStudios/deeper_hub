defmodule DeeperHub.Core.Data.Migrations.SysObjectsFileHandlers do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_file_handlers.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_file_handlers.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_file_handlers...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_objects_file_handlers (
id int(11) NOT NULL  auto_increment,
object varchar(64) NOT NULL,
title varchar(255) NOT NULL,
preg_ext text NOT NULL,
active tinyint(4) NOT NULL,
order int(11) NOT NULL,
override_class_name varchar(255) NOT NULL,
override_class_file varchar(255) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_file_handlers criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_file_handlers: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_file_handlers.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_file_handlers...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_file_handlers
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_file_handlers removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_file_handlers: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
