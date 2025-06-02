defmodule DeeperHub.Core.Data.Migrations.BxMarketSubproducts do
  @moduledoc """
  Migration para criar e remover a tabela bx_market_subproducts.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_market_subproducts.
  """
  def up do
    Logger.info("Criando tabela de bx_market_subproducts...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_market_subproducts (
id int(11) NOT NULL  auto_increment,
initiator int(11) NOT NULL,
content int(11) NOT NULL,
added int(10) unsigned NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_market_subproducts criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_market_subproducts: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_market_subproducts.
  """
  def down do
    Logger.info("Removendo tabela de bx_market_subproducts...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_market_subproducts
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_market_subproducts removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_market_subproducts: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
