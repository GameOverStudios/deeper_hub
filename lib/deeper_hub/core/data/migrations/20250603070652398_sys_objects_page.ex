defmodule DeeperHub.Core.Data.Migrations.SysObjectsPage do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_page.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_page.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_page...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_objects_page (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    author INTEGER NOT NULL DEFAULT 0,
    added INTEGER NOT NULL DEFAULT 0,
    object TEXT NOT NULL,
    uri TEXT NOT NULL,
    title_system TEXT NOT NULL,
    title TEXT NOT NULL,
    module TEXT NOT NULL,
    cover INTEGER NOT NULL DEFAULT 1,
    cover_image INTEGER NOT NULL DEFAULT 0,
    cover_title TEXT NOT NULL,
    type_id INTEGER NOT NULL DEFAULT 1,
    layout_id INTEGER NOT NULL,
    sticky_columns INTEGER NOT NULL DEFAULT 0,
    submenu TEXT NOT NULL,
    visible_for_levels INTEGER NOT NULL DEFAULT 2147483647,
    visible_for_levels_editable INTEGER NOT NULL DEFAULT 1,
    url TEXT NOT NULL,
    content_info TEXT NOT NULL,
    meta_title TEXT NOT NULL,
    meta_description TEXT NOT NULL,
    meta_keywords TEXT NOT NULL,
    meta_robots TEXT NOT NULL,
    cache_lifetime INTEGER NOT NULL DEFAULT 0,
    cache_editable INTEGER NOT NULL DEFAULT 1,
    inj_head TEXT NOT NULL,
    inj_footer TEXT NOT NULL,
    config_api TEXT NOT NULL,
    deletable INTEGER NOT NULL,
    override_class_name TEXT NOT NULL,
    override_class_file TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_page criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_objects_page: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_page: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_page.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_page...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_page
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_page removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_objects_page: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_page: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
