defmodule DeeperHub.Core.Data.Migrations.SysObjectsView do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_view.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_view.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_view...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_objects_view (
id int(11) NOT NULL  auto_increment,
name varchar(64) NOT NULL,
module varchar(32) NOT NULL DEFAULT,
table_track varchar(32) NOT NULL,
period int(11) NOT NULL DEFAULT 86400,
pruning int(11) NOT NULL DEFAULT 31536000,
is_on tinyint(4) NOT NULL DEFAULT 1,
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
        Logger.info("Tabela de sys_objects_view criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_view: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_view.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_view...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_view
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_view removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_view: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
