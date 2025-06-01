# Documentação Deeper: Esquema do Banco de Dados para Menus (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas usadas pelo motor de menus do UNA: `sys_menu_sets`, `sys_menu_templates`, `sys_objects_menu`, e `sys_menu_items`.

## Tabela: `sys_menu_sets`

```sql
CREATE TABLE IF NOT EXISTS sys_menu_sets (
  set_name TEXT PRIMARY KEY, -- Nome único do conjunto de menus
  module TEXT NOT NULL, -- Módulo ao qual este conjunto pertence
  title TEXT NOT NULL, -- Chave de tradução para o título do conjunto
  deletable INTEGER NOT NULL DEFAULT 1 -- 0 ou 1
);
```

```sql
CREATE TABLE IF NOT EXISTS sys_menu_templates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  template TEXT NOT NULL UNIQUE, -- Nome do arquivo de template visual para o menu
  title TEXT NOT NULL, -- Chave de tradução para o título do template
  visible INTEGER NOT NULL DEFAULT 1 -- 0 ou 1, se o template está disponível para seleção
);
```

```sql
CREATE TABLE IF NOT EXISTS sys_objects_menu (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  object TEXT NOT NULL UNIQUE, -- Nome único do objeto de menu (ex: 'bx_persons_main_menu')
  title TEXT NOT NULL, -- Chave de tradução para o título do menu
  set_name TEXT NOT NULL, -- FK (lógica) para sys_menu_sets.set_name
  module TEXT NOT NULL, -- Módulo que define este objeto de menu
  template_id INTEGER NOT NULL, -- FK para sys_menu_templates.id
  persistent INTEGER NOT NULL DEFAULT 0, -- 0 ou 1, se o menu deve persistir entre páginas (cache de UI)
  deletable INTEGER NOT NULL DEFAULT 1,
  active INTEGER NOT NULL DEFAULT 0, -- 0 ou 1, se o objeto de menu está ativo
  override_class_name TEXT,
  override_class_file TEXT,
  FOREIGN KEY (template_id) REFERENCES sys_menu_templates(id) ON DELETE RESTRICT ON UPDATE CASCADE
  -- FK lógica para set_name (sys_menu_sets.set_name) e module (sys_modules.name)
);
CREATE INDEX IF NOT EXISTS idx_sys_objects_menu_set_name ON sys_objects_menu(set_name);
```

```sql
CREATE TABLE IF NOT EXISTS sys_menu_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  parent_id INTEGER NOT NULL DEFAULT 0, -- ID do item pai (para hierarquia, 0 para item raiz)
  set_name TEXT NOT NULL, -- FK (lógica) para sys_menu_sets.set_name (a qual conjunto este item pertence)
  module TEXT NOT NULL, -- Módulo que define este item
  name TEXT NOT NULL, -- Nome programático do item (único dentro do set_name)
  title_system TEXT, -- Chave de tradução para o título interno
  title TEXT NOT NULL, -- Chave de tradução para o título exibido
  link TEXT NOT NULL, -- URL do link
  onclick TEXT, -- Código JavaScript para o evento onclick
  target TEXT, -- Alvo do link (ex: '_blank')
  icon TEXT, -- Classe/path do ícone
  addon TEXT, -- Texto/HTML adicional (ex: badge)
  addon_cache INTEGER NOT NULL DEFAULT 0, -- Se o addon deve ser cacheado (UNA PHP)
  markers TEXT, -- String JSON ou serializada para marcadores/badges dinâmicos
  submenu_object TEXT, -- Nome de um sys_objects_menu.object para ser renderizado como submenu
  submenu_popup INTEGER NOT NULL DEFAULT 0, -- 0 ou 1, se o submenu deve ser popup
  visible_for_levels INTEGER NOT NULL DEFAULT 2147483647, -- Bitmask ACL
  visibility_custom TEXT, -- Lógica de visibilidade customizada (UNA PHP)
  hidden_on TEXT, -- Condições de tela para ocultar (ex: 'phone,tablet')
  hidden_on_cxt TEXT, -- Ocultar baseado em contexto (UNA PHP)
  hidden_on_pt INTEGER DEFAULT 0, -- Ocultar baseado em tipo de página (UNA PHP)
  hidden_on_col INTEGER DEFAULT 0, -- Ocultar baseado em colunas (UNA PHP)
  primary_item INTEGER NOT NULL DEFAULT 0, -- SQLite não gosta de 'primary' como nome
  collapsed INTEGER NOT NULL DEFAULT 0,
  active INTEGER NOT NULL DEFAULT 1, -- 0 ou 1, se o item está ativo
  active_api INTEGER NOT NULL DEFAULT 0, -- Se o item deve ser exposto via API no UNA
  copyable INTEGER NOT NULL DEFAULT 1,
  editable INTEGER NOT NULL DEFAULT 1,
  \"order\" INTEGER NOT NULL DEFAULT 0
  -- FK lógica para set_name (sys_menu_sets.set_name)
  -- FK lógica para submenu_object (sys_objects_menu.object)
);

CREATE INDEX IF NOT EXISTS idx_sys_menu_items_set_name_parent_id ON sys_menu_items(set_name, parent_id, \"order\");
CREATE UNIQUE INDEX IF NOT EXISTS idx_sys_menu_items_set_name_name ON sys_menu_items(set_name, name);
```

*   Agrupa itens de menu. Um `sys_objects_menu` referencia um `set_name`.

## Tabela: `sys_menu_templates`

*   Define os diferentes estilos visuais para a renderização de menus.

## Tabela: `sys_objects_menu`

*   Define uma instância específica de um menu que pode ser renderizada. É este `object` que a API usará para buscar um menu.

## Tabela: `sys_menu_items`

*   Define cada item individual dentro de um conjunto de menu (`set_name`).
*   `parent_id` cria a hierarquia.
*   `visible_for_levels` e `active` são cruciais para a API determinar quais itens retornar.
*   `submenu_object` permite aninhar menus.