defmodule DeeperHub.Core.Data.Migrations.SysSeoLinks do
  @moduledoc """
  Migration para criar e remover a tabela sys_seo_links.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_seo_links.
  """
  def up do
    Logger.info("Criando tabela de sys_seo_links...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_seo_links (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    module TEXT NOT NULL,
    page_uri TEXT NOT NULL,
    param_name TEXT NOT NULL,
    param_value TEXT NOT NULL,
    uri TEXT NOT NULL,
    added INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_seo_links criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_seo_links: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_seo_links: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_seo_links.
  """
  def down do
    Logger.info("Removendo tabela de sys_seo_links...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_seo_links
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_seo_links removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_seo_links: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_seo_links: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
