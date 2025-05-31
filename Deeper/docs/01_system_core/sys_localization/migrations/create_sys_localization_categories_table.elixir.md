# Migração Elixir: Criar Tabela `sys_localization_categories`

Este módulo de migração Elixir cria a tabela `sys_localization_categories` no SQLite, usada para agrupar chaves de tradução.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_localization_categories_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysLocalizationCategoriesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_localization_categories.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_localization_categories...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_localization_categories (
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      Name TEXT NOT NULL UNIQUE -- Nome da categoria, ex: 'System', 'Accounts', 'BxPersons'
    );
    CREATE INDEX IF NOT EXISTS idx_sys_loc_cat_name ON sys_localization_categories(Name);
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_localization_categories...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_localization_categories;\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
```