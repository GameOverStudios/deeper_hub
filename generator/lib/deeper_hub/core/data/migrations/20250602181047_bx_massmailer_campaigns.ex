defmodule DeeperHub.Core.Data.Migrations.BxMassmailerCampaigns do
  @moduledoc """
  Migration para criar e remover a tabela bx_massmailer_campaigns.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_massmailer_campaigns.
  """
  def up do
    Logger.info("Criando tabela de bx_massmailer_campaigns...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_massmailer_campaigns (
id int(11) unsigned NOT NULL  auto_increment,
title varchar(255) NULL,
subject varchar(255) NULL,
from_name varchar(255) NULL,
reply_to varchar(255) NULL,
body text NULL,
segments varchar(255) NULL,
author int(11) NOT NULL,
added int(11) NOT NULL DEFAULT 0,
changed int(11) NOT NULL DEFAULT 0,
date_sent int(11) NOT NULL DEFAULT 0,
email_list text NULL,
is_one_per_account smallint(1) NOT NULL,
is_track_links smallint(1) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_massmailer_campaigns criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_massmailer_campaigns: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_massmailer_campaigns.
  """
  def down do
    Logger.info("Removendo tabela de bx_massmailer_campaigns...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_massmailer_campaigns
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_massmailer_campaigns removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_massmailer_campaigns: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
