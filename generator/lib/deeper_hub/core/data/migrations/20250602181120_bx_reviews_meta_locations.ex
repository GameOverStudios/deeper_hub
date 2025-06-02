defmodule DeeperHub.Core.Data.Migrations.BxReviewsMetaLocations do
  @moduledoc """
  Migration para criar e remover a tabela bx_reviews_meta_locations.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_reviews_meta_locations.
  """
  def up do
    Logger.info("Criando tabela de bx_reviews_meta_locations...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_reviews_meta_locations (
object_id int(10) unsigned NOT NULL,
lat double NOT NULL,
lng double NOT NULL,
country varchar(2) NOT NULL,
state varchar(255) NOT NULL,
city varchar(255) NOT NULL,
zip varchar(255) NOT NULL,
street varchar(255) NOT NULL,
street_number varchar(255) NOT NULL,
  PRIMARY KEY (object_id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_reviews_meta_locations criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_reviews_meta_locations: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_reviews_meta_locations.
  """
  def down do
    Logger.info("Removendo tabela de bx_reviews_meta_locations...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_reviews_meta_locations
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_reviews_meta_locations removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_reviews_meta_locations: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
