defmodule DeeperHub.Core.Data.Migrations.BxPaymentSubscriptionsDeleted do
  @moduledoc """
  Migration para criar e remover a tabela bx_payment_subscriptions_deleted.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_payment_subscriptions_deleted.
  """
  def up do
    Logger.info("Criando tabela de bx_payment_subscriptions_deleted...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_payment_subscriptions_deleted (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    pending_id INTEGER NOT NULL DEFAULT 0,
    customer_id TEXT NOT NULL,
    subscription_id TEXT NOT NULL,
    period INTEGER NOT NULL DEFAULT 1,
    period_unit TEXT NOT NULL,
    trial INTEGER NOT NULL DEFAULT 0,
    date_add INTEGER NOT NULL DEFAULT 0,
    date_next INTEGER NOT NULL DEFAULT 0,
    pay_attempts INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'unpaid',
    reason TEXT NOT NULL,
    deleted INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_subscriptions_deleted criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_payment_subscriptions_deleted: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_payment_subscriptions_deleted: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_payment_subscriptions_deleted.
  """
  def down do
    Logger.info("Removendo tabela de bx_payment_subscriptions_deleted...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_payment_subscriptions_deleted
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_subscriptions_deleted removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_payment_subscriptions_deleted: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_payment_subscriptions_deleted: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
