defmodule DeeperHub.Core.Data.Migrations.SysObjectsStorage do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_storage.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_storage.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_storage...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_objects_storage (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object TEXT NOT NULL,
    engine TEXT NOT NULL,
    params TEXT NOT NULL,
    token_life INTEGER NOT NULL,
    cache_control INTEGER NOT NULL,
    levels INTEGER NOT NULL,
    table_files TEXT NOT NULL,
    ext_mode TEXT NOT NULL,
    ext_allow TEXT NOT NULL,
    ext_deny TEXT NOT NULL,
    quota_size INTEGER NOT NULL,
    current_size INTEGER NOT NULL,
    quota_number INTEGER NOT NULL,
    current_number INTEGER NOT NULL,
    max_file_size INTEGER NOT NULL,
    ts INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_storage criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_objects_storage: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_storage: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_storage.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_storage...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_storage
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_storage removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_objects_storage: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_storage: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
