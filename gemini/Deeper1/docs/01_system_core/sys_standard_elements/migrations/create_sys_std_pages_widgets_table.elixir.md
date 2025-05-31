# Migração Elixir: Criar Tabela `sys_std_pages_widgets`

Este módulo de migração Elixir cria a tabela `sys_std_pages_widgets` no SQLite, uma tabela de junção que define quais widgets (`sys_std_widgets`) são exibidos em quais páginas padrão (`sys_std_pages`) e sua ordem.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_std_pages_widgets_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysStdPagesWidgetsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_std_pages_widgets.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_std_pages_widgets...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_std_pages_widgets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      page_id INTEGER NOT NULL, -- FK para sys_std_pages.id
      widget_id INTEGER NOT NULL, -- FK para sys_std_widgets.id
      \"order\" INTEGER NOT NULL DEFAULT 0,
      UNIQUE(page_id, widget_id)
      -- FOREIGN KEY (page_id) REFERENCES sys_std_pages(id) ON DELETE CASCADE,
      -- FOREIGN KEY (widget_id) REFERENCES sys_std_widgets(id) ON DELETE CASCADE
    );
    CREATE INDEX IF NOT EXISTS idx_sys_std_pw_page_order ON sys_std_pages_widgets(page_id, \"order\");
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_std_pages_widgets...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_std_pages_widgets;\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
```