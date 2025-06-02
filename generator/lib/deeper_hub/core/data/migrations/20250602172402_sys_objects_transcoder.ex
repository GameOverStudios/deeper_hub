defmodule DeeperHub.Core.Data.Migrations.SysObjectsTranscoder do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_transcoder.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_transcoder.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_transcoder...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_objects_transcoder (
id int(11) NOT NULL  auto_increment,
object varchar(64) NOT NULL,
storage_object varchar(64) NOT NULL,
source_type enum('Folder','Storage','Proxy') NOT NULL,
source_params text NOT NULL,
private enum('auto','yes','no') NOT NULL,
atime_tracking int(11) NOT NULL,
atime_pruning int(11) NOT NULL,
ts int(11) NOT NULL DEFAULT 0,
override_class_name varchar(255) NOT NULL,
override_class_file varchar(255) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_transcoder criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_transcoder: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_transcoder.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_transcoder...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_transcoder
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_transcoder removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_transcoder: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
