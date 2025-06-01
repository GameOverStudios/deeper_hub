# Migração gerada com ID único: V1748745504073 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysGridFieldsTable do
  # Migração gerada com ID único: V1748745504073 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_grid_fields.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_grid_fields.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_grid_fields...", module: __MODULE__)
    # PRAGMA foreign_keys = ON;

    sql = """
    CREATE TABLE IF NOT EXISTS sys_grid_fields (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object TEXT NOT NULL, -- FK para sys_objects_grid.object
      name TEXT NOT NULL, -- Nome do campo/coluna
      title TEXT, -- Título da coluna
      width TEXT NOT NULL,
      translatable INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      chars_limit INTEGER NOT NULL DEFAULT 0,
      params TEXT,
      hidden_on TEXT,
      "order" INTEGER NOT NULL,
      FOREIGN KEY (object) REFERENCES sys_objects_grid(object) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_grid_fields_object_name ON sys_grid_fields(object, name);
    CREATE INDEX IF NOT EXISTS idx_sys_grid_fields_object_order ON sys_grid_fields(object, "order");
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_grid_fields criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_grid_fields: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_grid_fields.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_grid_fields...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS sys_grid_fields;"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_grid_fields removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_grid_fields: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end