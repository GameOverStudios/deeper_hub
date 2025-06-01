# Migração Elixir: Criar Tabela `deeper_articles_tags`

Este módulo de migração Elixir cria a tabela `deeper_articles_tags` no SQLite, utilizada para armazenar as tags que podem ser associadas aos artigos.

## Código da Migração (`lib/deeper/core/data/migrations/content/articles/create_deeper_articles_tags_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.Content.Articles.CreateDeeperArticlesTagsTable do
  @moduledoc \"Migração para criar a tabela deeper_articles_tags.\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela deeper_articles_tags...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_articles_tags (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      slug TEXT NOT NULL UNIQUE,
      item_count INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    );
    \"\"\"
    # Índices em name e slug são criados pelas constraints UNIQUE.
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_articles_tags criada com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao criar tabela deeper_articles_tags: #{inspect(reason)}\", module: __MODULE__)
    end)
  end

  def down do
    Logger.info(\"Removendo tabela deeper_articles_tags...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_articles_tags;\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_articles_tags removida com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao remover tabela deeper_articles_tags: #{inspect(reason)}\", module: __MODULE__)
    end)
  end
end
```