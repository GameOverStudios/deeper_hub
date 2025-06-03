defmodule DeeperHub.Core.Data.Migrations.SysObjectsLiveUpdates do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_live_updates.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_live_updates.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_live_updates...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_objects_live_updates (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    init INTEGER NOT NULL DEFAULT 0,
    frequency INTEGER NOT NULL DEFAULT 1,
    service_call TEXT NOT NULL DEFAULT '''',
    active INTEGER NOT NULL DEFAULT 1
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_live_updates criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_objects_live_updates: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_live_updates: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_live_updates.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_live_updates...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_live_updates
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_live_updates removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_objects_live_updates: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_live_updates: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
