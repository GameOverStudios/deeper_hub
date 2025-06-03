defmodule DeeperHub.Core.Data.Migrations.BxAdsPromoTracker do
  @moduledoc """
  Migration para criar e remover a tabela bx_ads_promo_tracker.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_ads_promo_tracker.
  """
  def up do
    Logger.info("Criando tabela de bx_ads_promo_tracker...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_ads_promo_tracker (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    entry_id INTEGER NOT NULL DEFAULT 0,
    date INTEGER NOT NULL DEFAULT 0,
    impressions INTEGER NOT NULL DEFAULT 0,
    clicks INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_ads_promo_tracker criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_ads_promo_tracker: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_ads_promo_tracker: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_ads_promo_tracker.
  """
  def down do
    Logger.info("Removendo tabela de bx_ads_promo_tracker...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_ads_promo_tracker
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_ads_promo_tracker removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_ads_promo_tracker: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_ads_promo_tracker: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
