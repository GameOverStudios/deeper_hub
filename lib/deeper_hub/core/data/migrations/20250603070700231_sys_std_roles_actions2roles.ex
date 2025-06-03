defmodule DeeperHub.Core.Data.Migrations.SysStdRolesActions2roles do
  @moduledoc """
  Migration para criar e remover a tabela sys_std_roles_actions2roles.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_std_roles_actions2roles.
  """
  def up do
    Logger.info("Criando tabela de sys_std_roles_actions2roles...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_std_roles_actions2roles (
    role_id INTEGER NOT NULL DEFAULT 0,
    action_id INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (role_id, action_id)
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_std_roles_actions2roles criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_std_roles_actions2roles: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_std_roles_actions2roles: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_std_roles_actions2roles.
  """
  def down do
    Logger.info("Removendo tabela de sys_std_roles_actions2roles...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_std_roles_actions2roles
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_std_roles_actions2roles removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_std_roles_actions2roles: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_std_roles_actions2roles: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
