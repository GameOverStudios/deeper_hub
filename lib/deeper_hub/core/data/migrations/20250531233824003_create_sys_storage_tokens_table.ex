# Migração gerada com ID único: V1748745504003 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysStorageTokensTable do
  # Migração gerada com ID único: V1748745504003 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_storage_tokens.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_storage_tokens.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_storage_tokens...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_storage_tokens (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      file_id INTEGER NOT NULL,
      storage_object TEXT NOT NULL,
      hash TEXT NOT NULL UNIQUE,
      created INTEGER NOT NULL,
      FOREIGN KEY (file_id) REFERENCES deeper_files(id) ON DELETE CASCADE,
      FOREIGN KEY (storage_object) REFERENCES sys_objects_storage(object) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_sys_storage_tokens_hash ON sys_storage_tokens(hash);
    CREATE INDEX IF NOT EXISTS idx_sys_storage_tokens_created ON sys_storage_tokens(created);
    -- Opcional: um índice em file_id pode ser útil se você frequentemente busca tokens por file_id
    CREATE INDEX IF NOT EXISTS idx_sys_storage_tokens_file_id ON sys_storage_tokens(file_id);
    """

    # Repo.execute("PRAGMA foreign_keys = ON;") -- Se necessário

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_storage_tokens criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_storage_tokens: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_storage_tokens.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_storage_tokens...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS sys_storage_tokens;"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_storage_tokens removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_storage_tokens: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end