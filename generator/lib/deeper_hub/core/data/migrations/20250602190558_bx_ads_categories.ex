defmodule DeeperHub.Core.Data.Migrations.BxAdsCategories do
  @moduledoc """
  Migration para criar e remover a tabela bx_ads_categories.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_ads_categories.
  """
  def up do
    Logger.info("Criando tabela de bx_ads_categories...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_ads_categories (
id int(11) unsigned NOT NULL  auto_increment,
parent_id int(11) unsigned NOT NULL DEFAULT 0,
level tinyint(11) unsigned NOT NULL DEFAULT 0,
type int(11) NOT NULL DEFAULT 0,
name varchar(64) NOT NULL DEFAULT,
title varchar(255) NOT NULL DEFAULT,
text text NOT NULL,
icon varchar(255) NOT NULL DEFAULT,
items int(11) NOT NULL DEFAULT 0,
active tinyint(4) NOT NULL DEFAULT 1,
order int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_ads_categories criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_ads_categories: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_ads_categories.
  """
  def down do
    Logger.info("Removendo tabela de bx_ads_categories...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_ads_categories
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_ads_categories removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_ads_categories: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
