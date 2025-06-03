defmodule DeeperHub.Core.Data.Migrations.SysAclLevelsMembers do
  @moduledoc """
  Migration para criar e remover a tabela sys_acl_levels_members.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_acl_levels_members.
  """
  def up do
    Logger.info("Criando tabela de sys_acl_levels_members...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_acl_levels_members (
    IDMember INTEGER NOT NULL DEFAULT 0,
    IDLevel INTEGER NOT NULL DEFAULT 0,
    DateStarts TEXT NOT NULL DEFAULT '0000-00-00 00:00:00',
    DateExpires TEXT NULL,
    State TEXT NOT NULL,
    TransactionID TEXT NOT NULL,
      PRIMARY KEY (IDMember, IDLevel, DateStarts)
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_acl_levels_members criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_acl_levels_members: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_acl_levels_members: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_acl_levels_members.
  """
  def down do
    Logger.info("Removendo tabela de sys_acl_levels_members...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_acl_levels_members
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_acl_levels_members removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_acl_levels_members: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_acl_levels_members: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
