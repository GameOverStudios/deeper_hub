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
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    block_id INTEGER NOT NULL,
    revision INTEGER NOT NULL,
    language TEXT NOT NULL,
    main_lang INTEGER NOT NULL DEFAULT 0,
    profile_id INTEGER NOT NULL,
    content TEXT NOT NULL,
    unsafe INTEGER NOT NULL DEFAULT 0,
    notes TEXT NOT NULL,
    added INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_pages_wiki_blocks criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_pages_wiki_blocks: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_pages_wiki_blocks: #{inspect(reason)}", module: __MODULE__)
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

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_pages_wiki_blocks: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_pages_wiki_blocks: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
