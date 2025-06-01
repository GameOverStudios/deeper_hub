# Migração Elixir: Criar Tabela `deeper_report_types` (Opcional)

Este módulo de migração Elixir cria a tabela `deeper_report_types` no SQLite. Esta tabela é opcional e pode ser usada para gerenciar os tipos de denúncia disponíveis no sistema de forma dinâmica.

## Código da Migração (`lib/deeper/core/data/migrations/interaction_systems/reporting/create_deeper_report_types_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.InteractionSystems.Reporting.CreateDeeperReportTypesTable do
  @moduledoc \"Migração para criar a tabela deeper_report_types.\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela deeper_report_types...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_report_types (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type_key TEXT NOT NULL UNIQUE,
      title_lkey TEXT NOT NULL,
      description_lkey TEXT,
      active INTEGER NOT NULL DEFAULT 1,
      \"order\" INTEGER NOT NULL DEFAULT 0
    );
    \"\"\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_report_types criada com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao criar tabela deeper_report_types: #{inspect(reason)}\", module: __MODULE__)
    end)
  end

  def down do
    Logger.info(\"Removendo tabela deeper_report_types...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_report_types;\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_report_types removida com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao remover tabela deeper_report_types: #{inspect(reason)}\", module: __MODULE__)
    end)
  end
end
```