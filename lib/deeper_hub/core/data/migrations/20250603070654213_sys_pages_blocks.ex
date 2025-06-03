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
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object TEXT NOT NULL,
    cell_id INTEGER NOT NULL DEFAULT 1,
    module TEXT NOT NULL,
    title_system TEXT NOT NULL,
    title TEXT NOT NULL,
    designbox_id INTEGER NOT NULL DEFAULT 11,
    class TEXT NOT NULL,
    submenu TEXT NOT NULL,
    tabs INTEGER NOT NULL DEFAULT 0,
    async INTEGER NOT NULL DEFAULT 0,
    visible_for_levels INTEGER NOT NULL DEFAULT 2147483647,
    hidden_on TEXT NOT NULL,
    "type" TEXT NOT NULL DEFAULT 'raw',
    content TEXT NOT NULL,
    content_empty TEXT NOT NULL,
    text TEXT NOT NULL,
    text_updated INTEGER NOT NULL,
    help TEXT NOT NULL,
    cache_lifetime INTEGER NOT NULL DEFAULT 0,
    config_api TEXT NOT NULL,
    deletable INTEGER NOT NULL DEFAULT 1,
    copyable INTEGER NOT NULL DEFAULT 1,
    active INTEGER NOT NULL DEFAULT 1,
    active_api INTEGER NOT NULL DEFAULT 0,
    "order" INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_pages_blocks criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_pages_blocks: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_pages_blocks: #{inspect(reason)}", module: __MODULE__)
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

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_pages_blocks: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_pages_blocks: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
