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
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    caption TEXT NOT NULL,
    description TEXT NOT NULL,
    acl_id INTEGER NOT NULL DEFAULT 0,
    percentage REAL NOT NULL DEFAULT 0,
    installment REAL NOT NULL DEFAULT 0,
    active INTEGER NOT NULL DEFAULT 0,
    "order" INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_commissions criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_payment_commissions: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_payment_commissions: #{inspect(reason)}", module: __MODULE__)
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

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_payment_commissions: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_payment_commissions: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
