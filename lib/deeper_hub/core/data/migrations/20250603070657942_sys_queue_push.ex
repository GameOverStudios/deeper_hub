defmodule DeeperHub.Core.Data.Migrations.SysQueuePush do
  @moduledoc """
  Migration para criar e remover a tabela sys_queue_push.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_queue_push.
  """
  def up do
    Logger.info("Criando tabela de sys_queue_push...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_queue_push (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER NOT NULL DEFAULT 0,
    message TEXT NOT NULL DEFAULT ''''
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_queue_push criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_queue_push: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_queue_push: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_queue_push.
  """
  def down do
    Logger.info("Removendo tabela de sys_queue_push...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_queue_push
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_queue_push removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_queue_push: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_queue_push: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
