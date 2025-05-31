# Migração Elixir: Criar Tabela `deeper_articles_tags_to_entries`

Este módulo de migração Elixir cria a tabela de junção `deeper_articles_tags_to_entries` no SQLite. Esta tabela gerencia o relacionamento muitos-para-muitos entre artigos (`deeper_articles_entries`) e tags (`deeper_articles_tags`).

## Código da Migração (`lib/deeper/core/data/migrations/content/articles/create_deeper_articles_tags_to_entries_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.Content.Articles.CreateDeeperArticlesTagsToEntriesTable do
  @moduledoc \"Migração para criar a tabela de junção deeper_articles_tags_to_entries.\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela deeper_articles_tags_to_entries...\", module: __MODULE__)
    # Repo.execute(\"PRAGMA foreign_keys = ON;\")
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_articles_tags_to_entries (
      tag_id INTEGER NOT NULL,
      entry_id INTEGER NOT NULL,
      PRIMARY KEY (tag_id, entry_id),
      FOREIGN KEY (tag_id) REFERENCES deeper_articles_tags(id) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (entry_id) REFERENCES deeper_articles_entries(id) ON DELETE CASCADE ON UPDATE CASCADE
    );
    -- Índices separados em tag_id e entry_id podem ser úteis para buscas.
    -- O índice da PK já cobre (tag_id, entry_id).
    CREATE INDEX IF NOT EXISTS idx_datte_entry_id ON deeper_articles_tags_to_entries(entry_id);
    -- CREATE INDEX IF NOT EXISTS idx_datte_tag_id ON deeper_articles_tags_to_entries(tag_id); (coberto pela PK)
    \"\"\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_articles_tags_to_entries criada com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao criar tabela deeper_articles_tags_to_entries: #{inspect(reason)}\", module: __MODULE__)
    end)
  end

  def down do
    Logger.info(\"Removendo tabela deeper_articles_tags_to_entries...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_articles_tags_to_entries;\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_articles_tags_to_entries removida com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao remover tabela deeper_articles_tags_to_entries: #{inspect(reason)}\", module: __MODULE__)
    end)
  end
end
```