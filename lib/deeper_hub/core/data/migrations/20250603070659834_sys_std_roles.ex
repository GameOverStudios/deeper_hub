defmodule DeeperHub.Core.Data.Migrations.SysStdRoles do
  @moduledoc """
  Migration para criar e remover a tabela sys_std_roles.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_std_roles.
  """
  def up do
    Logger.info("Criando tabela de sys_std_roles...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_std_roles (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    active INTEGER NOT NULL DEFAULT 1,
    "order" INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_std_roles criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_std_roles: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_std_roles: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_std_roles.
  """
  def down do
    Logger.info("Removendo tabela de sys_std_roles...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_std_roles
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_std_roles removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_std_roles: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_std_roles: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
