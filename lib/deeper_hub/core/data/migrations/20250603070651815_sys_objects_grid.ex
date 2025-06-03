defmodule DeeperHub.Core.Data.Migrations.SysObjectsGrid do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_grid.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_grid.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_grid...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_objects_grid (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object TEXT NOT NULL,
    source_type TEXT NOT NULL,
    source TEXT NOT NULL,
    "table" TEXT NOT NULL,
    field_id TEXT NOT NULL,
    field_order TEXT NOT NULL,
    field_active TEXT NOT NULL,
    order_get_field TEXT NOT NULL DEFAULT 'order_field',
    order_get_dir TEXT NOT NULL DEFAULT 'order_dir',
    paginate_url TEXT NOT NULL,
    paginate_per_page INTEGER NOT NULL DEFAULT 10,
    paginate_simple TEXT NULL,
    paginate_get_start TEXT NOT NULL,
    paginate_get_per_page TEXT NOT NULL,
    filter_fields TEXT NOT NULL,
    filter_fields_translatable TEXT NOT NULL,
    filter_mode TEXT NOT NULL DEFAULT 'auto',
    filter_get TEXT NOT NULL DEFAULT 'filter',
    sorting_fields TEXT NOT NULL,
    sorting_fields_translatable TEXT NOT NULL,
    visible_for_levels INTEGER NOT NULL DEFAULT 2147483647,
    responsive INTEGER NOT NULL DEFAULT 1,
    show_total_count INTEGER NOT NULL DEFAULT 0,
    override_class_name TEXT NOT NULL,
    override_class_file TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_grid criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_objects_grid: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_grid: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_grid.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_grid...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_grid
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_grid removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_objects_grid: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_grid: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
