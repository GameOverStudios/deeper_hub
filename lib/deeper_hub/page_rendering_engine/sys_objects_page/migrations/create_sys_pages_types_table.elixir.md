# Migração Elixir: Criar Tabela `sys_pages_types`

Este módulo de migração Elixir cria a tabela `sys_pages_types` no SQLite. Esta tabela define os tipos gerais de página que podem influenciar o template base de uma página.

## Código da Migração (`lib/deeper/core/data/migrations/page_engine/create_sys_pages_types_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.PageEngine.CreateSysPagesTypesTable do
  @moduledoc \"Migração para criar a tabela sys_pages_types.\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela sys_pages_types...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_pages_types (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      template TEXT NOT NULL,
      \"order\" INTEGER NOT NULL DEFAULT 0
    );
    \"\"\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela sys_pages_types criada com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao criar tabela sys_pages_types: #{inspect(reason)}\", module: __MODULE__)
    end)
  end

  def down do
    Logger.info(\"Removendo tabela sys_pages_types...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_pages_types;\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela sys_pages_types removida com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao remover tabela sys_pages_types: #{inspect(reason)}\", module: __MODULE__)
    end)
  end
end
```