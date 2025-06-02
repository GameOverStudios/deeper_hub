defmodule DeeperHub.Core.Data.Migrations.SysObjectsLocationMap do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_location_map.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_location_map.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_location_map...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_objects_location_map (
id int(11) NOT NULL  auto_increment,
object varchar(64) NOT NULL,
module varchar(32) NOT NULL,
title varchar(255) NOT NULL,
class_name varchar(255) NOT NULL,
class_file varchar(255) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_location_map criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_location_map: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_location_map.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_location_map...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_location_map
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_location_map removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_location_map: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
