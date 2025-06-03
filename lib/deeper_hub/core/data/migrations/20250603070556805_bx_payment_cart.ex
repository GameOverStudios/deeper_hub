defmodule DeeperHub.Core.Data.Migrations.BxPaymentCart do
  @moduledoc """
  Migration para criar e remover a tabela bx_payment_cart.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_payment_cart.
  """
  def up do
    Logger.info("Criando tabela de bx_payment_cart...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_payment_cart (
    client_id INTEGER NOT NULL DEFAULT 0,
    items TEXT NOT NULL DEFAULT '''',
    customs TEXT NOT NULL DEFAULT '''',
      PRIMARY KEY (client_id)
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_cart criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_payment_cart: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_payment_cart: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_payment_cart.
  """
  def down do
    Logger.info("Removendo tabela de bx_payment_cart...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_payment_cart
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_cart removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_payment_cart: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_payment_cart: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
