# Migração gerada com ID único: V1748745504210 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysPagesBlocksDataTable do
  # Migração gerada com ID único: V1748745504210 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_pages_blocks_data.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_pages_blocks_data.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_pages_blocks_data (opcional)...", module: __MODULE__)

    # PRAGMA foreign_keys = ON;

    sql = """
    CREATE TABLE IF NOT EXISTS sys_pages_blocks_data (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      block_id INTEGER NOT NULL, -- FK para sys_pages_blocks.id
      content_id INTEGER NOT NULL, -- ID do conteúdo ao qual este override se aplica
      content_module TEXT NOT NULL, -- Módulo do conteúdo
      data TEXT NOT NULL, -- Dados de override, geralmente JSON
      FOREIGN KEY (block_id) REFERENCES sys_pages_blocks(id) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_pages_blocks_data_block_content ON sys_pages_blocks_data(block_id, content_id, content_module);
    CREATE INDEX IF NOT EXISTS idx_sys_pages_blocks_data_content_id_module ON sys_pages_blocks_data(content_id, content_module);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_pages_blocks_data criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_pages_blocks_data: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_pages_blocks_data.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_pages_blocks_data...", module: __MODULE__)

    sql = "DROP TABLE IF EXISTS sys_pages_blocks_data;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_pages_blocks_data removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_pages_blocks_data: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end