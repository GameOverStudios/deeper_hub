defmodule DeeperHub.Core.Data.Migrations.BxAdsSources do
  @moduledoc """
  Migration para criar e remover a tabela bx_ads_sources.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_ads_sources.
  """
  def up do
    Logger.info("Criando tabela de bx_ads_sources...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_ads_sources (
id int(11) NOT NULL  auto_increment,
name varchar(64) NOT NULL DEFAULT,
caption varchar(128) NOT NULL DEFAULT,
description varchar(128) NOT NULL DEFAULT,
option_prefix varchar(32) NOT NULL DEFAULT,
active tinyint(4) NOT NULL DEFAULT 0,
order tinyint(4) NOT NULL DEFAULT 0,
class_name varchar(128) NOT NULL DEFAULT,
class_file varchar(255) NOT NULL DEFAULT,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_ads_sources criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_ads_sources: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_ads_sources.
  """
  def down do
    Logger.info("Removendo tabela de bx_ads_sources...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_ads_sources
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_ads_sources removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_ads_sources: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
