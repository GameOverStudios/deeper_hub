defmodule DeeperHub.Core.Data.Migrations.BxPaymentUserValues do
  @moduledoc """
  Migration para criar e remover a tabela bx_payment_user_values.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_payment_user_values.
  """
  def up do
    Logger.info("Criando tabela de bx_payment_user_values...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_payment_user_values (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL DEFAULT 0,
    option_id INTEGER NOT NULL DEFAULT 0,
    value TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_user_values criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_payment_user_values: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_payment_user_values: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_payment_user_values.
  """
  def down do
    Logger.info("Removendo tabela de bx_payment_user_values...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_payment_user_values
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_user_values removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_payment_user_values: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_payment_user_values: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
