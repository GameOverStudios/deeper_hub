defmodule DeeperHub.Core.Data.Migrations.BxPaymentTransactionsPending do
  @moduledoc """
  Migration para criar e remover a tabela bx_payment_transactions_pending.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_payment_transactions_pending.
  """
  def up do
    Logger.info("Criando tabela de bx_payment_transactions_pending...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_payment_transactions_pending (
id int(10) unsigned NOT NULL  auto_increment,
client_id int(11) NOT NULL DEFAULT 0,
seller_id int(11) NOT NULL DEFAULT 0,
type varchar(16) NOT NULL DEFAULT single,
provider varchar(32) NOT NULL DEFAULT,
items text NOT NULL DEFAULT '',
customs text NOT NULL DEFAULT '',
amount float NOT NULL DEFAULT 0,
currency varchar(4) NOT NULL DEFAULT,
order varchar(32) NOT NULL DEFAULT,
data text NOT NULL,
error_code varchar(16) NOT NULL DEFAULT,
error_msg varchar(255) NOT NULL DEFAULT,
date int(11) NOT NULL DEFAULT 0,
authorized tinyint(4) NOT NULL DEFAULT 0,
processed tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_transactions_pending criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_payment_transactions_pending: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_payment_transactions_pending.
  """
  def down do
    Logger.info("Removendo tabela de bx_payment_transactions_pending...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_payment_transactions_pending
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_transactions_pending removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_payment_transactions_pending: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
