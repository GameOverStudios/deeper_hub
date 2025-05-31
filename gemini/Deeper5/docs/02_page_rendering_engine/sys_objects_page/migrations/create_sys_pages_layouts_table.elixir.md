# Migração Elixir: Criar Tabela `sys_pages_layouts`

Este módulo de migração Elixir cria a tabela `sys_pages_layouts` no SQLite. Esta tabela define os diferentes layouts (arranjos de colunas/células) disponíveis para as páginas.

## Código da Migração (`lib/deeper/core/data/migrations/page_engine/create_sys_pages_layouts_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.PageEngine.CreateSysPagesLayoutsTable do
  @moduledoc \"Migração para criar a tabela sys_pages_layouts.\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela sys_pages_layouts...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_pages_layouts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      icon TEXT NOT NULL,
      title TEXT NOT NULL,
      template TEXT NOT NULL,
      cells_number INTEGER NOT NULL
    );
    \"\"\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela sys_pages_layouts criada com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao criar tabela sys_pages_layouts: #{inspect(reason)}\", module: __MODULE__)
    end)
  end

  def down do
    Logger.info(\"Removendo tabela sys_pages_layouts...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_pages_layouts;\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela sys_pages_layouts removida com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao remover tabela sys_pages_layouts: #{inspect(reason)}\", module: __MODULE__)
    end)
  end
end
```