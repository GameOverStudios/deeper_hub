defmodule DeeperHub.Core.Data.Migrations.BxAdsLinks do
  @moduledoc """
  Migration para criar e remover a tabela bx_ads_links.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_ads_links.
  """
  def up do
    Logger.info("Criando tabela de bx_ads_links...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_ads_links (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER NOT NULL,
    media_id INTEGER NOT NULL DEFAULT 0,
    url TEXT NOT NULL,
    title TEXT NOT NULL,
    text TEXT NOT NULL,
    added INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_ads_links criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_ads_links: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_ads_links: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_ads_links.
  """
  def down do
    Logger.info("Removendo tabela de bx_ads_links...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_ads_links
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_ads_links removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_ads_links: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_ads_links: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
