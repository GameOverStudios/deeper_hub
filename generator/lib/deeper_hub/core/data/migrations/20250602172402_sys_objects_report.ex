defmodule DeeperHub.Core.Data.Migrations.SysObjectsReport do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_report.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_report.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_report...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_objects_report (
id int(11) NOT NULL  auto_increment,
name varchar(64) NOT NULL,
module varchar(32) NOT NULL DEFAULT,
table_main varchar(32) NOT NULL,
table_track varchar(32) NOT NULL,
pruning int(11) NOT NULL DEFAULT 31536000,
is_on tinyint(4) NOT NULL DEFAULT 1,
base_url varchar(256) NOT NULL DEFAULT,
object_comment varchar(64) NOT NULL,
trigger_table varchar(32) NOT NULL,
trigger_field_id varchar(32) NOT NULL,
trigger_field_author varchar(32) NOT NULL,
trigger_field_count varchar(32) NOT NULL,
class_name varchar(32) NOT NULL DEFAULT,
class_file varchar(256) NOT NULL DEFAULT,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_report criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_report: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_report.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_report...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_report
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_report removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_report: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
