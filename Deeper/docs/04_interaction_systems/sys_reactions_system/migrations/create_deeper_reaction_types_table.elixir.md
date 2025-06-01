# Migração Elixir: Criar Tabela `deeper_reaction_types` (Opcional)

Este módulo de migração Elixir cria a tabela `deeper_reaction_types` no SQLite. Esta tabela é opcional e serve para definir os tipos de reação disponíveis de forma dinâmica.

## Código da Migração (`lib/deeper/core/data/migrations/interaction_systems/reactions/create_deeper_reaction_types_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.InteractionSystems.Reactions.CreateDeeperReactionTypesTable do
  @moduledoc \"Migração para criar a tabela deeper_reaction_types.\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela deeper_reaction_types...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_reaction_types (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      reaction_key TEXT NOT NULL UNIQUE,
      title_lkey TEXT NOT NULL,
      icon_class TEXT,
      color_hex TEXT,
      is_positive INTEGER DEFAULT 1,
      \"order\" INTEGER NOT NULL DEFAULT 0,
      active INTEGER NOT NULL DEFAULT 1
    );
    \"\"\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_reaction_types criada com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao criar tabela deeper_reaction_types: #{inspect(reason)}\", module: __MODULE__)
    end)
  end

  def down do
    Logger.info(\"Removendo tabela deeper_reaction_types...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_reaction_types;\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_reaction_types removida com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao remover tabela deeper_reaction_types: #{inspect(reason)}\", module: __MODULE__)
    end)
  end
end
```