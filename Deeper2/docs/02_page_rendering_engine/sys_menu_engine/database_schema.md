# Documentação Deeper: Esquema do BD para Motor de Menus (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas do UNA que compõem o sistema de menus.

## Tabela: `sys_menu_templates`

```sql
CREATE TABLE IF NOT EXISTS sys_menu_templates (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11)
  template TEXT NOT NULL UNIQUE, -- Nome do arquivo de template. No UNA é VARCHAR(255)
  title TEXT NOT NULL, -- Título do template. No UNA é VARCHAR(255)
  visible INTEGER NOT NULL DEFAULT 1 -- 0 ou 1. No UNA é TINYINT(4)
);
```

```sql
CREATE TABLE IF NOT EXISTS sys_menu_sets (
  set_name TEXT PRIMARY KEY NOT NULL, -- Nome único do conjunto de menus. No UNA é VARCHAR(64)
  module TEXT NOT NULL, -- Módulo que define este conjunto. No UNA é VARCHAR(32)
  title TEXT NOT NULL, -- Título amigável do conjunto. No UNA é VARCHAR(255)
  deletable INTEGER NOT NULL DEFAULT 1 -- 0 ou 1. No UNA é TINYINT(4)
  -- FK para module (sys_modules.name)
);
CREATE INDEX IF NOT EXISTS idx_sys_menu_sets_module ON sys_menu_sets(module);
```

```sql
CREATE TABLE IF NOT EXISTS sys_objects_menu (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11)
  object TEXT NOT NULL UNIQUE, -- Nome único do objeto de menu, ex: 'bx_persons_main_menu'. No UNA é VARCHAR(64)
  title TEXT NOT NULL, -- Título do objeto de menu. No UNA é VARCHAR(255)
  set_name TEXT NOT NULL, -- FK para sys_menu_sets.set_name. No UNA é VARCHAR(64)
  module TEXT NOT NULL, -- Módulo que define este objeto. No UNA é VARCHAR(32)
  template_id INTEGER NOT NULL, -- FK para sys_menu_templates.id. No UNA é INT(11)
  persistent INTEGER NOT NULL DEFAULT 0, -- 0 ou 1. No UNA é TINYINT(4)
  deletable INTEGER NOT NULL DEFAULT 1, -- 0 ou 1. No UNA é TINYINT(4)
  active INTEGER NOT NULL DEFAULT 0, -- 0 ou 1. No UNA é TINYINT(4)
  override_class_name TEXT, -- No UNA é VARCHAR(255)
  override_class_file TEXT, -- No UNA é VARCHAR(255)
  FOREIGN KEY (set_name) REFERENCES sys_menu_sets(set_name) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (template_id) REFERENCES sys_menu_templates(id) ON UPDATE CASCADE ON DELETE RESTRICT
  -- FK para module (sys_modules.name)
);
CREATE INDEX IF NOT EXISTS idx_sys_objects_menu_object ON sys_objects_menu(object);
CREATE INDEX IF NOT EXISTS idx_sys_objects_menu_set_name ON sys_objects_menu(set_name);
CREATE INDEX IF NOT EXISTS idx_sys_objects_menu_module ON sys_objects_menu(module);
```

