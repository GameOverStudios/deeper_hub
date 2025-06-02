defmodule DeeperHub.Core.Data.Migrations.SysWikiFiles do
  @moduledoc """
  Migration para criar e remover a tabela sys_wiki_files.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_wiki_files.
  """
  def up do
    Logger.info("Criando tabela de sys_wiki_files...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_wiki_files (
id int(11) NOT NULL  auto_increment,
profile_id int(10) unsigned NOT NULL,
remote_id varchar(128) NOT NULL,
path varchar(255) NOT NULL,
file_name varchar(255) NOT NULL,
mime_type varchar(128) NOT NULL,
ext varchar(32) NOT NULL,
size bigint(20) NOT NULL,
added int(11) NOT NULL,
modified int(11) NOT NULL,
private int(11) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_wiki_files criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_wiki_files: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_wiki_files.
  """
  def down do
    Logger.info("Removendo tabela de sys_wiki_files...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_wiki_files
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_wiki_files removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_wiki_files: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
