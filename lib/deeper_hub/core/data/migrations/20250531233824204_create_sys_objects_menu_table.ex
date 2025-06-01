# Migração gerada com ID único: V1748745504204 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysObjectsMenuTable do
  # Migração gerada com ID único: V1748745504204 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_objects_menu.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_objects_menu.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_objects_menu...", module: __MODULE__)

    # PRAGMA foreign_keys = ON;

    sql = """
    CREATE TABLE IF NOT EXISTS sys_objects_menu (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object TEXT NOT NULL UNIQUE, -- Nome único do objeto de menu
      title TEXT NOT NULL,
      set_name TEXT NOT NULL, -- FK para sys_menu_sets.set_name
      module TEXT NOT NULL,
      template_id INTEGER NOT NULL, -- FK para sys_menu_templates.id
      persistent INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      deletable INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      active INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      override_class_name TEXT,
      override_class_file TEXT,
      FOREIGN KEY (set_name) REFERENCES sys_menu_sets(set_name) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (template_id) REFERENCES sys_menu_templates(id) ON DELETE RESTRICT ON UPDATE CASCADE
      -- FK para module (sys_modules.name)
    );

    CREATE INDEX IF NOT EXISTS idx_sys_objects_menu_object ON sys_objects_menu(object);
    CREATE INDEX IF NOT EXISTS idx_sys_objects_menu_set_name ON sys_objects_menu(set_name);
    CREATE INDEX IF NOT EXISTS idx_sys_objects_menu_module ON sys_objects_menu(module);
    CREATE INDEX IF NOT EXISTS idx_sys_objects_menu_template_id ON sys_objects_menu(template_id);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_objects_menu criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_objects_menu: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_objects_menu.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_objects_menu...", module: __MODULE__)

    sql = "DROP TABLE IF EXISTS sys_objects_menu;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_objects_menu removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_objects_menu: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end