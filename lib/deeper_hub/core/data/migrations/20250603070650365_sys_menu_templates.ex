defmodule DeeperHub.Core.Data.Migrations.SysMenuTemplates do
  @moduledoc """
  Migration para criar e remover a tabela sys_menu_templates.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_menu_templates.
  """
  def up do
    Logger.info("Criando tabela de sys_menu_templates...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_menu_templates (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    template TEXT NOT NULL,
    title TEXT NOT NULL,
    visible INTEGER NOT NULL DEFAULT 1
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_menu_templates criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_menu_templates: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_menu_templates: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_menu_templates.
  """
  def down do
    Logger.info("Removendo tabela de sys_menu_templates...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_menu_templates
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_menu_templates removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_menu_templates: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_menu_templates: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
