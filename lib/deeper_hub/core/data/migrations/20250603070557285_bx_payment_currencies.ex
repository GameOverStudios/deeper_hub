defmodule DeeperHub.Core.Data.Migrations.BxPaymentCurrencies do
  @moduledoc """
  Migration para criar e remover a tabela bx_payment_currencies.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_payment_currencies.
  """
  def up do
    Logger.info("Criando tabela de bx_payment_currencies...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_payment_currencies (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    code TEXT NOT NULL,
    rate REAL NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_currencies criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_payment_currencies: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_payment_currencies: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_payment_currencies.
  """
  def down do
    Logger.info("Removendo tabela de bx_payment_currencies...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_payment_currencies
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_currencies removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_payment_currencies: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_payment_currencies: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
