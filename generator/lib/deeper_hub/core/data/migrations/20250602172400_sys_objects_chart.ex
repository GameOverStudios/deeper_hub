defmodule DeeperHub.Core.Data.Migrations.SysObjectsChart do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_chart.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_chart.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_chart...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_objects_chart (
id int(11) NOT NULL  auto_increment,
object varchar(32) NOT NULL,
title varchar(255) NOT NULL,
table varchar(255) NOT NULL,
field_date_ts varchar(255) NOT NULL,
field_date_dt varchar(255) NOT NULL,
field_status varchar(255) NOT NULL,
column_date int(11) NOT NULL DEFAULT 0,
column_count int(11) NOT NULL DEFAULT 1,
type varchar(255) NOT NULL,
options text NOT NULL,
query text NOT NULL,
active tinyint(4) NOT NULL DEFAULT 1,
order int(11) NOT NULL,
class_name varchar(32) NOT NULL DEFAULT,
class_file varchar(256) NOT NULL DEFAULT,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_chart criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_chart: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_chart.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_chart...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_chart
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_chart removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_chart: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
