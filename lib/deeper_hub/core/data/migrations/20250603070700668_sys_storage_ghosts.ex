defmodule DeeperHub.Core.Data.Migrations.SysStorageGhosts do
  @moduledoc """
  Migration para criar e remover a tabela sys_storage_ghosts.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_storage_ghosts.
  """
  def up do
    Logger.info("Criando tabela de sys_storage_ghosts...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_storage_ghosts (
    iid INTEGER NOT NULL,
    id INTEGER NOT NULL,
    profile_id INTEGER NOT NULL,
    object TEXT NOT NULL,
    content_id INTEGER NOT NULL,
    created INTEGER NOT NULL,
    "order" INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (iid)
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_storage_ghosts criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_storage_ghosts: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_storage_ghosts: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_storage_ghosts.
  """
  def down do
    Logger.info("Removendo tabela de sys_storage_ghosts...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_storage_ghosts
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_storage_ghosts removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_storage_ghosts: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_storage_ghosts: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
