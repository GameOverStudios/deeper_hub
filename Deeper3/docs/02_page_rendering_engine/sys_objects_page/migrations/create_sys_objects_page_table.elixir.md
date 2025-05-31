# Migração Elixir: Criar Tabela `sys_objects_page`

Este módulo de migração Elixir é responsável por criar a tabela `sys_objects_page` no banco de dados SQLite. Esta tabela central define cada página individual no sistema UNA, seu URI, título, layout associado, tipo, e outras configurações e metadados.

**Dependências:** Esta tabela possui chaves estrangeiras para `sys_pages_layouts` e `sys_pages_types`. Essas tabelas devem existir antes da execução desta migração (ou, mais precisamente, antes da imposição das FKs).

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_objects_page_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysObjectsPageTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_objects_page.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_objects_page.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_objects_page...\", module: __MODULE__)

    # PRAGMA foreign_keys = ON;

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_objects_page (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      author INTEGER NOT NULL DEFAULT 0, -- ID do perfil do autor
      added INTEGER NOT NULL DEFAULT 0, -- Unix Timestamp
      object TEXT NOT NULL UNIQUE, -- Nome único do objeto de página
      uri TEXT NOT NULL UNIQUE, -- URI da página
      title_system TEXT,
      title TEXT NOT NULL,
      module TEXT NOT NULL, -- Módulo ao qual a página pertence
      cover INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      cover_image INTEGER DEFAULT 0, -- ID da imagem de capa
      cover_title TEXT,
      type_id INTEGER NOT NULL DEFAULT 1, -- FK para sys_pages_types.id
      layout_id INTEGER NOT NULL, -- FK para sys_pages_layouts.id
      sticky_columns INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      submenu TEXT, -- Nome do objeto de menu para o submenu
      visible_for_levels INTEGER DEFAULT 2147483647, -- Bitmask ACL
      visible_for_levels_editable INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      url TEXT, -- URL externa para redirecionamento
      content_info TEXT, -- Nome do objeto content_info
      meta_title TEXT,
      meta_description TEXT,
      meta_keywords TEXT,
      meta_robots TEXT,
      cache_lifetime INTEGER NOT NULL DEFAULT 0, -- Em segundos
      cache_editable INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      inj_head TEXT,
      inj_footer TEXT,
      deletable INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      override_class_name TEXT,
      override_class_file TEXT,
      FOREIGN KEY (layout_id) REFERENCES sys_pages_layouts(id) ON UPDATE CASCADE ON DELETE RESTRICT,
      FOREIGN KEY (type_id) REFERENCES sys_pages_types(id) ON UPDATE CASCADE ON DELETE RESTRICT
      -- Outras FKs (module, submenu, content_info, author, cover_image) serão para tabelas
      -- a serem definidas/migradas em outras seções.
    );

    CREATE INDEX IF NOT EXISTS idx_sys_objects_page_object ON sys_objects_page(object);
    CREATE INDEX IF NOT EXISTS idx_sys_objects_page_uri ON sys_objects_page(uri);
    CREATE INDEX IF NOT EXISTS idx_sys_objects_page_module ON sys_objects_page(module);
    CREATE INDEX IF NOT EXISTS idx_sys_objects_page_layout_id ON sys_objects_page(layout_id);
    CREATE INDEX IF NOT EXISTS idx_sys_objects_page_type_id ON sys_objects_page(type_id);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_objects_page criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_objects_page: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_objects_page.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_objects_page...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS sys_objects_page;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_objects_page removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_objects_page: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`, `author`, `added`, `cover_image`, `type_id`, `layout_id`, `cache_lifetime`: `INT` ou `TINYINT` (MySQL) -> `INTEGER` (SQLite). `added` é um Timestamp Unix.
*   `object`, `uri`, `title_system`, `title`, `module`, `cover_title`, `submenu`, `url`, `content_info`, `meta_title`, `meta_description`, `meta_keywords`, `meta_robots`, `inj_head`, `inj_footer`, `override_class_name`, `override_class_file`: `VARCHAR` ou `TEXT` (MySQL) -> `TEXT` (SQLite). `object` e `uri` são `UNIQUE`.
*   `cover`, `sticky_columns`, `visible_for_levels_editable`, `cache_editable`, `deletable`: `TINYINT` (MySQL) -> `INTEGER` (SQLite), (0 ou 1).
*   `visible_for_levels`: `INT` (MySQL) -> `INTEGER` (SQLite). Este é uma bitmask.
*   **Chaves Estrangeiras:**
    *   `layout_id` para `sys_pages_layouts.id`.
    *   `type_id` para `sys_pages_types.id`.
    *   Outras colunas como `module`, `submenu`, `content_info`, `author` e `cover_image` são conceitualmente chaves estrangeiras para tabelas que serão definidas em outras migrações (ex: `sys_modules`, `sys_objects_menu`, `sys_profiles`, `sys_files`). A constraint `FOREIGN KEY` pode ser adicionada posteriormente com `ALTER TABLE` ou se as tabelas referenciadas forem criadas antes desta. Por simplicidade, apenas as FKs para tabelas já migradas nesta seção (`sys_pages_layouts`, `sys_pages_types`) estão explicitamente definidas. `ON DELETE RESTRICT` é usado para prevenir a exclusão de layouts ou tipos em uso.