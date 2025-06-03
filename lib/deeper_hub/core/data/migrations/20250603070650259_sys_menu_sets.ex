defmodule DeeperHub.Core.Data.Migrations.SysMenuSets do
  @moduledoc """
  Migration para criar e remover a tabela sys_menu_sets.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_menu_sets.
  """
  def up do
    Logger.info("Criando tabela de sys_menu_sets...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_menu_sets (
    set_name TEXT NOT NULL,
    module TEXT NOT NULL,
    title TEXT NOT NULL,
    deletable INTEGER NOT NULL DEFAULT 1,
      PRIMARY KEY (set_name)
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_menu_sets criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_menu_sets: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_menu_sets: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_menu_sets.
  """
  def down do
    Logger.info("Removendo tabela de sys_menu_sets...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_menu_sets
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_menu_sets removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_menu_sets: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_menu_sets: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
