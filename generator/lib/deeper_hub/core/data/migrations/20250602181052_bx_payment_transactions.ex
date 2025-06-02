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
id int(11) NOT NULL  auto_increment,
pending_id int(11) NOT NULL DEFAULT 0,
client_id int(11) NOT NULL DEFAULT 0,
seller_id int(11) NOT NULL DEFAULT 0,
author_id int(11) NOT NULL DEFAULT 0,
module_id int(11) NOT NULL DEFAULT 0,
item_id int(11) NOT NULL DEFAULT 0,
item_count int(11) NOT NULL DEFAULT 0,
amount float NOT NULL DEFAULT 0,
currency varchar(4) NOT NULL DEFAULT,
license varchar(16) NOT NULL DEFAULT,
date int(11) NOT NULL DEFAULT 0,
new tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_transactions criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_payment_transactions: #{reason}", module: __MODULE__)
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

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_payment_transactions: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
