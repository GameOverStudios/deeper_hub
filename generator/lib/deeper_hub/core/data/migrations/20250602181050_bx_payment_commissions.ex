defmodule DeeperHub.Core.Data.Migrations.BxPaymentCommissions do
  @moduledoc """
  Migration para criar e remover a tabela bx_payment_commissions.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_payment_commissions.
  """
  def up do
    Logger.info("Criando tabela de bx_payment_commissions...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_payment_commissions (
id int(11) NOT NULL  auto_increment,
name varchar(64) NOT NULL DEFAULT,
caption varchar(128) NOT NULL DEFAULT,
description varchar(128) NOT NULL DEFAULT,
acl_id int(11) NOT NULL DEFAULT 0,
percentage float NOT NULL DEFAULT 0,
installment float NOT NULL DEFAULT 0,
active tinyint(4) NOT NULL DEFAULT 0,
order tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_commissions criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_payment_commissions: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_payment_commissions.
  """
  def down do
    Logger.info("Removendo tabela de bx_payment_commissions...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_payment_commissions
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_commissions removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_payment_commissions: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
