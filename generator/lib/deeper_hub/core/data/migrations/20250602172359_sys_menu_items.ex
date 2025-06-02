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
id int(11) NOT NULL  auto_increment,
parent_id int(11) NOT NULL DEFAULT 0,
set_name varchar(64) NOT NULL,
module varchar(32) NOT NULL,
name varchar(255) NOT NULL,
title_system varchar(255) NOT NULL,
title varchar(255) NOT NULL,
title_attr varchar(255) NOT NULL DEFAULT,
link varchar(512) NOT NULL,
onclick varchar(255) NOT NULL,
target varchar(255) NOT NULL,
area_label varchar(255) NOT NULL DEFAULT,
icon text NOT NULL,
icon_only tinyint(4) NOT NULL DEFAULT 0,
addon text NOT NULL,
addon_cache tinyint(4) NOT NULL DEFAULT 0,
markers text NOT NULL,
submenu_object varchar(64) NOT NULL,
submenu_popup tinyint(4) NOT NULL DEFAULT 0,
visible_for_levels int(11) NOT NULL DEFAULT 2147483647,
visibility_custom text NOT NULL,
hidden_on varchar(255) NOT NULL DEFAULT,
hidden_on_cxt varchar(255) NOT NULL DEFAULT,
hidden_on_pt int(11) NOT NULL DEFAULT 0,
hidden_on_col int(11) NOT NULL DEFAULT 0,
config_api text NOT NULL,
primary tinyint(4) NOT NULL DEFAULT 0,
collapsed tinyint(4) NOT NULL DEFAULT 0,
active tinyint(4) NOT NULL DEFAULT 1,
active_api tinyint(4) NOT NULL DEFAULT 0,
copyable tinyint(4) NOT NULL DEFAULT 1,
editable tinyint(4) NOT NULL DEFAULT 1,
order int(11) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_menu_items criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_menu_items: #{reason}", module: __MODULE__)
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

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_menu_items: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
