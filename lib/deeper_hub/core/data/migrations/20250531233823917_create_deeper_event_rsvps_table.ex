# Migração gerada com ID único: V1748745503916 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateDeeperEventRsvpsTable do
  # Migração gerada com ID único: V1748745503916 em 2025-05-31 23:38:23
  @moduledoc """
  Migração para criar a tabela deeper_event_rsvps.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela deeper_event_rsvps.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela deeper_event_rsvps...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS deeper_event_rsvps (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      event_id INTEGER NOT NULL,
      profile_id INTEGER NOT NULL,
      rsvp_status TEXT NOT NULL CHECK(rsvp_status IN ('yes', 'no', 'maybe')),
      comment TEXT,
      guests_count INTEGER NOT NULL DEFAULT 0,
      rsvped_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      UNIQUE (event_id, profile_id),
      FOREIGN KEY (event_id) REFERENCES deeper_events(id) ON DELETE CASCADE,
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_deeper_event_rsvps_event_id_status ON deeper_event_rsvps(event_id, rsvp_status);
    CREATE INDEX IF NOT EXISTS idx_deeper_event_rsvps_profile_id ON deeper_event_rsvps(profile_id);
    """

    # Repo.execute("PRAGMA foreign_keys = ON;") -- Se necessário

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_event_rsvps criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela deeper_event_rsvps: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela deeper_event_rsvps.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela deeper_event_rsvps...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS deeper_event_rsvps;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_event_rsvps removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela deeper_event_rsvps: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end
end
