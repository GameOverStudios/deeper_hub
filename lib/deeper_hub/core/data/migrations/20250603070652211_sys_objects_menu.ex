defmodule DeeperHub.Core.Data.Migrations.SysObjectsMenu do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_menu.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_menu.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_menu...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_objects_menu (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object TEXT NOT NULL,
    title TEXT NOT NULL,
    set_name TEXT NOT NULL,
    module TEXT NOT NULL,
    template_id INTEGER NOT NULL,
    config_api TEXT NOT NULL,
    persistent INTEGER NOT NULL DEFAULT 0,
    deletable INTEGER NOT NULL DEFAULT 1,
    active INTEGER NOT NULL DEFAULT 0,
    override_class_name TEXT NOT NULL,
    override_class_file TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_menu criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_objects_menu: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_menu: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_menu.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_menu...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_menu
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_menu removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_objects_menu: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_menu: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
