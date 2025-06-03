defmodule DeeperHub.Core.Data.Migrations.SysQueueEmail do
  @moduledoc """
  Migration para criar e remover a tabela sys_queue_email.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_queue_email.
  """
  def up do
    Logger.info("Criando tabela de sys_queue_email...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_queue_email (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    email TEXT NOT NULL,
    subject TEXT NOT NULL,
    body TEXT NOT NULL DEFAULT '''',
    params TEXT NOT NULL DEFAULT ''''
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_queue_email criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_queue_email: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_queue_email: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_queue_email.
  """
  def down do
    Logger.info("Removendo tabela de sys_queue_email...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_queue_email
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_queue_email removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_queue_email: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_queue_email: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
