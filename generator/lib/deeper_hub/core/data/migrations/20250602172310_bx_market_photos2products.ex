defmodule DeeperHub.Core.Data.Migrations.BxMarketPhotos2products do
  @moduledoc """
  Migration para criar e remover a tabela bx_market_photos2products.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_market_photos2products.
  """
  def up do
    Logger.info("Criando tabela de bx_market_photos2products...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_market_photos2products (
id int(11) unsigned NOT NULL  auto_increment,
content_id int(11) unsigned NOT NULL,
file_id int(11) NOT NULL,
title varchar(255) NOT NULL,
order int(11) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_market_photos2products criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_market_photos2products: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_market_photos2products.
  """
  def down do
    Logger.info("Removendo tabela de bx_market_photos2products...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_market_photos2products
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_market_photos2products removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_market_photos2products: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