```sql
CREATE TABLE IF NOT EXISTS sys_menu_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11)
  parent_id INTEGER NOT NULL DEFAULT 0, -- ID do item pai (para submenus). Refere-se a sys_menu_items.id
  set_name TEXT NOT NULL, -- FK para sys_menu_sets.set_name. No UNA é VARCHAR(64)
  module TEXT NOT NULL, -- Módulo que define este item. No UNA é VARCHAR(32)
  name TEXT NOT NULL, -- Nome único do item (dentro do set?). No UNA é VARCHAR(255)
  title_system TEXT, -- Chave de linguagem para o título. No UNA é VARCHAR(255)
  title TEXT NOT NULL, -- Título do item (pode ser o valor traduzido). No UNA é VARCHAR(255)
  link TEXT NOT NULL, -- URL do link. No UNA é VARCHAR(512)
  onclick TEXT, -- JavaScript para o evento onclick. No UNA é VARCHAR(255)
  target TEXT, -- Atributo target do link (ex: _blank). No UNA é VARCHAR(255)
  icon TEXT, -- Classe do ícone ou URL da imagem. No UNA é TEXT
  addon TEXT, -- Conteúdo adicional (ex: contador de notificações). No UNA é TEXT
  addon_cache INTEGER NOT NULL DEFAULT 0, -- 0 ou 1, se o addon deve ser cacheado. No UNA é TINYINT(4)
  markers TEXT, -- Marcadores especiais para o item (ex: 'new'). No UNA é TEXT
  submenu_object TEXT, -- Nome do objeto de menu para o submenu (FK para sys_objects_menu.object). No UNA é VARCHAR(64)
  submenu_popup INTEGER NOT NULL DEFAULT 0, -- 0 ou 1, se o submenu é popup. No UNA é TINYINT(4)
  visible_for_levels INTEGER, -- Bitmask ACL. No UNA é INT(11) NOT NULL DEFAULT 2147483647
  visibility_custom TEXT, -- Lógica de visibilidade customizada (service call no UNA). No UNA é TEXT
  hidden_on TEXT, -- Condições para ocultar (ex: mobile, desktop). No UNA é VARCHAR(255)
  hidden_on_cxt TEXT, -- Contextos para ocultar. No UNA é VARCHAR(255)
  hidden_on_pt INTEGER, -- Tipos de página para ocultar. No UNA é INT(11)
  hidden_on_col INTEGER, -- Número de colunas para ocultar. No UNA é INT(11)
  primary_item INTEGER NOT NULL DEFAULT 0, -- 0 ou 1. Nome da coluna no UNA era `primary`.
  collapsed INTEGER NOT NULL DEFAULT 0, -- 0 ou 1. No UNA é TINYINT(4)
  active INTEGER NOT NULL DEFAULT 1, -- 0 ou 1. No UNA é TINYINT(4)
  active_api INTEGER NOT NULL DEFAULT 0, -- 0 ou 1, se ativo para API. No UNA é TINYINT(4)
  copyable INTEGER NOT NULL DEFAULT 1, -- 0 ou 1. No UNA é TINYINT(4)
  editable INTEGER NOT NULL DEFAULT 1, -- 0 ou 1. No UNA é TINYINT(4)
  \"order\" INTEGER NOT NULL, -- Ordem do item. No UNA é INT(11)
  FOREIGN KEY (set_name) REFERENCES sys_menu_sets(set_name) ON DELETE CASCADE ON UPDATE CASCADE
  -- FK para parent_id (sys_menu_items.id), module (sys_modules.name), submenu_object (sys_objects_menu.object)
  -- A FK para parent_id (auto-referência) pode ser complicada de definir estritamente no SQLite CREATE TABLE,
  -- mas a lógica da aplicação deve respeitá-la.
);
CREATE INDEX IF NOT EXISTS idx_sys_menu_items_set_name_parent_order ON sys_menu_items(set_name, parent_id, \"order\");
CREATE INDEX IF NOT EXISTS idx_sys_menu_items_module ON sys_menu_items(module);
CREATE INDEX IF NOT EXISTS idx_sys_menu_items_name ON sys_menu_items(name);
CREATE INDEX IF NOT EXISTS idx_sys_menu_items_link ON sys_menu_items(link(255)); -- SQLite não suporta prefixo, mas indexar o começo é bom
```

*   Define os diferentes templates visuais para menus (mais relevante para o UNA PHP).

## Tabela: `sys_menu_sets`

*   Define conjuntos lógicos de itens de menu. A chave primária é `set_name`.

## Tabela: `sys_objects_menu`

*   Define instâncias específicas de menus, ligando um `set_name` a um template de visualização.

## Tabela: `sys_menu_items`

*   Define os itens individuais de cada menu.
*   `primary_item`: Renomeado de `primary` para evitar conflito com palavra reservada.
*   A auto-referência `parent_id` para `sys_menu_items.id` é para criar hierarquias de menu.

### Chaves Estrangeiras e Integridade:
*   As chaves estrangeiras foram definidas. `ON DELETE CASCADE` em `sys_menu_items` para `set_name` e `sys_objects_menu` para `set_name` garante que deletar um `set` remove seus itens e objetos de menu associados. `ON DELETE RESTRICT` para `template_id` em `sys_objects_menu` previne a exclusão de templates em uso.
*   Lembre-se de `PRAGMA foreign_keys = ON;` para SQLite.