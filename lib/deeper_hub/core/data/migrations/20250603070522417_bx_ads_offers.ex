defmodule DeeperHub.Core.Data.Migrations.BxAdsOffers do
  @moduledoc """
  Migration para criar e remover a tabela bx_ads_offers.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_ads_offers.
  """
  def up do
    Logger.info("Criando tabela de bx_ads_offers...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_ads_offers (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    content_id INTEGER NOT NULL DEFAULT 0,
    author_id INTEGER NOT NULL DEFAULT 0,
    added INTEGER NOT NULL DEFAULT 0,
    changed INTEGER NOT NULL DEFAULT 0,
    amount REAL NOT NULL DEFAULT 0,
    quantity INTEGER NOT NULL DEFAULT 0,
    message TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'awaiting'
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_ads_offers criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_ads_offers: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_ads_offers: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_ads_offers.
  """
  def down do
    Logger.info("Removendo tabela de bx_ads_offers...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_ads_offers
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_ads_offers removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_ads_offers: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_ads_offers: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
