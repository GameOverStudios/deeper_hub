# Migração Elixir: Criar Tabela `sys_localization_categories`

Este módulo de migração Elixir cria a tabela `sys_localization_categories` no SQLite, usada para categorizar as chaves de tradução.

## Código da Migração (`lib/deeper/core/data/migrations/localization/create_sys_localization_categories_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.Localization.CreateSysLocalizationCategoriesTable do
  @moduledoc \"Migração para criar a tabela sys_localization_categories.\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela sys_localization_categories...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_localization_categories (
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      Name TEXT NOT NULL UNIQUE
    );
    \"\"\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela sys_localization_categories criada com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao criar tabela sys_localization_categories: #{inspect(reason)}\", module: __MODULE__)
    end)
  end

  def down do
    Logger.info(\"Removendo tabela sys_localization_categories...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_localization_categories;\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela sys_localization_categories removida com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao remover tabela sys_localization_categories: #{inspect(reason)}\", module: __MODULE__)
    end)
  end
end
```