defmodule DeeperHub.Core.Data.Migrations.SysAccounts do
  @moduledoc """
  Migration para criar e remover a tabela sys_accounts.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_accounts.
  """
  def up do
    Logger.info("Criando tabela de sys_accounts...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_accounts (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    picture INTEGER NOT NULL DEFAULT 0,
    email TEXT NOT NULL,
    email_confirmed INTEGER NOT NULL DEFAULT 0,
    phone TEXT NOT NULL,
    phone_confirmed INTEGER NOT NULL DEFAULT 0,
    receive_updates INTEGER NOT NULL DEFAULT 1,
    receive_news INTEGER NOT NULL DEFAULT 1,
    password TEXT NOT NULL,
    password_changed INTEGER NOT NULL DEFAULT 0,
    salt TEXT NOT NULL,
    role INTEGER NOT NULL DEFAULT 1,
    lang_id INTEGER NOT NULL DEFAULT 0,
    added INTEGER NOT NULL DEFAULT 0,
    changed INTEGER NOT NULL DEFAULT 0,
    logged INTEGER NOT NULL DEFAULT 0,
    ip TEXT NOT NULL,
    referred TEXT NOT NULL,
    login_attempts INTEGER NOT NULL DEFAULT 0,
    locked INTEGER NOT NULL DEFAULT 0,
    active INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_accounts criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_accounts: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_accounts: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_accounts.
  """
  def down do
    Logger.info("Removendo tabela de sys_accounts...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_accounts
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_accounts removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_accounts: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_accounts: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
