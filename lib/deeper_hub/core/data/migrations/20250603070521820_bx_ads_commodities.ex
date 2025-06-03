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
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    entry_id INTEGER NOT NULL DEFAULT 0,
    "type" TEXT NOT NULL,
    amount REAL NOT NULL,
    added INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_ads_commodities criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_ads_commodities: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_ads_commodities: #{inspect(reason)}", module: __MODULE__)
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

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_ads_commodities: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_ads_commodities: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
