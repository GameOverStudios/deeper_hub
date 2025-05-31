# Migração Elixir: Criar Tabela `sys_menu_items`

Este módulo de migração Elixir é responsável por criar a tabela `sys_menu_items` no banco de dados SQLite. Esta tabela armazena os itens individuais que compõem cada menu (conjunto de menu), incluindo seus títulos, links, ícones, ordem e configurações de visibilidade.

**Dependências:** Esta tabela possui uma chave estrangeira para `sys_menu_sets`.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_menu_items_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysMenuItemsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_menu_items.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_menu_items.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_menu_items...\", module: __MODULE__)

    # PRAGMA foreign_keys = ON;

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_menu_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      parent_id INTEGER NOT NULL DEFAULT 0, -- Refere-se a sys_menu_items.id para submenus
      set_name TEXT NOT NULL, -- FK para sys_menu_sets.set_name
      module TEXT NOT NULL,
      name TEXT NOT NULL,
      title_system TEXT, -- Chave de linguagem para o título
      title TEXT NOT NULL,
      link TEXT NOT NULL,
      onclick TEXT,
      target TEXT,
      icon TEXT,
      addon TEXT,
      addon_cache INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      markers TEXT,
      submenu_object TEXT, -- Nome do objeto de menu (sys_objects_menu.object) para o submenu
      submenu_popup INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      visible_for_levels INTEGER DEFAULT 2147483647, -- Bitmask ACL
      visibility_custom TEXT,
      hidden_on TEXT,
      hidden_on_cxt TEXT,
      hidden_on_pt INTEGER DEFAULT 0,
      hidden_on_col INTEGER DEFAULT 0,
      primary_item INTEGER NOT NULL DEFAULT 0, -- Renomeado de 'primary'
      collapsed INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      active INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      active_api INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      copyable INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      editable INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      \"order\" INTEGER NOT NULL,
      FOREIGN KEY (set_name) REFERENCES sys_menu_sets(set_name) ON DELETE CASCADE ON UPDATE CASCADE
      -- FK para parent_id (auto-referência), module (sys_modules.name),
      -- submenu_object (sys_objects_menu.object) são conceituais ou gerenciadas pela app.
    );

    CREATE INDEX IF NOT EXISTS idx_sys_menu_items_set_name_parent_order ON sys_menu_items(set_name, parent_id, \"order\");
    CREATE INDEX IF NOT EXISTS idx_sys_menu_items_module ON sys_menu_items(module);
    CREATE INDEX IF NOT EXISTS idx_sys_menu_items_name ON sys_menu_items(name);
    CREATE INDEX IF NOT EXISTS idx_sys_menu_items_link ON sys_menu_items(link);
    CREATE INDEX IF NOT EXISTS idx_sys_menu_items_submenu_object ON sys_menu_items(submenu_object);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_menu_items criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_menu_items: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_menu_items.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
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

## Notas de Adaptação SQLite:

*   `id`, `parent_id`, `hidden_on_pt`, `hidden_on_col`, `order`: `INT(11)` (MySQL) -> `INTEGER` (SQLite). `id` é `PRIMARY KEY AUTOINCREMENT`. `order` está entre aspas.
*   `set_name`, `module`, `name`, `title_system`, `title`, `link`, `onclick`, `target`, `icon`, `addon`, `markers`, `submenu_object`, `visibility_custom`, `hidden_on`, `hidden_on_cxt`: `VARCHAR` ou `TEXT` (MySQL) -> `TEXT` (SQLite).
*   `addon_cache`, `submenu_popup`, `primary_item`, `collapsed`, `active`, `active_api`, `copyable`, `editable`: `TINYINT(4)` (MySQL) -> `INTEGER` (SQLite), (0 ou 1). `primary_item` foi renomeado de `primary`.
*   `visible_for_levels`: `INT(11)` (MySQL) -> `INTEGER` (SQLite). É uma bitmask.
*   **Chave Estrangeira:** Explicitamente definida para `set_name`. A auto-referência `parent_id` e a referência `submenu_object` para `sys_objects_menu.object` são mais complexas de impor estritamente com `FOREIGN KEY` no SQLite durante a criação inicial se a ordem não for perfeita, mas a lógica da aplicação deve tratar essas relações.