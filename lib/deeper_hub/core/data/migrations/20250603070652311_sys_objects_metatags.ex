defmodule DeeperHub.Core.Data.Migrations.SysObjectsMetatags do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_metatags.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_metatags.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_metatags...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_objects_metatags (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object TEXT NOT NULL,
    module TEXT NOT NULL,
    table_keywords TEXT NOT NULL,
    table_locations TEXT NOT NULL,
    table_mentions TEXT NOT NULL,
    override_class_name TEXT NOT NULL,
    override_class_file TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_metatags criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_objects_metatags: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_metatags: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_metatags.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_metatags...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_metatags
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_metatags removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_objects_metatags: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_metatags: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
