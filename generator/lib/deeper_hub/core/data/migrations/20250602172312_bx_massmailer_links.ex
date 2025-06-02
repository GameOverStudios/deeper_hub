defmodule DeeperHub.Core.Data.Migrations.BxMassmailerLinks do
  @moduledoc """
  Migration para criar e remover a tabela bx_massmailer_links.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_massmailer_links.
  """
  def up do
    Logger.info("Criando tabela de bx_massmailer_links...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_massmailer_links (
id int(11) unsigned NOT NULL  auto_increment,
letter_hash varchar(35) NULL,
hash varchar(35) NULL,
link varchar(255) NULL,
title varchar(255) NULL,
campaign_id int(11) NULL,
date_click int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_massmailer_links criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_massmailer_links: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_massmailer_links.
  """
  def down do
    Logger.info("Removendo tabela de bx_massmailer_links...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_massmailer_links
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_massmailer_links removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_massmailer_links: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
