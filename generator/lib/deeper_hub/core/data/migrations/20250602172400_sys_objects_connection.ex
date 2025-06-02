defmodule DeeperHub.Core.Data.Migrations.SysObjectsConnection do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_connection.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_connection.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_connection...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_objects_connection (
id int(11) NOT NULL  auto_increment,
object varchar(64) NOT NULL,
table varchar(255) NOT NULL,
profile_initiator tinyint(4) NOT NULL DEFAULT 1,
profile_content tinyint(4) NOT NULL DEFAULT 0,
type enum('one-way','mutual') NOT NULL,
tt_initiator varchar(32) NOT NULL DEFAULT,
tf_id_initiator varchar(32) NOT NULL DEFAULT,
tf_count_initiator varchar(32) NOT NULL DEFAULT,
tt_content varchar(32) NOT NULL DEFAULT,
tf_id_content varchar(32) NOT NULL DEFAULT,
tf_count_content varchar(32) NOT NULL DEFAULT,
override_class_name varchar(255) NOT NULL,
override_class_file varchar(255) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_connection criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_connection: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_connection.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_connection...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_connection
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_connection removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_connection: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
