defmodule DeeperHub.Core.Data.Migrations.SysInjectionsAdmin do
  @moduledoc """
  Migration para criar e remover a tabela sys_injections_admin.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_injections_admin.
  """
  def up do
    Logger.info("Criando tabela de sys_injections_admin...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_injections_admin (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    page_index INTEGER NOT NULL DEFAULT 0,
    "key" TEXT NOT NULL,
    "type" TEXT NOT NULL DEFAULT 'text',
    data TEXT NOT NULL,
    "replace" INTEGER NOT NULL DEFAULT 0,
    active INTEGER NOT NULL DEFAULT 1
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_injections_admin criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_injections_admin: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_injections_admin: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_injections_admin.
  """
  def down do
    Logger.info("Removendo tabela de sys_injections_admin...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_injections_admin
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_injections_admin removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_injections_admin: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_injections_admin: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
