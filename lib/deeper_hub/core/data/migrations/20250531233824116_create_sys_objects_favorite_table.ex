# Migração gerada com ID único: V1748745504115 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysObjectsFavoriteTable do
  # Migração gerada com ID único: V1748745504115 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_objects_favorite.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_objects_favorite.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_objects_favorite...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_objects_favorite (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      table_track TEXT NOT NULL, -- Tabela de rastreamento de favoritos
      table_lists TEXT, -- Tabela para listas de favoritos (opcional para API inicial)
      pruning INTEGER NOT NULL DEFAULT 31536000, -- 1 ano em segundos
      is_on INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      is_undo INTEGER NOT NULL DEFAULT 1, -- 0 ou 1 (se pode desfavoritar)
      is_public INTEGER NOT NULL DEFAULT 1, -- 0 ou 1 (se lista de quem favoritou é pública)
      base_url TEXT,
      trigger_table TEXT,
      trigger_field_id TEXT,
      trigger_field_author TEXT,
      trigger_field_count TEXT, -- Coluna para contagem de favoritos
      class_name TEXT,
      class_file TEXT
    );

    CREATE INDEX IF NOT EXISTS idx_sys_objects_favorite_name ON sys_objects_favorite(name);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_objects_favorite criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_objects_favorite: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_objects_favorite.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_objects_favorite...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS sys_objects_favorite;"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_objects_favorite removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_objects_favorite: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end