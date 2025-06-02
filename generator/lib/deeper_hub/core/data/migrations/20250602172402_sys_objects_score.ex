defmodule DeeperHub.Core.Data.Migrations.SysObjectsScore do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_score.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_score.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_score...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_objects_score (
id int(11) unsigned NOT NULL  auto_increment,
name varchar(50) NOT NULL DEFAULT,
module varchar(32) NOT NULL,
table_main varchar(50) NOT NULL DEFAULT,
table_track varchar(50) NOT NULL DEFAULT,
post_timeout int(11) NOT NULL DEFAULT 0,
pruning int(11) NOT NULL DEFAULT 31536000,
is_undo tinyint(1) NOT NULL DEFAULT 0,
is_on tinyint(1) NOT NULL DEFAULT 1,
trigger_table varchar(32) NOT NULL DEFAULT,
trigger_field_id varchar(32) NOT NULL DEFAULT,
trigger_field_author varchar(32) NOT NULL DEFAULT,
trigger_field_score varchar(32) NOT NULL DEFAULT,
trigger_field_cup varchar(32) NOT NULL DEFAULT,
trigger_field_cdown varchar(32) NOT NULL DEFAULT,
class_name varchar(32) NOT NULL DEFAULT,
class_file varchar(256) NOT NULL DEFAULT,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_score criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_score: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_score.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_score...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_score
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_score removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_score: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
