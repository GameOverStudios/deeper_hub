defmodule DeeperHub.Core.Data.Migrations.BxMapshowAccounts do
  @moduledoc """
  Migration para criar e remover a tabela bx_mapshow_accounts.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_mapshow_accounts.
  """
  def up do
    Logger.info("Criando tabela de bx_mapshow_accounts...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_mapshow_accounts (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    account_id INTEGER NOT NULL,
    lng REAL NULL,
    lat REAL NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_mapshow_accounts criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_mapshow_accounts: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_mapshow_accounts: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_mapshow_accounts.
  """
  def down do
    Logger.info("Removendo tabela de bx_mapshow_accounts...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_mapshow_accounts
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_mapshow_accounts removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_mapshow_accounts: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_mapshow_accounts: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
