defmodule DeeperHub.Core.Data.Migrations.BxAdsReviews do
  @moduledoc """
  Migration para criar e remover a tabela bx_ads_reviews.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_ads_reviews.
  """
  def up do
    Logger.info("Criando tabela de bx_ads_reviews...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_ads_reviews (
cmt_id int(11) NOT NULL  auto_increment,
cmt_parent_id int(11) NOT NULL DEFAULT 0,
cmt_vparent_id int(11) NOT NULL DEFAULT 0,
cmt_object_id int(11) NOT NULL DEFAULT 0,
cmt_author_id int(11) NOT NULL DEFAULT 0,
cmt_level int(11) NOT NULL DEFAULT 0,
cmt_text text NOT NULL,
cmt_mood tinyint(4) NOT NULL DEFAULT 0,
cmt_rate int(11) NOT NULL DEFAULT 0,
cmt_rate_count int(11) NOT NULL DEFAULT 0,
cmt_time int(11) unsigned NOT NULL DEFAULT 0,
cmt_replies int(11) NOT NULL DEFAULT 0,
cmt_pinned int(11) NOT NULL DEFAULT 0,
cmt_cf int(11) NOT NULL DEFAULT 1,
  PRIMARY KEY (cmt_id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_ads_reviews criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_ads_reviews: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_ads_reviews.
  """
  def down do
    Logger.info("Removendo tabela de bx_ads_reviews...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_ads_reviews
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_ads_reviews removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_ads_reviews: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
