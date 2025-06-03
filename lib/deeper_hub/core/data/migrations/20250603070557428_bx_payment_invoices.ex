defmodule DeeperHub.Core.Data.Migrations.BxPaymentInvoices do
  @moduledoc """
  Migration para criar e remover a tabela bx_payment_invoices.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_payment_invoices.
  """
  def up do
    Logger.info("Criando tabela de bx_payment_invoices...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_payment_invoices (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    commissionaire_id TEXT NOT NULL,
    committent_id TEXT NOT NULL,
    amount REAL NOT NULL DEFAULT 0,
    currency TEXT NOT NULL,
    period_start INTEGER NOT NULL DEFAULT 0,
    period_end INTEGER NOT NULL DEFAULT 0,
    date_issue INTEGER NOT NULL DEFAULT 0,
    date_due INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'unpaid',
    ntf_exp INTEGER NOT NULL DEFAULT 0,
    ntf_due INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_invoices criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_payment_invoices: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_payment_invoices: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_payment_invoices.
  """
  def down do
    Logger.info("Removendo tabela de bx_payment_invoices...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_payment_invoices
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_invoices removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_payment_invoices: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_payment_invoices: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
