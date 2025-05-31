# Migração Elixir: Criar Tabela `sys_pages_blocks`

Este módulo de migração Elixir é responsável por criar a tabela `sys_pages_blocks` no banco de dados SQLite. Esta tabela define os blocos de conteúdo individuais que compõem uma página (`sys_objects_page`), especificando seu tipo, conteúdo, em qual célula do layout aparecem, e outras propriedades.

**Dependências:** Esta tabela possui chaves estrangeiras para `sys_objects_page` (via coluna `object`) e `sys_pages_design_boxes`.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_pages_blocks_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysPagesBlocksTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_pages_blocks.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_pages_blocks.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_pages_blocks...\", module: __MODULE__)

    # PRAGMA foreign_keys = ON;

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_pages_blocks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object TEXT NOT NULL, -- Nome do objeto de página (sys_objects_page.object)
      cell_id INTEGER NOT NULL DEFAULT 1,
      module TEXT NOT NULL,
      title_system TEXT,
      title TEXT NOT NULL,
      designbox_id INTEGER NOT NULL DEFAULT 11, -- FK para sys_pages_design_boxes.id
      class TEXT,
      submenu TEXT, -- Nome do objeto de menu
      tabs INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      async INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      visible_for_levels INTEGER DEFAULT 2147483647, -- Bitmask ACL
      hidden_on TEXT,
      type TEXT NOT NULL DEFAULT 'raw' CHECK(type IN (
        'raw', 'html', 'creative', 'bento_grid', 'lang', 'image', 'rss', 'menu', 'custom', 'service', 'wiki'
      )),
      content TEXT, -- Conteúdo (HTML, def de serviço, ID de imagem, URL RSS, nome de menu)
      content_empty TEXT, -- Chave de linguagem para conteúdo vazio
      \"text\" TEXT, -- Conteúdo para blocos 'wiki' ou 'text'
      text_updated INTEGER, -- Unix Timestamp
      help TEXT,
      cache_lifetime INTEGER NOT NULL DEFAULT 0, -- Em segundos
      deletable INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      copyable INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      active INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      active_api INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      \"order\" INTEGER NOT NULL,
      FOREIGN KEY (object) REFERENCES sys_objects_page(object) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (designbox_id) REFERENCES sys_pages_design_boxes(id) ON UPDATE CASCADE ON DELETE RESTRICT
      -- FKs para module (sys_modules.name), submenu (sys_objects_menu.object) a serem adicionadas/consideradas.
    );

    CREATE INDEX IF NOT EXISTS idx_sys_pages_blocks_object_cell_order ON sys_pages_blocks(object, cell_id, \"order\");
    CREATE INDEX IF NOT EXISTS idx_sys_pages_blocks_module ON sys_pages_blocks(module);
    CREATE INDEX IF NOT EXISTS idx_sys_pages_blocks_designbox_id ON sys_pages_blocks(designbox_id);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_pages_blocks criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_pages_blocks: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_pages_blocks.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_pages_blocks...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS sys_pages_blocks;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_pages_blocks removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_pages_blocks: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`, `cell_id`, `designbox_id`, `text_updated`, `cache_lifetime`, `order`: `INT` ou `TINYINT` (MySQL) -> `INTEGER` (SQLite). `text_updated` é um Timestamp Unix. `order` está entre aspas.
*   `object`, `module`, `title_system`, `title`, `class`, `submenu`, `hidden_on`, `content`, `content_empty`, `text`, `help`: `VARCHAR` ou `TEXT`/`MEDIUMTEXT` (MySQL) -> `TEXT` (SQLite).
*   `tabs`, `async`, `deletable`, `copyable`, `active`, `active_api`: `TINYINT` (MySQL) -> `INTEGER` (SQLite), (0 ou 1).
*   `visible_for_levels`: `INT` (MySQL) -> `INTEGER` (SQLite). É uma bitmask.
*   `type`: `ENUM(...)` (MySQL) -> `TEXT CHECK(type IN (...))` (SQLite).
*   **Chaves Estrangeiras:**
    *   `object` para `sys_objects_page.object`.
    *   `designbox_id` para `sys_pages_design_boxes.id`.