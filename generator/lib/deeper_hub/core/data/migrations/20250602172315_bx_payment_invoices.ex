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
id int(11) NOT NULL  auto_increment,
name varchar(64) NOT NULL DEFAULT,
commissionaire_id varchar(32) NOT NULL DEFAULT,
committent_id varchar(32) NOT NULL DEFAULT,
amount float NOT NULL DEFAULT 0,
currency varchar(4) NOT NULL DEFAULT,
period_start int(11) NOT NULL DEFAULT 0,
period_end int(11) NOT NULL DEFAULT 0,
date_issue int(11) NOT NULL DEFAULT 0,
date_due int(11) NOT NULL DEFAULT 0,
status varchar(32) NOT NULL DEFAULT unpaid,
ntf_exp tinyint(4) NOT NULL DEFAULT 0,
ntf_due tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_invoices criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_payment_invoices: #{reason}", module: __MODULE__)
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

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_payment_invoices: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
