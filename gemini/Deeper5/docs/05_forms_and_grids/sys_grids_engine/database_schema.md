# Documentação Deeper: Esquema do BD para Motor de Grades Dinâmicas (SQLite)

Define `CREATE TABLE` para as tabelas do motor de grades do UNA.

## Tabela: `sys_objects_grid`

```sql
CREATE TABLE IF NOT EXISTS sys_objects_grid (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  object TEXT NOT NULL UNIQUE, -- Nome do objeto de grade (ex: 'bx_persons_administration')
  source_type TEXT NOT NULL CHECK(source_type IN ('Sql', 'Array', 'Service')), -- 'Service' é uma adição Deeper
  source TEXT NOT NULL, -- Query SQL, ou nome da função/serviço Elixir
  table_name TEXT NOT NULL, -- Tabela principal (informativo, ou usado se source_type='Service')
  field_id TEXT NOT NULL, -- Nome da coluna ID na fonte de dados
  field_order TEXT NOT NULL, -- Nome da coluna usada para ordenação manual (se houver)
  field_active TEXT, -- Nome da coluna para status ativo/inativo (se houver)
  order_get_field TEXT NOT NULL DEFAULT 'order_field', -- Nome do query param para campo de ordenação
  order_get_dir TEXT NOT NULL DEFAULT 'order_dir', -- Nome do query param para direção de ordenação
  paginate_url TEXT, -- URL base para paginação no UNA PHP. Para Deeper, será endpoint da API de dados.
  paginate_per_page INTEGER NOT NULL DEFAULT 10,
  paginate_simple TEXT, -- Opções para paginação simples no UNA PHP
  paginate_get_start TEXT NOT NULL DEFAULT 'start', -- Nome do query param para offset/página
  paginate_get_per_page TEXT NOT NULL DEFAULT 'per_page', -- Nome do query param para itens por página
  filter_fields TEXT, -- Lista de campos filtráveis (string delimitada por vírgula)
  filter_fields_translatable TEXT, -- Campos de filtro que precisam de tradução (lógica complexa)
  filter_mode TEXT NOT NULL DEFAULT 'auto' CHECK(filter_mode IN ('like', 'fulltext', 'auto')),
  filter_get TEXT NOT NULL DEFAULT 'filter', -- Nome do query param para filtro geral
  sorting_fields TEXT, -- Lista de campos ordenáveis (string delimitada por vírgula)
  sorting_fields_translatable TEXT,
  visible_for_levels INTEGER NOT NULL DEFAULT 2147483647, -- Bitmask ACL
  responsive INTEGER NOT NULL DEFAULT 1,
  show_total_count INTEGER NOT NULL DEFAULT 1,
  override_class_name TEXT,
  override_class_file TEXT
);
```

```sql
CREATE TABLE IF NOT EXISTS sys_grid_fields (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  object TEXT NOT NULL, -- FK (lógica) para sys_objects_grid.object
  name TEXT NOT NULL, -- Nome da coluna/campo da fonte de dados
  title TEXT NOT NULL, -- Chave de tradução para o título da coluna
  width TEXT NOT NULL DEFAULT 'auto', -- Largura da coluna (ex: '10%', '100px')
  translatable INTEGER NOT NULL DEFAULT 0, -- Se o conteúdo do campo é uma chave de tradução
  chars_limit INTEGER NOT NULL DEFAULT 0, -- Limite de caracteres para exibir (0 para sem limite)
  params TEXT, -- Parâmetros de formatação/renderização (JSON ou string)
  hidden_on TEXT, -- Condições de tela para ocultar (ex: 'phone,tablet')
  \"order\" INTEGER NOT NULL DEFAULT 0
  -- UNIQUE (object, name)
);
CREATE UNIQUE INDEX IF NOT EXISTS uidx_sgf_object_name ON sys_grid_fields(object, name);
CREATE INDEX IF NOT EXISTS idx_sgf_object_order ON sys_grid_fields(object, \"order\");
```

```sql
CREATE TABLE IF NOT EXISTS sys_grid_actions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  object TEXT NOT NULL, -- FK (lógica) para sys_objects_grid.object
  type TEXT NOT NULL CHECK(type IN ('bulk', 'single', 'independent')),
  name TEXT NOT NULL, -- Nome da ação (ex: 'delete', 'edit', 'activate')
  title TEXT NOT NULL, -- Chave de tradução para o título da ação
  icon TEXT, -- Classe/path do ícone
  icon_only INTEGER NOT NULL DEFAULT 0,
  confirm INTEGER NOT NULL DEFAULT 1, -- Se a ação requer confirmação do usuário
  active INTEGER NOT NULL DEFAULT 1,
  \"order\" INTEGER NOT NULL DEFAULT 0
  -- UNIQUE (object, type, name)
);
CREATE UNIQUE INDEX IF NOT EXISTS uidx_sga_object_type_name ON sys_grid_actions(object, type, name);
CREATE INDEX IF NOT EXISTS idx_sga_object_order ON sys_grid_actions(object, \"order\");
```

## Tabela: `sys_grid_fields`

## Tabela: `sys_grid_actions`