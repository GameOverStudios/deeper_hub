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
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    caption TEXT NOT NULL,
    description TEXT NOT NULL,
    option_prefix TEXT NOT NULL,
    active INTEGER NOT NULL DEFAULT 0,
    "order" INTEGER NOT NULL DEFAULT 0,
    class_name TEXT NOT NULL,
    class_file TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_ads_sources criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_ads_sources: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_ads_sources: #{inspect(reason)}", module: __MODULE__)
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

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_ads_sources: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_ads_sources: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
