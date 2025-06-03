defmodule DeeperHub.Core.Data.Migrations.SysSeoUriRewrites do
  @moduledoc """
  Migration para criar e remover a tabela sys_seo_uri_rewrites.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_seo_uri_rewrites.
  """
  def up do
    Logger.info("Criando tabela de sys_seo_uri_rewrites...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_seo_uri_rewrites (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    uri_orig TEXT NOT NULL,
    uri_rewrite TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_seo_uri_rewrites criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_seo_uri_rewrites: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_seo_uri_rewrites: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_seo_uri_rewrites.
  """
  def down do
    Logger.info("Removendo tabela de sys_seo_uri_rewrites...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_seo_uri_rewrites
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_seo_uri_rewrites removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_seo_uri_rewrites: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_seo_uri_rewrites: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
