defmodule DeeperHub.Core.Data.Migrations.BxPaymentTransactions do
  @moduledoc """
  Migration para criar e remover a tabela bx_payment_transactions.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_payment_transactions.
  """
  def up do
    Logger.info("Criando tabela de bx_payment_transactions...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_payment_transactions (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    pending_id INTEGER NOT NULL DEFAULT 0,
    client_id INTEGER NOT NULL DEFAULT 0,
    seller_id INTEGER NOT NULL DEFAULT 0,
    author_id INTEGER NOT NULL DEFAULT 0,
    module_id INTEGER NOT NULL DEFAULT 0,
    item_id INTEGER NOT NULL DEFAULT 0,
    item_count INTEGER NOT NULL DEFAULT 0,
    amount REAL NOT NULL DEFAULT 0,
    currency TEXT NOT NULL,
    license TEXT NOT NULL,
    date INTEGER NOT NULL DEFAULT 0,
    new INTEGER NOT NULL DEFAULT 1
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_transactions criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_payment_transactions: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_payment_transactions: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_payment_transactions.
  """
  def down do
    Logger.info("Removendo tabela de bx_payment_transactions...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_payment_transactions
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_transactions removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_payment_transactions: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_payment_transactions: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
