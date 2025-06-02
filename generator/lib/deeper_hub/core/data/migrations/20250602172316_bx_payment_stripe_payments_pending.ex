defmodule DeeperHub.Core.Data.Migrations.BxPaymentStripePaymentsPending do
  @moduledoc """
  Migration para criar e remover a tabela bx_payment_stripe_payments_pending.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_payment_stripe_payments_pending.
  """
  def up do
    Logger.info("Criando tabela de bx_payment_stripe_payments_pending...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_payment_stripe_payments_pending (
id int(11) NOT NULL  auto_increment,
subscription_id varchar(32) NOT NULL DEFAULT,
amount float NOT NULL DEFAULT 0,
currency varchar(4) NOT NULL DEFAULT,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_stripe_payments_pending criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_payment_stripe_payments_pending: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_payment_stripe_payments_pending.
  """
  def down do
    Logger.info("Removendo tabela de bx_payment_stripe_payments_pending...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_payment_stripe_payments_pending
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_stripe_payments_pending removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_payment_stripe_payments_pending: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
