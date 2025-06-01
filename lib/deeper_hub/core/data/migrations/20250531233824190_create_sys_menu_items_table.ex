# Migração gerada com ID único: V1748745504189 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysMenuItemsTable do
  # Migração gerada com ID único: V1748745504189 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_menu_items.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_menu_items.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_menu_items...", module: __MODULE__)

    # PRAGMA foreign_keys = ON;

    sql = """
    CREATE TABLE IF NOT EXISTS sys_menu_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      parent_id INTEGER NOT NULL DEFAULT 0, -- Refere-se a sys_menu_items.id para submenus
      set_name TEXT NOT NULL, -- FK para sys_menu_sets.set_name
      module TEXT NOT NULL,
      name TEXT NOT NULL,
      title_system TEXT, -- Chave de linguagem para o título
      title TEXT NOT NULL,
      link TEXT NOT NULL,
      onclick TEXT,
      target TEXT,
      icon TEXT,
      addon TEXT,
      addon_cache INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      markers TEXT,
      submenu_object TEXT, -- Nome do objeto de menu (sys_objects_menu.object) para o submenu
      submenu_popup INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      visible_for_levels INTEGER DEFAULT 2147483647, -- Bitmask ACL
      visibility_custom TEXT,
      hidden_on TEXT,
      hidden_on_cxt TEXT,
      hidden_on_pt INTEGER DEFAULT 0,
      hidden_on_col INTEGER DEFAULT 0,
      primary_item INTEGER NOT NULL DEFAULT 0, -- Renomeado de 'primary'
      collapsed INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      active INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      active_api INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      copyable INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      editable INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      "order" INTEGER NOT NULL,
      FOREIGN KEY (set_name) REFERENCES sys_menu_sets(set_name) ON DELETE CASCADE ON UPDATE CASCADE
      -- FK para parent_id (auto-referência), module (sys_modules.name),
      -- submenu_object (sys_objects_menu.object) são conceituais ou gerenciadas pela app.
    );

    CREATE INDEX IF NOT EXISTS idx_sys_menu_items_set_name_parent_order ON sys_menu_items(set_name, parent_id, "order");
    CREATE INDEX IF NOT EXISTS idx_sys_menu_items_module ON sys_menu_items(module);
    CREATE INDEX IF NOT EXISTS idx_sys_menu_items_name ON sys_menu_items(name);
    CREATE INDEX IF NOT EXISTS idx_sys_menu_items_link ON sys_menu_items(link);
    CREATE INDEX IF NOT EXISTS idx_sys_menu_items_submenu_object ON sys_menu_items(submenu_object);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_menu_items criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_menu_items: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_menu_items.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_menu_items...", module: __MODULE__)

    sql = "DROP TABLE IF EXISTS sys_menu_items;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_menu_items removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_menu_items: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end