# Migração gerada com ID único: V1748745503848 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateBxPersonsMetaLocationsTable do
  # Migração gerada com ID único: V1748745503848 em 2025-05-31 23:38:23
  @moduledoc """
  Migração para criar a tabela bx_persons_meta_locations.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela bx_persons_meta_locations.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela bx_persons_meta_locations...", module: __MODULE__)
    # PRAGMA foreign_keys = ON;

    sql = """
    CREATE TABLE IF NOT EXISTS bx_persons_meta_locations (
      object_id INTEGER PRIMARY KEY NOT NULL, -- FK para sys_profiles.id
      lat REAL, -- No UNA é DOUBLE
      lng REAL, -- No UNA é DOUBLE
      country TEXT, -- No UNA é VARCHAR(2)
      state TEXT, -- No UNA é VARCHAR(255)
      city TEXT, -- No UNA é VARCHAR(255)
      zip TEXT, -- No UNA é VARCHAR(255)
      street TEXT, -- No UNA é VARCHAR(255)
      street_number TEXT, -- No UNA é VARCHAR(255)
      FOREIGN KEY (object_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
    );

    -- O índice `country_state_city (country, state(8), city(8))` do UNA.
    -- SQLite não suporta prefixos de índice, então indexamos as colunas inteiras.
    CREATE INDEX IF NOT EXISTS idx_bx_persons_meta_loc_country_state_city ON bx_persons_meta_locations(country, state, city);
    CREATE INDEX IF NOT EXISTS idx_bx_persons_meta_loc_lat_lng ON bx_persons_meta_locations(lat, lng); -- Para buscas espaciais
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela bx_persons_meta_locations criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela bx_persons_meta_locations: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela bx_persons_meta_locations.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela bx_persons_meta_locations...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS bx_persons_meta_locations;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela bx_persons_meta_locations removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela bx_persons_meta_locations: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end
end
