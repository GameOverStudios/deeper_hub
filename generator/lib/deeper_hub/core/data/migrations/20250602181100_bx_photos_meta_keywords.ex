defmodule DeeperHub.Core.Data.Migrations.BxPhotosMetaKeywords do
  @moduledoc """
  Migration para criar e remover a tabela bx_photos_meta_keywords.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_photos_meta_keywords.
  """
  def up do
    Logger.info("Criando tabela de bx_photos_meta_keywords...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_photos_meta_keywords (
id int(11) NOT NULL  auto_increment,
object_id int(10) unsigned NOT NULL,
keyword varchar(255) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_photos_meta_keywords criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_photos_meta_keywords: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_photos_meta_keywords.
  """
  def down do
    Logger.info("Removendo tabela de bx_photos_meta_keywords...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_photos_meta_keywords
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_photos_meta_keywords removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_photos_meta_keywords: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
