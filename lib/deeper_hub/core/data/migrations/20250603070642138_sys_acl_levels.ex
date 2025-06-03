defmodule DeeperHub.Core.Data.Migrations.SysAclLevels do
  @moduledoc """
  Migration para criar e remover a tabela sys_acl_levels.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_acl_levels.
  """
  def up do
    Logger.info("Criando tabela de sys_acl_levels...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_acl_levels (
    ID INTEGER NOT NULL,
    Name TEXT NOT NULL,
    Icon TEXT NOT NULL DEFAULT '''',
    Description TEXT NOT NULL,
    Active TEXT NOT NULL DEFAULT 'no',
    Purchasable TEXT NOT NULL DEFAULT 'yes',
    Removable TEXT NOT NULL DEFAULT 'yes',
    QuotaSize INTEGER NOT NULL,
    QuotaNumber INTEGER NOT NULL,
    QuotaMaxFileSize INTEGER NOT NULL,
    "Order" INTEGER NOT NULL DEFAULT 0,
    PasswordExpired INTEGER NOT NULL DEFAULT 0,
    PasswordExpiredNotify INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_acl_levels criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_acl_levels: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_acl_levels: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_acl_levels.
  """
  def down do
    Logger.info("Removendo tabela de sys_acl_levels...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_acl_levels
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_acl_levels removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_acl_levels: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_acl_levels: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
