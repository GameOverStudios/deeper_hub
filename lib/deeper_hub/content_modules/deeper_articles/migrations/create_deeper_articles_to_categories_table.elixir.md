# Migração Elixir: Criar Tabela de Junção `deeper_articles_to_categories`

Este módulo de migração Elixir é responsável por criar a tabela de junção `deeper_articles_to_categories` no banco de dados SQLite. Esta tabela estabelece uma relação muitos-para-muitos entre artigos (`deeper_articles`) e categorias (`deeper_article_categories`).

## Código da Migração (`lib/deeper/core/data/migrations/create_deeper_articles_to_categories_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateDeeperArticlesToCategoriesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela de junção deeper_articles_to_categories.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela deeper_articles_to_categories.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela de junção deeper_articles_to_categories...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_articles_to_categories (
      article_id INTEGER NOT NULL,
      category_id INTEGER NOT NULL,
      PRIMARY KEY (article_id, category_id),
      FOREIGN KEY (article_id) REFERENCES deeper_articles(id) ON DELETE CASCADE,
      FOREIGN KEY (category_id) REFERENCES deeper_article_categories(id) ON DELETE CASCADE
    );

    -- Índice para otimizar buscas por categoria_id primeiro, e depois article_id
    CREATE INDEX IF NOT EXISTS idx_datc_category_id_article_id ON deeper_articles_to_categories(category_id, article_id);
    -- O índice da chave primária (article_id, category_id) já otimiza buscas por article_id primeiro.
    \"\"\"

    # Repo.execute(\"PRAGMA foreign_keys = ON;\") -- Se necessário

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela de junção deeper_articles_to_categories criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela de junção deeper_articles_to_categories: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela de junção deeper_articles_to_categories.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela de junção deeper_articles_to_categories...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_articles_to_categories;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela de junção deeper_articles_to_categories removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela de junção deeper_articles_to_categories: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   A chave primária é composta por `(article_id, category_id)`, garantindo que uma combinação específica de artigo e categoria seja única.
*   `ON DELETE CASCADE` em ambas as chaves estrangeiras significa que:
    *   Se um artigo for excluído, todas as suas associações a categorias nesta tabela serão removidas.
    *   Se uma categoria for excluída, todas as associações de artigos a essa categoria nesta tabela serão removidas.
*   Um índice adicional `idx_datc_category_id_article_id` é criado para otimizar queries que buscam todos os artigos de uma determinada categoria. O índice da chave primária já cobre eficientemente a busca de todas as categorias de um determinado artigo.