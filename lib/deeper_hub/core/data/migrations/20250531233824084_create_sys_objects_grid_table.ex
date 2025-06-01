# Migração gerada com ID único: V1748745504083 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysObjectsGridTable do
  # Migração gerada com ID único: V1748745504083 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_objects_grid.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_objects_grid.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_objects_grid...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_objects_grid (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object TEXT NOT NULL UNIQUE,
      source_type TEXT NOT NULL CHECK(source_type IN ('Sql', 'Array')),
      source TEXT NOT NULL,
      "table" TEXT NOT NULL,
      field_id TEXT NOT NULL,
      field_order TEXT NOT NULL,
      field_active TEXT,
      order_get_field TEXT NOT NULL DEFAULT 'order_field',
      order_get_dir TEXT NOT NULL DEFAULT 'order_dir',
      paginate_url TEXT,
      paginate_per_page INTEGER NOT NULL DEFAULT 10,
      paginate_simple TEXT,
      paginate_get_start TEXT NOT NULL,
      paginate_get_per_page TEXT NOT NULL,
      filter_fields TEXT,
      filter_fields_translatable TEXT,
      filter_mode TEXT NOT NULL DEFAULT 'auto' CHECK(filter_mode IN ('like', 'fulltext', 'auto')),
      filter_get TEXT NOT NULL DEFAULT 'filter',
      sorting_fields TEXT,
      sorting_fields_translatable TEXT,
      visible_for_levels INTEGER NOT NULL DEFAULT 2147483647,
      responsive INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      show_total_count INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      override_class_name TEXT,
      override_class_file TEXT
    );

    CREATE INDEX IF NOT EXISTS idx_sys_objects_grid_object ON sys_objects_grid(object);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_objects_grid criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_objects_grid: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_objects_grid.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_objects_grid...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS sys_objects_grid;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_objects_grid removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_objects_grid: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end
end
