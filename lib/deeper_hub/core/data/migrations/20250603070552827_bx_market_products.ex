defmodule DeeperHub.Core.Data.Migrations.BxMarketProducts do
  @moduledoc """
  Migration para criar e remover a tabela bx_market_products.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_market_products.
  """
  def up do
    Logger.info("Criando tabela de bx_market_products...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_market_products (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    author INTEGER NOT NULL DEFAULT 0,
    added INTEGER NOT NULL DEFAULT 0,
    changed INTEGER NOT NULL DEFAULT 0,
    thumb INTEGER NOT NULL DEFAULT 0,
    cover INTEGER NOT NULL DEFAULT 0,
    cover_data TEXT NOT NULL,
    cover_raw TEXT NOT NULL,
    package INTEGER NOT NULL DEFAULT 0,
    name TEXT NOT NULL,
    title TEXT NOT NULL,
    text TEXT NOT NULL,
    notes TEXT NOT NULL,
    notes_purchased TEXT NOT NULL,
    cat INTEGER NOT NULL,
    price_single REAL NOT NULL DEFAULT 0,
    price_recurring REAL NOT NULL DEFAULT 0,
    duration_recurring TEXT NOT NULL DEFAULT 'month',
    trial_recurring INTEGER NOT NULL DEFAULT 0,
    labels TEXT NOT NULL,
    location TEXT NOT NULL,
    views INTEGER NOT NULL DEFAULT 0,
    rate REAL NOT NULL DEFAULT 0,
    votes INTEGER NOT NULL DEFAULT 0,
    rrate REAL NOT NULL DEFAULT 0,
    rvotes INTEGER NOT NULL DEFAULT 0,
    score INTEGER NOT NULL DEFAULT 0,
    sc_up INTEGER NOT NULL DEFAULT 0,
    sc_down INTEGER NOT NULL DEFAULT 0,
    favorites INTEGER NOT NULL DEFAULT 0,
    comments INTEGER NOT NULL DEFAULT 0,
    reports INTEGER NOT NULL DEFAULT 0,
    featured INTEGER NOT NULL DEFAULT 0,
    cf INTEGER NOT NULL DEFAULT 1,
    allow_view_to TEXT NOT NULL DEFAULT 3,
    allow_purchase_to TEXT NOT NULL DEFAULT 3,
    allow_comment_to TEXT NOT NULL DEFAULT 'c',
    allow_vote_to TEXT NOT NULL DEFAULT 'c',
    status TEXT NOT NULL DEFAULT 'active',
    status_admin TEXT NOT NULL DEFAULT 'active'
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_market_products criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_market_products: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_market_products: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_market_products.
  """
  def down do
    Logger.info("Removendo tabela de bx_market_products...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_market_products
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_market_products removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_market_products: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_market_products: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
