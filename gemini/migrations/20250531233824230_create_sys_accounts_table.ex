# Migração gerada com ID único: V1748745504230 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysAccountsTable do
  # Migração gerada com ID único: V1748745504230 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_accounts.
  """

  # Assumindo que este é o seu módulo de acesso ao DB
  alias DeeperHub.Core.Data.Repo
  # Assumindo que este é o seu módulo de logging
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_accounts.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_accounts...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_accounts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      profile_id INTEGER,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      email_confirmed INTEGER NOT NULL DEFAULT 0,
      phone TEXT,
      phone_confirmed INTEGER NOT NULL DEFAULT 0,
      receive_updates INTEGER NOT NULL DEFAULT 1,
      receive_news INTEGER NOT NULL DEFAULT 1,
      password_hash TEXT NOT NULL,
      role INTEGER NOT NULL DEFAULT 1,
      lang_id INTEGER DEFAULT 0,
      added INTEGER NOT NULL, -- Unix Timestamp
      changed INTEGER NOT NULL, -- Unix Timestamp
      logged INTEGER, -- Unix Timestamp
      ip TEXT,
      referred TEXT,
      login_attempts INTEGER NOT NULL DEFAULT 0,
      locked INTEGER NOT NULL DEFAULT 0,
      active INTEGER NOT NULL DEFAULT 0
    );

    CREATE INDEX IF NOT EXISTS idx_sys_accounts_email ON sys_accounts(email);
    CREATE INDEX IF NOT EXISTS idx_sys_accounts_profile_id ON sys_accounts(profile_id);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_accounts criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_accounts: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_accounts.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_accounts...", module: __MODULE__)

    sql = "DROP TABLE IF EXISTS sys_accounts;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_accounts removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_accounts: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end
end
