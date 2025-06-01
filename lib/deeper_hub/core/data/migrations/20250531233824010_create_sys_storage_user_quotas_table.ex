# Migração gerada com ID único: V1748745504010 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysStorageUserQuotasTable do
  # Migração gerada com ID único: V1748745504010 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_storage_user_quotas.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_storage_user_quotas...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_storage_user_quotas (
      profile_id INTEGER PRIMARY KEY, -- FK para sys_profiles.id
      current_size INTEGER NOT NULL DEFAULT 0, -- Tamanho total usado em bytes
      current_number INTEGER NOT NULL DEFAULT 0, -- Número total de arquivos
      ts INTEGER NOT NULL DEFAULT 0 -- Unix Timestamp da última atualização
      -- FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_storage_user_quotas criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_storage_user_quotas: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_storage_user_quotas...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS sys_storage_user_quotas;"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_storage_user_quotas removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_storage_user_quotas: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end