defmodule DeeperHub.Core.Data.Migrations.SysObjectsFeature do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_feature.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_feature.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_feature...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_objects_feature (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    module TEXT NOT NULL,
    is_on INTEGER NOT NULL DEFAULT 1,
    is_undo INTEGER NOT NULL DEFAULT 1,
    base_url TEXT NOT NULL,
    trigger_table TEXT NOT NULL,
    trigger_field_id TEXT NOT NULL,
    trigger_field_author TEXT NOT NULL,
    trigger_field_flag TEXT NOT NULL,
    class_name TEXT NOT NULL,
    class_file TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_feature criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_objects_feature: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_feature: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_feature.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_feature...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_feature
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_feature removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_objects_feature: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_feature: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
