# Migração Elixir: Criar Tabela `deeper_reactions_track`

Este módulo de migração Elixir cria a tabela `deeper_reactions_track` no SQLite. Esta tabela armazena as reações individuais dadas pelos usuários a diferentes objetos.

## Código da Migração (`lib/deeper/core/data/migrations/interaction_systems/reactions/create_deeper_reactions_track_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.InteractionSystems.Reactions.CreateDeeperReactionsTrackTable do
  @moduledoc \"Migração para criar a tabela deeper_reactions_track.\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela deeper_reactions_track...\", module: __MODULE__)
    # Repo.execute(\"PRAGMA foreign_keys = ON;\")
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_reactions_track (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      system_name TEXT NOT NULL,
      object_id INTEGER NOT NULL,
      reactor_profile_id INTEGER NOT NULL,
      reaction_type_key TEXT NOT NULL,
      reacted_at INTEGER NOT NULL,
      ip_address TEXT,
      UNIQUE (system_name, object_id, reactor_profile_id),
      FOREIGN KEY (reactor_profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
      -- FOREIGN KEY (reaction_type_key) REFERENCES deeper_reaction_types(reaction_key) ON UPDATE CASCADE -- Se deeper_reaction_types existir
    );

    CREATE INDEX IF NOT EXISTS idx_dreactt_system_object_type ON deeper_reactions_track(system_name, object_id, reaction_type_key);
    CREATE INDEX IF NOT EXISTS idx_dreactt_reactor ON deeper_reactions_track(reactor_profile_id);
    \"\"\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_reactions_track criada com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao criar tabela deeper_reactions_track: #{inspect(reason)}\", module: __MODULE__)
    end)
  end

  def down do
    Logger.info(\"Removendo tabela deeper_reactions_track...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_reactions_track;\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_reactions_track removida com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao remover tabela deeper_reactions_track: #{inspect(reason)}\", module: __MODULE__)
    end)
  end
end
```