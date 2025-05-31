# Documentação Deeper: Esquema do BD para Motor de Grids de Dados (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas do UNA que compõem o sistema de grids de dados dinâmicos.

## Tabela: `sys_objects_grid` (Definição de Grids)

```sql
CREATE TABLE IF NOT EXISTS sys_objects_grid (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11)
  object TEXT NOT NULL UNIQUE, -- Nome único do objeto de grid, ex: 'bx_persons_administration'
  source_type TEXT NOT NULL CHECK(source_type IN ('Sql', 'Array')), -- ENUM('Sql','Array') no UNA
  source TEXT NOT NULL, -- Query SQL ou nome da função PHP que retorna array
  \"table\" TEXT NOT NULL, -- Tabela principal (se source_type='Sql' e source não for uma query completa)
  field_id TEXT NOT NULL, -- Nome da coluna ID na 'table' ou na query 'source'
  field_order TEXT NOT NULL, -- Nome da coluna para ordenação padrão
  field_active TEXT, -- Nome da coluna para status ativo (opcional)
  order_get_field TEXT NOT NULL DEFAULT 'order_field', -- Nome do query param para campo de ordenação
  order_get_dir TEXT NOT NULL DEFAULT 'order_dir', -- Nome do query param para direção da ordenação
  paginate_url TEXT, -- URL base para paginação no UNA PHP (menos relevante para API)
  paginate_per_page INTEGER NOT NULL DEFAULT 10,
  paginate_simple TEXT, -- Template para paginação simples no UNA PHP
  paginate_get_start TEXT NOT NULL, -- Nome do query param para offset/start (ex: 'start', 'offset')
  paginate_get_per_page TEXT NOT NULL, -- Nome do query param para limit/per_page (ex: 'per_page', 'limit')
  filter_fields TEXT, -- Lista de campos filtráveis (string CSV ou JSON)
  filter_fields_translatable TEXT, -- Lista de campos filtráveis que são traduzíveis
  filter_mode TEXT NOT NULL DEFAULT 'auto' CHECK(filter_mode IN ('like', 'fulltext', 'auto')), -- ENUM
  filter_get TEXT NOT NULL DEFAULT 'filter', -- Nome do query param para o termo de filtro geral
  sorting_fields TEXT, -- Lista de campos ordenáveis (string CSV ou JSON)
  sorting_fields_translatable TEXT,
  visible_for_levels INTEGER NOT NULL DEFAULT 2147483647, -- Bitmask ACL
  responsive INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
  show_total_count INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
  override_class_name TEXT,
  override_class_file TEXT
);
CREATE INDEX IF NOT EXISTS idx_sys_objects_grid_object ON sys_objects_grid(object);
```

```sql
CREATE TABLE IF NOT EXISTS sys_grid_fields (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11)
  object TEXT NOT NULL, -- FK para sys_objects_grid.object
  name TEXT NOT NULL, -- Nome do campo/coluna (da fonte de dados)
  title TEXT, -- Título da coluna (pode ser chave de linguagem). No UNA é VARCHAR(255) NOT NULL
  width TEXT NOT NULL, -- Largura da coluna (ex: '10%', '100px')
  translatable INTEGER NOT NULL DEFAULT 0, -- 0 ou 1 (se o conteúdo da coluna é traduzível)
  chars_limit INTEGER NOT NULL DEFAULT 0, -- Limite de caracteres para exibição
  params TEXT, -- Parâmetros adicionais (JSON ou string serializada, ex: para formatação)
  hidden_on TEXT, -- Condições para ocultar a coluna (ex: 'mobile'). VARCHAR(255)
  \"order\" INTEGER NOT NULL, -- Ordem da coluna no grid
  FOREIGN KEY (object) REFERENCES sys_objects_grid(object) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_grid_fields_object_name ON sys_grid_fields(object, name);
CREATE INDEX IF NOT EXISTS idx_sys_grid_fields_object_order ON sys_grid_fields(object, \"order\");
```

```sql
CREATE TABLE IF NOT EXISTS sys_grid_actions (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11)
  object TEXT NOT NULL, -- FK para sys_objects_grid.object
  type TEXT NOT NULL CHECK(type IN ('bulk', 'single', 'independent')), -- ENUM no UNA
  name TEXT NOT NULL, -- Nome da ação (ex: 'delete', 'edit', 'add_item')
  title TEXT, -- Título da ação (pode ser chave de linguagem). No UNA é VARCHAR(255) NOT NULL
  icon TEXT, -- Ícone da ação. No UNA é VARCHAR(255)
  icon_only INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
  confirm INTEGER NOT NULL DEFAULT 1, -- 0 ou 1 (se a ação requer confirmação)
  active INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
  \"order\" INTEGER NOT NULL,
  FOREIGN KEY (object) REFERENCES sys_objects_grid(object) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_grid_actions_object_type_name ON sys_grid_actions(object, type, name);
CREATE INDEX IF NOT EXISTS idx_sys_grid_actions_object_order ON sys_grid_actions(object, \"order\");
```

*   Define cada instância de grid.
*   `\"table\"` está entre aspas.

## Tabela: `sys_grid_fields` (Definição de Colunas do Grid)

*   Define cada coluna de um grid.
*   `\"order\"` está entre aspas.

## Tabela: `sys_grid_actions` (Definição de Ações do Grid)

*   Define as ações disponíveis em um grid.
*   `\"order\"` está entre aspas.

### Chaves Estrangeiras e Integridade:
*   Definidas onde aplicável.
*   Lembre-se de `PRAGMA foreign_keys = ON;` para SQLite.