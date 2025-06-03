defmodule DeeperHub.Core.Data.Migrations.SysPagesBlocksData do
  @moduledoc """
  Migration para criar e remover a tabela sys_pages_blocks_data.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_pages_blocks_data.
  """
  def up do
    Logger.info("Criando tabela de sys_pages_blocks_data...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_pages_blocks_data (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    block_id INTEGER NOT NULL DEFAULT 0,
    content_id INTEGER NOT NULL DEFAULT 0,
    content_module TEXT NOT NULL,
    data TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_pages_blocks_data criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_pages_blocks_data: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_pages_blocks_data: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_pages_blocks_data.
  """
  def down do
    Logger.info("Removendo tabela de sys_pages_blocks_data...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_pages_blocks_data
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_pages_blocks_data removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_pages_blocks_data: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_pages_blocks_data: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
