defmodule DeeperHub.Core.Data.Migrations.BxCreditsOrdersDeleted do
  @moduledoc """
  Migration para criar e remover a tabela bx_credits_orders_deleted.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_credits_orders_deleted.
  """
  def up do
    Logger.info("Criando tabela de bx_credits_orders_deleted...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_credits_orders_deleted (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER NOT NULL DEFAULT 0,
    bundle_id INTEGER NOT NULL DEFAULT 0,
    count INTEGER NOT NULL DEFAULT 0,
    "order" TEXT NOT NULL,
    license TEXT NOT NULL,
    "type" TEXT NOT NULL,
    added INTEGER NOT NULL DEFAULT 0,
    expired INTEGER NOT NULL DEFAULT 0,
    new INTEGER NOT NULL DEFAULT 1,
    reason TEXT NOT NULL,
    deleted INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_credits_orders_deleted criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_credits_orders_deleted: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_credits_orders_deleted: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_credits_orders_deleted.
  """
  def down do
    Logger.info("Removendo tabela de bx_credits_orders_deleted...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_credits_orders_deleted
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_credits_orders_deleted removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_credits_orders_deleted: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_credits_orders_deleted: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
