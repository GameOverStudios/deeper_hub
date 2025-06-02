defmodule DeeperHub.Core.Data.Migrations.SysPagesBlocks do
  @moduledoc """
  Migration para criar e remover a tabela sys_pages_blocks.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_pages_blocks.
  """
  def up do
    Logger.info("Criando tabela de sys_pages_blocks...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_pages_blocks (
id int(11) NOT NULL  auto_increment,
object varchar(64) NOT NULL,
cell_id int(11) NOT NULL DEFAULT 1,
module varchar(32) NOT NULL,
title_system varchar(255) NOT NULL,
title varchar(255) NOT NULL,
designbox_id int(11) NOT NULL DEFAULT 11,
class varchar(128) NOT NULL DEFAULT,
submenu varchar(64) NOT NULL DEFAULT,
tabs tinyint(4) NOT NULL DEFAULT 0,
async int(11) NOT NULL DEFAULT 0,
visible_for_levels int(11) NOT NULL DEFAULT 2147483647,
hidden_on varchar(255) NOT NULL DEFAULT,
type enum('raw','html','creative','bento_grid','lang','image','rss','menu','custom','service','wiki') NOT NULL DEFAULT raw,
content mediumtext NOT NULL,
content_empty varchar(255) NOT NULL DEFAULT,
text mediumtext NOT NULL,
text_updated int(11) NOT NULL,
help varchar(255) NOT NULL,
cache_lifetime int(11) NOT NULL DEFAULT 0,
config_api text NOT NULL,
deletable tinyint(4) NOT NULL DEFAULT 1,
copyable tinyint(4) NOT NULL DEFAULT 1,
active tinyint(4) NOT NULL DEFAULT 1,
active_api tinyint(4) NOT NULL DEFAULT 0,
order int(11) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_pages_blocks criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_pages_blocks: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_pages_blocks.
  """
  def down do
    Logger.info("Removendo tabela de sys_pages_blocks...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_pages_blocks
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_pages_blocks removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_pages_blocks: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
