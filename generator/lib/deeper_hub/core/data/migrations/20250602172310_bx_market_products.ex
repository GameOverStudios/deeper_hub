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
id int(11) unsigned NOT NULL  auto_increment,
author int(11) unsigned NOT NULL DEFAULT 0,
added int(11) NOT NULL DEFAULT 0,
changed int(11) NOT NULL DEFAULT 0,
thumb int(11) NOT NULL DEFAULT 0,
cover int(11) NOT NULL DEFAULT 0,
cover_data varchar(64) NOT NULL DEFAULT,
cover_raw longtext NOT NULL,
package int(11) NOT NULL DEFAULT 0,
name varchar(255) NOT NULL,
title varchar(255) NOT NULL,
text text NOT NULL,
notes text NOT NULL,
notes_purchased text NOT NULL,
cat int(11) NOT NULL,
price_single float NOT NULL DEFAULT 0,
price_recurring float NOT NULL DEFAULT 0,
duration_recurring varchar(16) NOT NULL DEFAULT month,
trial_recurring int(11) NOT NULL DEFAULT 0,
labels text NOT NULL,
location text NOT NULL,
views int(11) NOT NULL DEFAULT 0,
rate float NOT NULL DEFAULT 0,
votes int(11) NOT NULL DEFAULT 0,
rrate float NOT NULL DEFAULT 0,
rvotes int(11) NOT NULL DEFAULT 0,
score int(11) NOT NULL DEFAULT 0,
sc_up int(11) NOT NULL DEFAULT 0,
sc_down int(11) NOT NULL DEFAULT 0,
favorites int(11) NOT NULL DEFAULT 0,
comments int(11) NOT NULL DEFAULT 0,
reports int(11) NOT NULL DEFAULT 0,
featured int(11) NOT NULL DEFAULT 0,
cf int(11) NOT NULL DEFAULT 1,
allow_view_to varchar(32) NOT NULL DEFAULT 3,
allow_purchase_to varchar(32) NOT NULL DEFAULT 3,
allow_comment_to varchar(32) NOT NULL DEFAULT c,
allow_vote_to varchar(32) NOT NULL DEFAULT c,
status enum('active','hidden') NOT NULL DEFAULT active,
status_admin enum('active','hidden','pending') NOT NULL DEFAULT active,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_market_products criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_market_products: #{reason}", module: __MODULE__)
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

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_market_products: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
