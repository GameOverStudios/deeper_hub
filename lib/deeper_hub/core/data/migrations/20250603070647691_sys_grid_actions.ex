defmodule DeeperHub.Core.Data.Migrations.SysGridActions do
  @moduledoc """
  Migration para criar e remover a tabela sys_grid_actions.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_grid_actions.
  """
  def up do
    Logger.info("Criando tabela de sys_grid_actions...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_grid_actions (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object TEXT NOT NULL,
    "type" TEXT NOT NULL,
    name TEXT NOT NULL,
    title TEXT NOT NULL,
    icon TEXT NOT NULL,
    icon_only INTEGER NOT NULL DEFAULT 0,
    confirm INTEGER NOT NULL DEFAULT 1,
    active INTEGER NOT NULL DEFAULT 1,
    "order" INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_grid_actions criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_grid_actions: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_grid_actions: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_grid_actions.
  """
  def down do
    Logger.info("Removendo tabela de sys_grid_actions...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_grid_actions
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_grid_actions removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_grid_actions: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_grid_actions: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
