defmodule DeeperHub.Core.Data.Migrations.BxAdsPromoLicenses do
  @moduledoc """
  Migration para criar e remover a tabela bx_ads_promo_licenses.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_ads_promo_licenses.
  """
  def up do
    Logger.info("Criando tabela de bx_ads_promo_licenses...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_ads_promo_licenses (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER NOT NULL DEFAULT 0,
    commodity_id INTEGER NOT NULL DEFAULT 0,
    entry_id INTEGER NOT NULL DEFAULT 0,
    amount REAL NOT NULL DEFAULT 0,
    "order" TEXT NOT NULL,
    license TEXT NOT NULL,
    added INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_ads_promo_licenses criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_ads_promo_licenses: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_ads_promo_licenses: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_ads_promo_licenses.
  """
  def down do
    Logger.info("Removendo tabela de bx_ads_promo_licenses...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_ads_promo_licenses
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_ads_promo_licenses removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_ads_promo_licenses: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_ads_promo_licenses: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
