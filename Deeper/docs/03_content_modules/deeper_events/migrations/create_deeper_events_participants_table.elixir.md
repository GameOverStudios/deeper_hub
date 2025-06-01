# Migração Elixir: Criar Tabela `deeper_events_participants`

Este módulo de migração Elixir é responsável por criar a tabela `deeper_events_participants` no banco de dados SQLite. Esta tabela registra quais perfis estão participando ou interessados em eventos específicos.

## Código da Migração (`lib/deeper/core/data/migrations/create_deeper_events_participants_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateDeeperEventsParticipantsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela deeper_events_participants.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela deeper_events_participants...\", module: __MODULE__)

    # Repo.execute(\"PRAGMA foreign_keys = ON;\") # Se necessário

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_events_participants (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      event_id INTEGER NOT NULL,
      profile_id INTEGER NOT NULL,
      rsvp_status TEXT NOT NULL CHECK(rsvp_status IN ('attending', 'interested', 'not_attending')),
      added_at INTEGER NOT NULL,

      UNIQUE (event_id, profile_id),
      FOREIGN KEY (event_id) REFERENCES deeper_events_entries(id) ON DELETE CASCADE,
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_deeper_events_participants_event_id_status ON deeper_events_participants(event_id, rsvp_status);
    CREATE INDEX IF NOT EXISTS idx_deeper_events_participants_profile_id_event_id ON deeper_events_participants(profile_id, event_id);
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_events_participants criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela deeper_events_participants: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  def down do
    Logger.info(\"Removendo tabela deeper_events_participants...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_events_participants;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_events_participants removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela deeper_events_participants: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

**Nota:** Assegure-se de que as tabelas `deeper_events_entries` e `sys_profiles` já existam antes de executar a migração `up/0` para `deeper_events_participants`.