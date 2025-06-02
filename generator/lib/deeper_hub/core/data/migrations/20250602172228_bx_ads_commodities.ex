defmodule DeeperHub.Core.Data.Migrations.BxAdsCommodities do
  @moduledoc """
  Migration para criar e remover a tabela bx_ads_commodities.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_ads_commodities.
  """
  def up do
    Logger.info("Criando tabela de bx_ads_commodities...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_ads_commodities (
id int(11) unsigned NOT NULL  auto_increment,
entry_id int(11) NOT NULL DEFAULT 0,
type varchar(16) NOT NULL DEFAULT,
amount float NOT NULL,
added int(11) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_ads_commodities criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_ads_commodities: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_ads_commodities.
  """
  def down do
    Logger.info("Removendo tabela de bx_ads_commodities...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_ads_commodities
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_ads_commodities removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_ads_commodities: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
