# Migração Elixir: Criar Tabela `deeper_reports_track`

Este módulo de migração Elixir cria a tabela `deeper_reports_track` no SQLite. Esta tabela armazena as denúncias individuais feitas pelos usuários sobre diferentes objetos no sistema.

## Código da Migração (`lib/deeper/core/data/migrations/interaction_systems/reporting/create_deeper_reports_track_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.InteractionSystems.Reporting.CreateDeeperReportsTrackTable do
  @moduledoc \"Migração para criar a tabela deeper_reports_track.\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela deeper_reports_track...\", module: __MODULE__)
    # Repo.execute(\"PRAGMA foreign_keys = ON;\")
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_reports_track (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      system_name TEXT NOT NULL,
      object_id INTEGER NOT NULL,
      reporter_profile_id INTEGER NOT NULL,
      -- report_type_id INTEGER, -- Se usar a tabela deeper_report_types
      report_type_key TEXT NOT NULL,
      comment TEXT,
      status TEXT NOT NULL DEFAULT 'new' CHECK(status IN ('new', 'pending_review', 'acknowledged', 'resolved_action_taken', 'resolved_no_action', 'rejected')),
      reported_at INTEGER NOT NULL,
      checked_by_admin_profile_id INTEGER,
      checked_at INTEGER,
      admin_notes TEXT,
      FOREIGN KEY (reporter_profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (checked_by_admin_profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL ON UPDATE CASCADE
      -- FOREIGN KEY (report_type_id) REFERENCES deeper_report_types(id) ON DELETE RESTRICT ON UPDATE CASCADE -- Se usar
      -- UNIQUE constraint pode ser adicionada aqui dependendo da política (ex: UNIQUE(system_name, object_id, reporter_profile_id, report_type_key))
    );

    CREATE INDEX IF NOT EXISTS idx_drpt_system_object_status ON deeper_reports_track(system_name, object_id, status);
    CREATE INDEX IF NOT EXISTS idx_drpt_reporter ON deeper_reports_track(reporter_profile_id);
    CREATE INDEX IF NOT EXISTS idx_drpt_status_reported_at ON deeper_reports_track(status, reported_at);
    CREATE UNIQUE INDEX IF NOT EXISTS uidx_drpt_unique_report ON deeper_reports_track(system_name, object_id, reporter_profile_id, report_type_key);
    \"\"\"
    # Adicionada a constraint UNIQUE como exemplo.
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_reports_track criada com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao criar tabela deeper_reports_track: #{inspect(reason)}\", module: __MODULE__)
    end)
  end

  def down do
    Logger.info(\"Removendo tabela deeper_reports_track...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_reports_track;\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_reports_track removida com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao remover tabela deeper_reports_track: #{inspect(reason)}\", module: __MODULE__)
    end)
  end
end
```