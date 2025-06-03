defmodule DeeperHub.Core.Data.Migrations.SysAccountsPassword do
  @moduledoc """
  Migration para criar e remover a tabela sys_accounts_password.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_accounts_password.
  """
  def up do
    Logger.info("Criando tabela de sys_accounts_password...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_accounts_password (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    account_id INTEGER NOT NULL,
    password TEXT NOT NULL,
    password_changed INTEGER NOT NULL DEFAULT 0,
    salt TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_accounts_password criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_accounts_password: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_accounts_password: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_accounts_password.
  """
  def down do
    Logger.info("Removendo tabela de sys_accounts_password...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_accounts_password
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_accounts_password removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_accounts_password: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_accounts_password: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
