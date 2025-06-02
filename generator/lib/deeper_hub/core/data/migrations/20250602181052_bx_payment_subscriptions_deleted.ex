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
id int(11) NOT NULL  auto_increment,
pending_id int(11) NOT NULL DEFAULT 0,
customer_id varchar(32) NOT NULL DEFAULT,
subscription_id varchar(32) NOT NULL DEFAULT,
period int(11) unsigned NOT NULL DEFAULT 1,
period_unit varchar(32) NOT NULL DEFAULT,
trial int(11) unsigned NOT NULL DEFAULT 0,
date_add int(11) NOT NULL DEFAULT 0,
date_next int(11) NOT NULL DEFAULT 0,
pay_attempts tinyint(4) NOT NULL DEFAULT 0,
status varchar(32) NOT NULL DEFAULT unpaid,
reason varchar(16) NOT NULL DEFAULT,
deleted int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_subscriptions_deleted criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_payment_subscriptions_deleted: #{reason}", module: __MODULE__)
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

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_payment_subscriptions_deleted: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
