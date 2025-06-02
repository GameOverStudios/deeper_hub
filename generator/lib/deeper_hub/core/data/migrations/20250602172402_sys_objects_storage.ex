defmodule DeeperHub.Core.Data.Migrations.SysObjectsStorage do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_storage.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_storage.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_storage...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_objects_storage (
id int(11) NOT NULL  auto_increment,
object varchar(64) NOT NULL,
engine varchar(32) NOT NULL,
params text NOT NULL,
token_life int(11) NOT NULL,
cache_control int(11) NOT NULL,
levels tinyint(4) NOT NULL,
table_files varchar(64) NOT NULL,
ext_mode enum('allow-deny','deny-allow') NOT NULL,
ext_allow text NOT NULL,
ext_deny text NOT NULL,
quota_size int(11) NOT NULL,
current_size int(11) NOT NULL,
quota_number int(11) NOT NULL,
current_number int(11) NOT NULL,
max_file_size int(11) NOT NULL,
ts int(11) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_storage criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_storage: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_storage.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_storage...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_storage
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_storage removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_storage: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
