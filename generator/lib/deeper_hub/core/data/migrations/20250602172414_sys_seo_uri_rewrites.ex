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
id int(11) NOT NULL  auto_increment,
uri_orig varchar(255) NOT NULL,
uri_rewrite varchar(255) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_seo_uri_rewrites criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_seo_uri_rewrites: #{reason}", module: __MODULE__)
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

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_seo_uri_rewrites: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
