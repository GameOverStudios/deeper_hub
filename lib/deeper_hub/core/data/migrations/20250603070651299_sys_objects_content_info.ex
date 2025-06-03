defmodule DeeperHub.Core.Data.Migrations.SysObjectsContentInfo do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_content_info.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_content_info.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_content_info...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_objects_content_info (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    title TEXT NOT NULL,
    alert_unit TEXT NOT NULL,
    alert_action_add TEXT NOT NULL,
    alert_action_update TEXT NOT NULL,
    alert_action_delete TEXT NOT NULL,
    class_name TEXT NOT NULL,
    class_file TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_content_info criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_objects_content_info: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_content_info: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_content_info.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_content_info...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_content_info
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_content_info removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_objects_content_info: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_content_info: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
