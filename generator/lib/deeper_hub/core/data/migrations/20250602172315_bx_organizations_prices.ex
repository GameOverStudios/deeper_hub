defmodule DeeperHub.Core.Data.Migrations.BxOrganizationsPrices do
  @moduledoc """
  Migration para criar e remover a tabela bx_organizations_prices.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_organizations_prices.
  """
  def up do
    Logger.info("Criando tabela de bx_organizations_prices...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_organizations_prices (
id int(11) NOT NULL  auto_increment,
profile_id int(11) NOT NULL DEFAULT 0,
role_id int(11) unsigned NOT NULL DEFAULT 0,
name varchar(128) NOT NULL DEFAULT,
period int(11) unsigned NOT NULL DEFAULT 1,
period_unit varchar(32) NOT NULL DEFAULT,
price float unsigned NOT NULL DEFAULT 1,
order int(11) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_organizations_prices criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_organizations_prices: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_organizations_prices.
  """
  def down do
    Logger.info("Removendo tabela de bx_organizations_prices...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_organizations_prices
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_organizations_prices removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_organizations_prices: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
