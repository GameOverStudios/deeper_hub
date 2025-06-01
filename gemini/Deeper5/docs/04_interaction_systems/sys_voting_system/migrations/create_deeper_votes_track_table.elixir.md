# Migração Elixir: Criar Tabela `deeper_votes_track`

Este módulo de migração Elixir cria a tabela `deeper_votes_track` no SQLite. Esta tabela armazena os votos individuais dados pelos usuários a diferentes objetos no sistema.

## Código da Migração (`lib/deeper/core/data/migrations/interaction_systems/voting/create_deeper_votes_track_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.InteractionSystems.Voting.CreateDeeperVotesTrackTable do
  @moduledoc \"Migração para criar a tabela deeper_votes_track.\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela deeper_votes_track...\", module: __MODULE__)
    # Repo.execute(\"PRAGMA foreign_keys = ON;\")
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_votes_track (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      system_name TEXT NOT NULL,
      object_id INTEGER NOT NULL,
      voter_profile_id INTEGER NOT NULL,
      value INTEGER NOT NULL,
      voted_at INTEGER NOT NULL,
      ip_address TEXT,
      UNIQUE (system_name, object_id, voter_profile_id),
      FOREIGN KEY (voter_profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_dvt_system_object ON deeper_votes_track(system_name, object_id);
    CREATE INDEX IF NOT EXISTS idx_dvt_voter ON deeper_votes_track(voter_profile_id);
    \"\"\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_votes_track criada com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao criar tabela deeper_votes_track: #{inspect(reason)}\", module: __MODULE__)
    end)
  end

  def down do
    Logger.info(\"Removendo tabela deeper_votes_track...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_votes_track;\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_votes_track removida com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao remover tabela deeper_votes_track: #{inspect(reason)}\", module: __MODULE__)
    end)
  end
end
```