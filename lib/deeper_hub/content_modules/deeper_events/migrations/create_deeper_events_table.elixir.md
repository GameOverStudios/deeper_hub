# Migração Elixir: Criar Tabela `deeper_events`

Este módulo de migração Elixir é responsável por criar a tabela `deeper_events` no banco de dados SQLite. Esta tabela armazena todas as informações principais sobre os eventos criados no sistema.

## Código da Migração (`lib/deeper/core/data/migrations/create_deeper_events_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateDeeperEventsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela deeper_events.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela deeper_events.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela deeper_events...\", module: __MODULE__)

    sql = \"\"\"
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
    \"\"\"

    # Repo.execute(\"PRAGMA foreign_keys = ON;\") -- Se necessário

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_events criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela deeper_events: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela deeper_events.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela deeper_events...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_events;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_events removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela deeper_events: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   Esta tabela depende da existência de `sys_profiles` (para `profile_id` do organizador) e `deeper_files` (para `banner_file_id`). As migrações devem ser ordenadas corretamente.
*   `ON DELETE CASCADE` para `profile_id` significa que se o perfil do organizador for excluído, seus eventos também serão. Isso pode ser uma decisão de negócios importante.
*   Índices são adicionados para colunas comuns de filtro e ordenação. Um índice geoespacial (`idx_deeper_events_location`) é sugerido, mas sua eficácia e necessidade dependem do uso de consultas baseadas em localização e das capacidades do SQLite (pode exigir extensões R*Tree).