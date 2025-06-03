defmodule DeeperHub.Core.Data.Migrations.SysAclActions do
  @moduledoc """
  Migration para criar e remover a tabela sys_acl_actions.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_acl_actions.
  """
  def up do
    Logger.info("Criando tabela de sys_acl_actions...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_acl_actions (
    ID INTEGER NOT NULL,
    Module TEXT NOT NULL,
    Name TEXT NOT NULL,
    AdditionalParamName TEXT NULL,
    Title TEXT NOT NULL,
    "Desc" TEXT NOT NULL,
    Countable INTEGER NOT NULL DEFAULT 0,
    DisabledForLevels INTEGER NOT NULL DEFAULT 3
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_acl_actions criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_acl_actions: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_acl_actions: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_acl_actions.
  """
  def down do
    Logger.info("Removendo tabela de sys_acl_actions...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_acl_actions
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_acl_actions removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_acl_actions: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_acl_actions: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
