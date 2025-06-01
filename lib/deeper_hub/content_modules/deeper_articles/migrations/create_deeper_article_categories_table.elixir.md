# Migração Elixir: Criar Tabela `deeper_article_categories`

Este módulo de migração Elixir é responsável por criar a tabela `deeper_article_categories` no banco de dados SQLite. Esta tabela define as categorias que podem ser associadas aos artigos/posts.

## Código da Migração (`lib/deeper/core/data/migrations/create_deeper_article_categories_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateDeeperArticleCategoriesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela deeper_article_categories.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela deeper_article_categories.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela deeper_article_categories...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_article_categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      slug TEXT NOT NULL UNIQUE,
      description TEXT,
      parent_id INTEGER,
      FOREIGN KEY (parent_id) REFERENCES deeper_article_categories(id) ON DELETE SET NULL -- ou ON DELETE CASCADE se subcategorias devem ser removidas
    );

    CREATE INDEX IF NOT EXISTS idx_deeper_article_categories_slug ON deeper_article_categories(slug);
    CREATE INDEX IF NOT EXISTS idx_deeper_article_categories_parent_id ON deeper_article_categories(parent_id);
    \"\"\"

    # Repo.execute(\"PRAGMA foreign_keys = ON;\") -- Se necessário

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_article_categories criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela deeper_article_categories: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela deeper_article_categories.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela deeper_article_categories...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_article_categories;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_article_categories removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela deeper_article_categories: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   Tanto `name` quanto `slug` da categoria são `UNIQUE`.
*   `parent_id` permite a criação de hierarquias de categorias (categorias pais e filhas). A chave estrangeira aponta para a própria tabela.
    *   `ON DELETE SET NULL`: Se uma categoria pai for excluída, suas categorias filhas terão `parent_id` definido como `NULL`, tornando-as categorias de nível superior.
    *   `ON DELETE CASCADE`: Se uma categoria pai for excluída, todas as suas categorias filhas também seriam excluídas. A escolha depende do comportamento desejado.