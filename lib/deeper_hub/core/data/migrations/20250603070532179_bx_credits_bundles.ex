defmodule DeeperHub.Core.Data.Migrations.BxCreditsBundles do
  @moduledoc """
  Migration para criar e remover a tabela bx_credits_bundles.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_credits_bundles.
  """
  def up do
    Logger.info("Criando tabela de bx_credits_bundles...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_credits_bundles (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    added INTEGER NOT NULL,
    name TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    amount INTEGER NOT NULL DEFAULT 0,
    bonus INTEGER NOT NULL DEFAULT 0,
    price REAL NOT NULL DEFAULT 0,
    active INTEGER NOT NULL DEFAULT 0,
    "order" INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_credits_bundles criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_credits_bundles: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_credits_bundles: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_credits_bundles.
  """
  def down do
    Logger.info("Removendo tabela de bx_credits_bundles...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_credits_bundles
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_credits_bundles removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_credits_bundles: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_credits_bundles: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
