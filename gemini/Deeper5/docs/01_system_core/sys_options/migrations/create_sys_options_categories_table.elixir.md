# Migração Elixir: Criar Tabela `sys_options_categories`

Este módulo de migração Elixir cria a tabela `sys_options_categories` no SQLite. Esta tabela define categorias de configurações, agrupadas sob um `sys_options_types`.

## Código da Migração (`lib/deeper/core/data/migrations/options/create_sys_options_categories_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.Options.CreateSysOptionsCategoriesTable do
  @moduledoc \"Migração para criar a tabela sys_options_categories.\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela sys_options_categories...\", module: __MODULE__)
    # Repo.execute(\"PRAGMA foreign_keys = ON;\") # Garantir que FKs estão ativas
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_options_categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type_id INTEGER NOT NULL,
      name TEXT NOT NULL UNIQUE,
      caption TEXT NOT NULL,
      hidden INTEGER NOT NULL DEFAULT 0,
      \"order\" INTEGER DEFAULT 0,
      FOREIGN KEY (type_id) REFERENCES sys_options_types(id) ON DELETE CASCADE ON UPDATE CASCADE
    );
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok; {:error, reason} -> {:error, reason}
    end
    |> tap(fn
      :ok -> Logger.info(\"Tabela sys_options_categories criada com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao criar tabela sys_options_categories: #{inspect(reason)}\", module: __MODULE__)
    end)
  end

  def down do
    Logger.info(\"Removendo tabela sys_options_categories...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_options_categories;\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok; {:error, reason} -> {:error, reason}
    end
    |> tap(fn
      :ok -> Logger.info(\"Tabela sys_options_categories removida com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao remover tabela sys_options_categories: #{inspect(reason)}\", module: __MODULE__)
    end)
  end
end
```