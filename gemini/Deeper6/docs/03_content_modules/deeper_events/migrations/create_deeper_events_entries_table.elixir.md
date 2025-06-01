# Migração Elixir: Criar Tabela `deeper_events_entries`

Este módulo de migração Elixir é responsável por criar a tabela `deeper_events_entries` no banco de dados SQLite. Esta é a tabela principal para armazenar informações detalhadas sobre os eventos.

## Código da Migração (`lib/deeper/core/data/migrations/create_deeper_events_entries_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateDeeperEventsEntriesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela deeper_events_entries.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela deeper_events_entries...\", module: __MODULE__)

    # Habilitar chaves estrangeiras para esta sessão de conexão se não for global
    # Repo.execute(\"PRAGMA foreign_keys = ON;\")

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_events_entries (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      author_profile_id INTEGER NOT NULL,
      category_id INTEGER,
      title TEXT NOT NULL,
      description TEXT,
      cover_image_file_id INTEGER,
      event_url TEXT,
      start_datetime INTEGER NOT NULL,
      end_datetime INTEGER NOT NULL,
      timezone TEXT,
      location_type TEXT DEFAULT 'physical' CHECK(location_type IN ('physical', 'online', 'tbd')),
      location_venue_name TEXT,
      location_address TEXT,
      location_city TEXT,
      location_state TEXT,
      location_country TEXT,
      location_zip TEXT,
      location_lat REAL,
      location_lng REAL,
      location_online_url TEXT,
      max_participants INTEGER DEFAULT 0,
      allow_rsvp INTEGER DEFAULT 1,
      rsvp_deadline INTEGER,
      participants_count INTEGER DEFAULT 0,
      interested_count INTEGER DEFAULT 0,
      views_count INTEGER DEFAULT 0,
      favorites_count INTEGER DEFAULT 0,
      comments_count INTEGER DEFAULT 0,
      score_up_count INTEGER DEFAULT 0,
      score_down_count INTEGER DEFAULT 0,
      status TEXT DEFAULT 'active' CHECK(status IN ('active', 'pending_approval', 'cancelled', 'draft', 'past')),
      visibility_group_id TEXT DEFAULT '3',
      featured INTEGER DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,

      FOREIGN KEY (author_profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
      FOREIGN KEY (category_id) REFERENCES deeper_events_categories(id) ON DELETE SET NULL
      -- FOREIGN KEY (cover_image_file_id) REFERENCES deeper_files(id) ON DELETE SET NULL -- Adicionar quando deeper_files existir
    );

    CREATE INDEX IF NOT EXISTS idx_deeper_events_entries_author ON deeper_events_entries(author_profile_id);
    CREATE INDEX IF NOT EXISTS idx_deeper_events_entries_category ON deeper_events_entries(category_id);
    CREATE INDEX IF NOT EXISTS idx_deeper_events_entries_start_datetime ON deeper_events_entries(start_datetime);
    CREATE INDEX IF NOT EXISTS idx_deeper_events_entries_status ON deeper_events_entries(status);
    CREATE INDEX IF NOT EXISTS idx_deeper_events_entries_location_city_state ON deeper_events_entries(location_city, location_state);
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_events_entries criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela deeper_events_entries: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  def down do
    Logger.info(\"Removendo tabela deeper_events_entries...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_events_entries;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_events_entries removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela deeper_events_entries: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

**Nota:** Assegure-se de que as tabelas `sys_profiles` e `deeper_events_categories` já existam antes de executar a migração `up/0` para `deeper_events_entries` para que as chaves estrangeiras sejam criadas corretamente.