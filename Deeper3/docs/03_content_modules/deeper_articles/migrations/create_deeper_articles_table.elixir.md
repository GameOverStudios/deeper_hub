# Migração Elixir: Criar Tabela `deeper_articles`

Este módulo de migração Elixir é responsável por criar a tabela `deeper_articles` no banco de dados SQLite. Esta tabela armazena o conteúdo principal, título, autor e outros metadados de artigos ou posts.

## Código da Migração (`lib/deeper/core/data/migrations/create_deeper_articles_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateDeeperArticlesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela deeper_articles.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela deeper_articles.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela deeper_articles...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_articles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      profile_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      slug TEXT NOT NULL UNIQUE,
      body TEXT NOT NULL,
      excerpt TEXT,
      featured_image_file_id INTEGER,
      status TEXT NOT NULL DEFAULT 'draft' CHECK(status IN ('draft', 'published', 'archived', 'pending_review')),
      visibility TEXT NOT NULL DEFAULT 'public',
      allow_comments INTEGER NOT NULL DEFAULT 1,
      published_at INTEGER,
      views INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL,
      FOREIGN KEY (featured_image_file_id) REFERENCES deeper_files(id) ON DELETE SET NULL
    );

    CREATE INDEX IF NOT EXISTS idx_deeper_articles_profile_id ON deeper_articles(profile_id);
    CREATE INDEX IF NOT EXISTS idx_deeper_articles_slug ON deeper_articles(slug);
    CREATE INDEX IF NOT EXISTS idx_deeper_articles_status ON deeper_articles(status);
    CREATE INDEX IF NOT EXISTS idx_deeper_articles_published_at ON deeper_articles(published_at);
    CREATE INDEX IF NOT EXISTS idx_deeper_articles_created_at ON deeper_articles(created_at);
    \"\"\"

    # Repo.execute(\"PRAGMA foreign_keys = ON;\") -- Se necessário

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_articles criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela deeper_articles: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela deeper_articles.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela deeper_articles...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_articles;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_articles removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela deeper_articles: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   Esta tabela depende da existência de `sys_profiles` (para `profile_id`) e `deeper_files` (para `featured_image_file_id`). As migrações devem ser executadas em uma ordem que respeite essas dependências.
*   Índices são criados para colunas frequentemente usadas em filtros ou ordenação.
*   A coluna `slug` é `UNIQUE` para garantir URLs amigáveis únicas.