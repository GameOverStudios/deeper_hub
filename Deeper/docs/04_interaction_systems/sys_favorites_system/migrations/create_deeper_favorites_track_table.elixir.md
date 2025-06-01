# Migração Elixir: Criar Tabela `deeper_favorites_track`

Este módulo de migração Elixir cria a tabela `deeper_favorites_track` no SQLite. Esta tabela armazena as marcações de \"favorito\" feitas pelos usuários em diferentes objetos no sistema.

## Código da Migração (`lib/deeper/core/data/migrations/interaction_systems/favorites/create_deeper_favorites_track_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.InteractionSystems.Favorites.CreateDeeperFavoritesTrackTable do
  @moduledoc \"Migração para criar a tabela deeper_favorites_track.\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela deeper_favorites_track...\", module: __MODULE__)
    # Repo.execute(\"PRAGMA foreign_keys = ON;\")
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_favorites_track (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      system_name TEXT NOT NULL,
      object_id INTEGER NOT NULL,
      fan_profile_id INTEGER NOT NULL,
      favorited_at INTEGER NOT NULL,
      UNIQUE (system_name, object_id, fan_profile_id),
      FOREIGN KEY (fan_profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_dfavt_system_object ON deeper_favorites_track(system_name, object_id);
    CREATE INDEX IF NOT EXISTS idx_dfavt_fan_profile ON deeper_favorites_track(fan_profile_id, system_name);
    \"\"\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_favorites_track criada com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao criar tabela deeper_favorites_track: #{inspect(reason)}\", module: __MODULE__)
    end)
  end

  def down do
    Logger.info(\"Removendo tabela deeper_favorites_track...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_favorites_track;\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_favorites_track removida com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao remover tabela deeper_favorites_track: #{inspect(reason)}\", module: __MODULE__)
    end)
  end
end
```