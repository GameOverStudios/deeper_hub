defmodule DeeperHub.Core.Data.Migrations.SysMenuItems do
  @moduledoc """
  Migration para criar e remover a tabela sys_menu_items.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_menu_items.
  """
  def up do
    Logger.info("Criando tabela de sys_menu_items...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_menu_items (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    parent_id INTEGER NOT NULL DEFAULT 0,
    set_name TEXT NOT NULL,
    module TEXT NOT NULL,
    name TEXT NOT NULL,
    title_system TEXT NOT NULL,
    title TEXT NOT NULL,
    title_attr TEXT NOT NULL,
    link TEXT NOT NULL,
    onclick TEXT NOT NULL,
    target TEXT NOT NULL,
    area_label TEXT NOT NULL,
    icon TEXT NOT NULL,
    icon_only INTEGER NOT NULL DEFAULT 0,
    addon TEXT NOT NULL,
    addon_cache INTEGER NOT NULL DEFAULT 0,
    markers TEXT NOT NULL,
    submenu_object TEXT NOT NULL,
    submenu_popup INTEGER NOT NULL DEFAULT 0,
    visible_for_levels INTEGER NOT NULL DEFAULT 2147483647,
    visibility_custom TEXT NOT NULL,
    hidden_on TEXT NOT NULL,
    hidden_on_cxt TEXT NOT NULL,
    hidden_on_pt INTEGER NOT NULL DEFAULT 0,
    hidden_on_col INTEGER NOT NULL DEFAULT 0,
    config_api TEXT NOT NULL,
    "primary" INTEGER NOT NULL DEFAULT 0,
    collapsed INTEGER NOT NULL DEFAULT 0,
    active INTEGER NOT NULL DEFAULT 1,
    active_api INTEGER NOT NULL DEFAULT 0,
    copyable INTEGER NOT NULL DEFAULT 1,
    editable INTEGER NOT NULL DEFAULT 1,
    "order" INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_menu_items criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_menu_items: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_menu_items: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_menu_items.
  """
  def down do
    Logger.info("Removendo tabela de sys_menu_items...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_menu_items
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_menu_items removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_menu_items: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_menu_items: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
