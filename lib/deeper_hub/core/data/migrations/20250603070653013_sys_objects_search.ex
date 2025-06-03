defmodule DeeperHub.Core.Data.Migrations.SysObjectsSearch do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_search.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_search.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_search...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_objects_search (
    ID INTEGER NOT NULL,
    ObjectName TEXT NOT NULL,
    Title TEXT NOT NULL,
    "Order" INTEGER NOT NULL,
    GlobalSearch INTEGER NOT NULL DEFAULT 1,
    ClassName TEXT NOT NULL,
    ClassPath TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_search criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_objects_search: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_search: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_search.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_search...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_search
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_search removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_objects_search: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_search: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
