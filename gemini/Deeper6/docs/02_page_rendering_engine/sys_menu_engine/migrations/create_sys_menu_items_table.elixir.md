# Migração Elixir: Criar Tabela `sys_menu_items`

Este módulo de migração Elixir é responsável por criar a tabela `sys_menu_items` no banco de dados SQLite. Esta tabela contém os itens individuais que compõem cada menu.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_menu_items_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysMenuItemsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_menu_items.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela sys_menu_items...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_menu_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      parent_id INTEGER NOT NULL DEFAULT 0,
      set_name TEXT NOT NULL,
      module TEXT NOT NULL,
      name TEXT NOT NULL,
      title_system TEXT,
      title TEXT NOT NULL,
      link TEXT NOT NULL,
      onclick TEXT,
      target TEXT,
      icon TEXT,
      addon TEXT,
      submenu_object TEXT,
      submenu_popup INTEGER NOT NULL DEFAULT 0,
      visible_for_levels INTEGER NOT NULL DEFAULT 2147483647,
      hidden_on TEXT,
      active INTEGER NOT NULL DEFAULT 1,
      \"order\" INTEGER NOT NULL,
      FOREIGN KEY (set_name) REFERENCES sys_menu_sets(set_name) ON UPDATE CASCADE ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_sys_menu_items_set_name_parent_id ON sys_menu_items(set_name, parent_id);
    CREATE INDEX IF NOT EXISTS idx_sys_menu_items_set_name_active_order ON sys_menu_items(set_name, active, \"order\");
    CREATE UNIQUE INDEX IF NOT EXISTS idx_sys_menu_items_set_name_name ON sys_menu_items(set_name, name);
    \"\"\"
    # Repo.execute(\"PRAGMA foreign_keys = ON;\") # Se necessário

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_menu_items criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_menu_items: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  def down do
    Logger.info(\"Removendo tabela sys_menu_items...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_menu_items;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_menu_items removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_menu_items: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

**Nota sobre `order`:** A coluna `order` está entre aspas (`\"order\"`) porque `ORDER` é uma palavra reservada do SQL. SQLite permite isso, mas é uma boa prática para evitar conflitos.