defmodule DeeperHub.Core.Data.Migrations.BxAdsEntries do
  @moduledoc """
  Migration para criar e remover a tabela bx_ads_entries.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_ads_entries.
  """
  def up do
    Logger.info("Criando tabela de bx_ads_entries...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_ads_entries (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    author INTEGER NOT NULL,
    added INTEGER NOT NULL,
    changed INTEGER NOT NULL,
    sold INTEGER NOT NULL,
    shipped INTEGER NOT NULL,
    received INTEGER NOT NULL,
    source_type TEXT NOT NULL,
    source TEXT NOT NULL,
    category INTEGER NOT NULL,
    thumb INTEGER NOT NULL,
    name TEXT NOT NULL,
    title TEXT NOT NULL,
    url TEXT NOT NULL,
    price REAL NOT NULL,
    auction INTEGER NOT NULL DEFAULT 0,
    quantity INTEGER NOT NULL DEFAULT 1,
    single INTEGER NOT NULL DEFAULT 1,
    year INTEGER NOT NULL,
    text TEXT NOT NULL,
    notes_purchased TEXT NOT NULL,
    labels TEXT NOT NULL,
    tags TEXT NOT NULL,
    location TEXT NOT NULL,
    budget_total REAL NOT NULL DEFAULT 0,
    budget_daily REAL NOT NULL DEFAULT 0,
    impressions INTEGER NOT NULL DEFAULT 0,
    clicks INTEGER NOT NULL DEFAULT 0,
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
    reviews INTEGER NOT NULL DEFAULT 0,
    reviews_avg REAL NOT NULL DEFAULT 0,
    reports INTEGER NOT NULL DEFAULT 0,
    featured INTEGER NOT NULL DEFAULT 0,
    seg INTEGER NOT NULL DEFAULT 0,
    seg_gender INTEGER NOT NULL DEFAULT 0,
    seg_age_min INTEGER NOT NULL DEFAULT 0,
    seg_age_max INTEGER NOT NULL DEFAULT 0,
    seg_tags INTEGER NOT NULL DEFAULT 0,
    seg_country TEXT NOT NULL,
    cf INTEGER NOT NULL DEFAULT 1,
    allow_view_to TEXT NOT NULL DEFAULT 3,
    status TEXT NOT NULL DEFAULT 'active',
    status_admin TEXT NOT NULL DEFAULT 'active'
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_ads_entries criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_ads_entries: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_ads_entries: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_ads_entries.
  """
  def down do
    Logger.info("Removendo tabela de bx_ads_entries...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_ads_entries
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_ads_entries removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_ads_entries: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_ads_entries: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
