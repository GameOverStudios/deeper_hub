# Migração Elixir: Criar Tabela `deeper_event_rsvps`

Este módulo de migração Elixir é responsável por criar a tabela `deeper_event_rsvps` no banco de dados SQLite. Esta tabela registra as respostas de participação (RSVP - Répondez S'il Vous Plaît) dos usuários para os eventos.

## Código da Migração (`lib/deeper/core/data/migrations/create_deeper_event_rsvps_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateDeeperEventRsvpsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela deeper_event_rsvps.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela deeper_event_rsvps.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela deeper_event_rsvps...\", module: __MODULE__)

    sql = \"\"\"
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
    \"\"\"

    # Repo.execute(\"PRAGMA foreign_keys = ON;\") -- Se necessário

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_event_rsvps criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela deeper_event_rsvps: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela deeper_event_rsvps.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela deeper_event_rsvps...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_event_rsvps;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_event_rsvps removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela deeper_event_rsvps: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   Esta tabela depende da existência de `deeper_events` (para `event_id`) e `sys_profiles` (para `profile_id`).
*   A constraint `UNIQUE (event_id, profile_id)` garante que cada perfil de usuário possa ter apenas uma entrada de RSVP por evento. Para alterar um RSVP, uma operação `UPDATE` seria usada nesta tabela.
*   `ON DELETE CASCADE` para `event_id`: Se um evento for excluído, todos os RSVPs associados a ele são automaticamente removidos.
*   `ON DELETE CASCADE` para `profile_id`: Se um perfil de usuário for excluído, todos os seus RSVPs são automaticamente removidos.
*   Índices são criados para otimizar a busca de RSVPs por evento e status, e por perfil de participante.