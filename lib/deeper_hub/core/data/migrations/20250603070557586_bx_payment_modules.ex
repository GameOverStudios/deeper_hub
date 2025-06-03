defmodule DeeperHub.Core.Data.Migrations.BxPaymentModules do
  @moduledoc """
  Migration para criar e remover a tabela bx_payment_modules.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_payment_modules.
  """
  def up do
    Logger.info("Criando tabela de bx_payment_modules...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_payment_modules (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_modules criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_payment_modules: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_payment_modules: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_payment_modules.
  """
  def down do
    Logger.info("Removendo tabela de bx_payment_modules...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_payment_modules
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_modules removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_payment_modules: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_payment_modules: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
