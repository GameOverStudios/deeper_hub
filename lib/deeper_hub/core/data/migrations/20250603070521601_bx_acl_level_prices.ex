defmodule DeeperHub.Core.Data.Migrations.BxAclLevelPrices do
  @moduledoc """
  Migration para criar e remover a tabela bx_acl_level_prices.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_acl_level_prices.
  """
  def up do
    Logger.info("Criando tabela de bx_acl_level_prices...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_acl_level_prices (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    level_id INTEGER NOT NULL DEFAULT 0,
    name TEXT NOT NULL,
    period INTEGER NOT NULL DEFAULT 1,
    period_unit TEXT NOT NULL,
    trial INTEGER NOT NULL DEFAULT 0,
    price REAL NOT NULL DEFAULT 1,
    "immediate" INTEGER NOT NULL DEFAULT 1,
    "order" INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_acl_level_prices criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_acl_level_prices: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_acl_level_prices: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_acl_level_prices.
  """
  def down do
    Logger.info("Removendo tabela de bx_acl_level_prices...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_acl_level_prices
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_acl_level_prices removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_acl_level_prices: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_acl_level_prices: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
