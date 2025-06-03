defmodule DeeperHub.Core.Data.Migrations.BxTimelineMetaLocations do
  @moduledoc """
  Migration para criar e remover a tabela bx_timeline_meta_locations.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_timeline_meta_locations.
  """
  def up do
    Logger.info("Criando tabela de bx_timeline_meta_locations...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_timeline_meta_locations (
    object_id INTEGER NOT NULL,
    lat REAL NOT NULL,
    lng REAL NOT NULL,
    country TEXT NOT NULL,
    state TEXT NOT NULL,
    city TEXT NOT NULL,
    zip TEXT NOT NULL,
    street TEXT NOT NULL,
    street_number TEXT NOT NULL,
      PRIMARY KEY (id)
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_timeline_meta_locations criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_timeline_meta_locations: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_timeline_meta_locations.
  """
  def down do
    Logger.info("Removendo tabela de bx_timeline_meta_locations...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_timeline_meta_locations
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_timeline_meta_locations removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_timeline_meta_locations: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
