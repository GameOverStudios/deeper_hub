# Migração Elixir: Criar Tabela `deeper_groups_categories`

Cria a tabela para categorias de grupos.

## Código da Migração (`lib/deeper/core/data/migrations/create_deeper_groups_categories_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateDeeperGroupsCategoriesTable do
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela deeper_groups_categories...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_groups_categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      parent_id INTEGER DEFAULT 0,
      name TEXT NOT NULL UNIQUE,
      title_lang_key TEXT,
      \"order\" INTEGER DEFAULT 0
    );
    CREATE INDEX IF NOT EXISTS idx_deeper_groups_categories_parent_id ON deeper_groups_categories(parent_id);
    \"\"\"
    Repo.execute(sql) # Omitindo tratamento de erro para brevidade aqui, mas deve existir
  end

  def down do
    Logger.info(\"Removendo tabela deeper_groups_categories...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_groups_categories;\"
    Repo.execute(sql)
  end
end
```