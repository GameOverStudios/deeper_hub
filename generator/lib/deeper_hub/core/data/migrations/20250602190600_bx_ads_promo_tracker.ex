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
id int(11) unsigned NOT NULL  auto_increment,
entry_id int(11) unsigned NOT NULL DEFAULT 0,
date int(11) unsigned NOT NULL DEFAULT 0,
impressions int(11) unsigned NOT NULL DEFAULT 0,
clicks int(11) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_ads_promo_tracker criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_ads_promo_tracker: #{reason}", module: __MODULE__)
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

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_ads_promo_tracker: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
