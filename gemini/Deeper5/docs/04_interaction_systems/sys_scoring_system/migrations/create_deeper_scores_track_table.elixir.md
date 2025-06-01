# Migração Elixir: Criar Tabela `deeper_scores_track`

Este módulo de migração Elixir cria a tabela `deeper_scores_track` no SQLite. Esta tabela armazena os votos de pontuação (upvotes/downvotes) dados pelos usuários a diferentes objetos no sistema.

## Código da Migração (`lib/deeper/core/data/migrations/interaction_systems/scoring/create_deeper_scores_track_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.InteractionSystems.Scoring.CreateDeeperScoresTrackTable do
  @moduledoc \"Migração para criar a tabela deeper_scores_track.\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela deeper_scores_track...\", module: __MODULE__)
    # Repo.execute(\"PRAGMA foreign_keys = ON;\")
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_scores_track (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      system_name TEXT NOT NULL,
      object_id INTEGER NOT NULL,
      voter_profile_id INTEGER NOT NULL,
      type TEXT NOT NULL CHECK(type IN ('up', 'down')),
      voted_at INTEGER NOT NULL,
      ip_address TEXT,
      UNIQUE (system_name, object_id, voter_profile_id),
      FOREIGN KEY (voter_profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_dsct_system_object ON deeper_scores_track(system_name, object_id);
    CREATE INDEX IF NOT EXISTS idx_dsct_voter ON deeper_scores_track(voter_profile_id);
    \"\"\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_scores_track criada com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao criar tabela deeper_scores_track: #{inspect(reason)}\", module: __MODULE__)
    end)
  end

  def down do
    Logger.info(\"Removendo tabela deeper_scores_track...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_scores_track;\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_scores_track removida com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao remover tabela deeper_scores_track: #{inspect(reason)}\", module: __MODULE__)
    end)
  end
end
```