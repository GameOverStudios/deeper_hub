defmodule DeeperHub.Core.Data.Migrations.SysPagesWikiBlocks do
  @moduledoc """
  Migration para criar e remover a tabela sys_pages_wiki_blocks.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_pages_wiki_blocks.
  """
  def up do
    Logger.info("Criando tabela de sys_pages_wiki_blocks...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_pages_wiki_blocks (
id int(10) unsigned NOT NULL  auto_increment,
block_id int(11) NOT NULL,
revision int(11) NOT NULL,
language varchar(5) NOT NULL,
main_lang tinyint(4) NOT NULL DEFAULT 0,
profile_id int(10) unsigned NOT NULL,
content mediumtext NOT NULL,
unsafe tinyint(4) NOT NULL DEFAULT 0,
notes varchar(255) NOT NULL,
added int(11) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_pages_wiki_blocks criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_pages_wiki_blocks: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_pages_wiki_blocks.
  """
  def down do
    Logger.info("Removendo tabela de sys_pages_wiki_blocks...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_pages_wiki_blocks
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_pages_wiki_blocks removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_pages_wiki_blocks: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
