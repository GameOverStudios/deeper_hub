# Migração Elixir: Criar Tabela `deeper_object_reactions_summary` (Opcional)

Este módulo de migração Elixir cria a tabela `deeper_object_reactions_summary` no SQLite. Esta tabela é opcional e serve para armazenar contagens agregadas de cada tipo de reação para cada objeto.

## Código da Migração (`lib/deeper/core/data/migrations/interaction_systems/reactions/create_deeper_object_reactions_summary_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.InteractionSystems.Reactions.CreateDeeperObjectReactionsSummaryTable do
  @moduledoc \"Migração para criar a tabela deeper_object_reactions_summary.\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela deeper_object_reactions_summary...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_object_reactions_summary (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      system_name TEXT NOT NULL,
      object_id INTEGER NOT NULL,
      reaction_type_key TEXT NOT NULL,
      reaction_count INTEGER NOT NULL DEFAULT 0,
      UNIQUE (system_name, object_id, reaction_type_key)
      -- FOREIGN KEY (reaction_type_key) REFERENCES deeper_reaction_types(reaction_key) ON UPDATE CASCADE -- Se deeper_reaction_types existir
    );

    CREATE INDEX IF NOT EXISTS idx_dors_system_object ON deeper_object_reactions_summary(system_name, object_id);
    \"\"\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_object_reactions_summary criada com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao criar tabela deeper_object_reactions_summary: #{inspect(reason)}\", module: __MODULE__)
    end)
  end

  def down do
    Logger.info(\"Removendo tabela deeper_object_reactions_summary...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_object_reactions_summary;\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_object_reactions_summary removida com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao remover tabela deeper_object_reactions_summary: #{inspect(reason)}\", module: __MODULE__)
    end)
  end
end
```