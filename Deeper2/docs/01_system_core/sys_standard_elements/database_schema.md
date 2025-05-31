# Documentação Deeper: Esquema do BD para Elementos Padrão (`sys_std_*`) (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas \"padrão\" (`sys_std_*`) do sistema UNA.

## Tabela: `sys_std_pages`

```sql
CREATE TABLE IF NOT EXISTS sys_std_pages (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11) UNSIGNED
  \"index\" INTEGER NOT NULL DEFAULT 0, -- No UNA é INT(11) UNSIGNED
  name TEXT NOT NULL UNIQUE, -- Nome da página, ex: 'dashboard'. No UNA é VARCHAR(64)
  header TEXT, -- Título do cabeçalho. No UNA é VARCHAR(255)
  caption TEXT, -- Legenda/descrição. No UNA é VARCHAR(255)
  icon TEXT -- Ícone da página. No UNA é VARCHAR(255)
);
CREATE INDEX IF NOT EXISTS idx_sys_std_pages_name ON sys_std_pages(name);
```

```sql
CREATE TABLE IF NOT EXISTS sys_std_widgets (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11) UNSIGNED
  page_id TEXT NOT NULL, -- No UNA é VARCHAR(255) DEFAULT '', pode referenciar sys_std_pages.name ou outro identificador
  module TEXT, -- Módulo do widget. No UNA é VARCHAR(32)
  type TEXT, -- Tipo de widget. No UNA é VARCHAR(32)
  url TEXT, -- URL (se aplicável). No UNA é VARCHAR(255)
  click TEXT, -- Ação JS de clique. No UNA é TEXT
  icon TEXT, -- Ícone do widget. No UNA é VARCHAR(255)
  caption TEXT, -- Legenda do widget. No UNA é VARCHAR(255)
  cnt_notices TEXT, -- Lógica para contagem de notificações. No UNA é TEXT
  cnt_actions TEXT, -- Lógica para contagem de ações. No UNA é TEXT
  featured INTEGER NOT NULL DEFAULT 0 -- 0 ou 1. No UNA é TINYINT(4) UNSIGNED
);
CREATE INDEX IF NOT EXISTS idx_sys_std_widgets_page_id ON sys_std_widgets(page_id);
```

```sql
CREATE TABLE IF NOT EXISTS sys_std_pages_widgets (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11) UNSIGNED
  page_id INTEGER NOT NULL, -- FK para sys_std_pages.id. No UNA é INT(11) UNSIGNED
  widget_id INTEGER NOT NULL, -- FK para sys_std_widgets.id. No UNA é INT(11) UNSIGNED
  \"order\" INTEGER NOT NULL DEFAULT 0, -- No UNA é INT(11) UNSIGNED
  FOREIGN KEY (page_id) REFERENCES sys_std_pages(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (widget_id) REFERENCES sys_std_widgets(id) ON DELETE CASCADE ON UPDATE CASCADE
  -- UNIQUE (widget_id, page_id) no UNA
);
CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_std_pages_widgets_page_widget ON sys_std_pages_widgets(page_id, widget_id);
```

```sql
CREATE TABLE IF NOT EXISTS sys_std_roles (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11) UNSIGNED
  name TEXT NOT NULL UNIQUE, -- Nome do papel, ex: 'admin', 'moderator'. No UNA é VARCHAR(64)
  title TEXT NOT NULL, -- Título amigável. No UNA é VARCHAR(255)
  description TEXT, -- Descrição do papel. No UNA é VARCHAR(255)
  active INTEGER NOT NULL DEFAULT 1, -- 0 ou 1. No UNA é TINYINT(4)
  \"order\" INTEGER NOT NULL DEFAULT 0 -- No UNA é INT(11)
);
CREATE INDEX IF NOT EXISTS idx_sys_std_roles_name ON sys_std_roles(name);
```

```sql
CREATE TABLE IF NOT EXISTS sys_std_roles_actions (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11) UNSIGNED
  name TEXT NOT NULL UNIQUE, -- Nome da ação, ex: 'manage_users'. No UNA é VARCHAR(64)
  title TEXT NOT NULL, -- Título amigável. No UNA é VARCHAR(255)
  description TEXT -- Descrição da ação. No UNA é VARCHAR(255)
);
CREATE INDEX IF NOT EXISTS idx_sys_std_roles_actions_name ON sys_std_roles_actions(name);
```

```sql
CREATE TABLE IF NOT EXISTS sys_std_roles_actions2roles (
  role_id INTEGER NOT NULL, -- FK para sys_std_roles.id. No UNA é INT(11) UNSIGNED
  action_id INTEGER NOT NULL, -- FK para sys_std_roles_actions.id. No UNA é INT(11) UNSIGNED
  PRIMARY KEY (role_id, action_id),
  FOREIGN KEY (role_id) REFERENCES sys_std_roles(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (action_id) REFERENCES sys_std_roles_actions(id) ON DELETE CASCADE ON UPDATE CASCADE
);
```

```sql
CREATE TABLE IF NOT EXISTS sys_std_roles_members (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11) UNSIGNED
  account_id INTEGER NOT NULL UNIQUE, -- FK para sys_accounts.id. No UNA é INT(11) UNSIGNED
  role INTEGER NOT NULL, -- FK para sys_std_roles.id. No UNA é INT(11) UNSIGNED
  FOREIGN KEY (account_id) REFERENCES sys_accounts(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (role) REFERENCES sys_std_roles(id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_sys_std_roles_members_role ON sys_std_roles_members(role);
```

```sql
CREATE TABLE IF NOT EXISTS sys_std_widgets_bookmarks (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11) NOT NULL
  widget_id INTEGER NOT NULL, -- FK para sys_std_widgets.id. No UNA é INT(11) UNSIGNED
  profile_id INTEGER NOT NULL, -- FK para sys_profiles.id. No UNA é INT(11) UNSIGNED
  bookmark INTEGER NOT NULL DEFAULT 0, -- 0 ou 1. No UNA é TINYINT(4) UNSIGNED
  PRIMARY KEY (id), -- A PK original do UNA é só `id`
  FOREIGN KEY (widget_id) REFERENCES sys_std_widgets(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
  -- UNIQUE (widget_id, profile_id) no UNA
);
CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_std_widgets_bookmarks_widget_profile ON sys_std_widgets_bookmarks(widget_id, profile_id);
```

## Tabela: `sys_std_widgets`

## Tabela: `sys_std_pages_widgets`

## Tabela: `sys_std_roles`

## Tabela: `sys_std_roles_actions`

## Tabela: `sys_std_roles_actions2roles`

## Tabela: `sys_std_roles_members`

## Tabela: `sys_std_widgets_bookmarks`

*   Adaptações para SQLite incluem uso de `INTEGER` para IDs e booleanos, `TEXT` para strings.
*   Chaves estrangeiras foram adicionadas onde inferidas.
*   Colunas `order` foram colocadas entre aspas.