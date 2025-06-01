# Migração gerada com ID único: V1748745503902 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateDeeperEventsTable do
  # Migração gerada com ID único: V1748745503902 em 2025-05-31 23:38:23
  @moduledoc """
  Migração para criar a tabela deeper_events.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela deeper_events.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela deeper_events...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS deeper_events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      profile_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      slug TEXT NOT NULL UNIQUE,
      description TEXT NOT NULL,
      start_datetime INTEGER NOT NULL,
      end_datetime INTEGER NOT NULL,
      timezone TEXT,
      location_text TEXT,
      location_lat REAL,
      location_lng REAL,
      address TEXT,
      city TEXT,
      state TEXT,
      country TEXT,
      zip_code TEXT,
      banner_file_id INTEGER,
      visibility TEXT NOT NULL DEFAULT 'public' CHECK(visibility IN ('public', 'private', 'unlisted')),
      allow_rsvps INTEGER NOT NULL DEFAULT 1,
      max_attendees INTEGER DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'cancelled', 'past', 'draft')),
      rsvps_yes_count INTEGER NOT NULL DEFAULT 0,
      rsvps_maybe_count INTEGER NOT NULL DEFAULT 0,
      rsvps_no_count INTEGER NOT NULL DEFAULT 0,
      views INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
      FOREIGN KEY (banner_file_id) REFERENCES deeper_files(id) ON DELETE SET NULL
    );

    CREATE INDEX IF NOT EXISTS idx_deeper_events_profile_id ON deeper_events(profile_id);
    CREATE INDEX IF NOT EXISTS idx_deeper_events_slug ON deeper_events(slug);
    CREATE INDEX IF NOT EXISTS idx_deeper_events_start_datetime ON deeper_events(start_datetime);
    CREATE INDEX IF NOT EXISTS idx_deeper_events_status ON deeper_events(status);
    CREATE INDEX IF NOT EXISTS idx_deeper_events_visibility ON deeper_events(visibility);
    CREATE INDEX IF NOT EXISTS idx_deeper_events_location ON deeper_events(location_lat, location_lng);
    """

    # Repo.execute("PRAGMA foreign_keys = ON;") -- Se necessário

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_events criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela deeper_events: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela deeper_events.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela deeper_events...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS deeper_events;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_events removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela deeper_events: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end
end
