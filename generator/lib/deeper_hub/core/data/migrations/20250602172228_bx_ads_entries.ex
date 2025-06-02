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
id int(10) unsigned NOT NULL  auto_increment,
author int(11) NOT NULL,
added int(11) NOT NULL,
changed int(11) NOT NULL,
sold int(11) NOT NULL,
shipped int(11) NOT NULL,
received int(11) NOT NULL,
source_type varchar(32) NOT NULL DEFAULT,
source varchar(255) NOT NULL DEFAULT,
category int(11) NOT NULL,
thumb int(11) NOT NULL,
name varchar(255) NOT NULL,
title varchar(255) NOT NULL,
url varchar(255) NOT NULL,
price float NOT NULL,
auction tinyint(4) NOT NULL DEFAULT 0,
quantity int(11) NOT NULL DEFAULT 1,
single tinyint(4) NOT NULL DEFAULT 1,
year int(11) NOT NULL,
text mediumtext NOT NULL,
notes_purchased text NOT NULL,
labels text NOT NULL,
tags text NOT NULL,
location text NOT NULL,
budget_total float NOT NULL DEFAULT 0,
budget_daily float NOT NULL DEFAULT 0,
impressions int(11) unsigned NOT NULL DEFAULT 0,
clicks int(11) unsigned NOT NULL DEFAULT 0,
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
reviews int(11) NOT NULL DEFAULT 0,
reviews_avg float NOT NULL DEFAULT 0,
reports int(11) NOT NULL DEFAULT 0,
featured int(11) NOT NULL DEFAULT 0,
seg tinyint(4) NOT NULL DEFAULT 0,
seg_gender tinyint(4) NOT NULL DEFAULT 0,
seg_age_min int(11) NOT NULL DEFAULT 0,
seg_age_max int(11) NOT NULL DEFAULT 0,
seg_tags tinyint(4) NOT NULL DEFAULT 0,
seg_country varchar(255) NOT NULL DEFAULT,
cf int(11) NOT NULL DEFAULT 1,
allow_view_to varchar(16) NOT NULL DEFAULT 3,
status enum('active','awaiting','offer','sold','hidden') NOT NULL DEFAULT active,
status_admin enum('active','hidden','pending','unpaid') NOT NULL DEFAULT active,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_ads_entries criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_ads_entries: #{reason}", module: __MODULE__)
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

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_ads_entries: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
