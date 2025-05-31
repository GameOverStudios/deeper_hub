# Documentação Deeper: Esquema do Banco de Dados para Configurações (`sys_options` e relacionadas) (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas do UNA responsáveis pelo gerenciamento das configurações do sistema.

## Tabela: `sys_options_types`

```sql
CREATE TABLE IF NOT EXISTS sys_options_types (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11) UNSIGNED
  \"group\" TEXT NOT NULL, -- No UNA é VARCHAR(64)
  name TEXT NOT NULL UNIQUE, -- No UNA é VARCHAR(64)
  caption TEXT NOT NULL, -- No UNA é VARCHAR(64)
  icon TEXT, -- No UNA é VARCHAR(255)
  \"order\" INTEGER DEFAULT 0 -- No UNA é INT(11)
);
```

```sql
CREATE TABLE IF NOT EXISTS sys_options_categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11) UNSIGNED
  type_id INTEGER NOT NULL, -- No UNA é INT(11) UNSIGNED, FK para sys_options_types.id
  name TEXT NOT NULL UNIQUE, -- No UNA é VARCHAR(64)
  caption TEXT NOT NULL, -- No UNA é VARCHAR(64)
  hidden INTEGER NOT NULL DEFAULT 0, -- No UNA é TINYINT(1) (0 ou 1)
  \"order\" INTEGER DEFAULT 0, -- No UNA é INT(11)
  FOREIGN KEY (type_id) REFERENCES sys_options_types(id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_sys_options_categories_type_id ON sys_options_categories(type_id);
```

```sql
CREATE TABLE IF NOT EXISTS sys_options (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11) UNSIGNED
  category_id INTEGER NOT NULL, -- No UNA é INT(11) UNSIGNED, FK para sys_options_categories.id
  name TEXT NOT NULL UNIQUE, -- No UNA é VARCHAR(64)
  caption TEXT NOT NULL, -- No UNA é VARCHAR(255)
  info TEXT, -- No UNA é VARCHAR(255)
  value TEXT, -- No UNA é MEDIUMTEXT NOT NULL. Armazena o valor da opção.
  type TEXT NOT NULL DEFAULT 'text' CHECK(type IN (
    'value', 'digit', 'text', 'code', 'checkbox', 'select', 'combobox',
    'file', 'image', 'list', 'rlist', 'rgb', 'rgba', 'datetime'
  )), -- ENUM no UNA
  extra TEXT, -- No UNA é TEXT NOT NULL DEFAULT ''. Para 'select', 'list', etc. (ex: nomes de listas pré-definidas)
  \"check\" TEXT, -- No UNA é VARCHAR(32) (nome de função de validação)
  check_params TEXT, -- No UNA é TEXT
  check_error TEXT, -- No UNA é VARCHAR(255)
  \"order\" INTEGER DEFAULT 0, -- No UNA é INT(11)
  FOREIGN KEY (category_id) REFERENCES sys_options_categories(id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_sys_options_category_id ON sys_options(category_id);
CREATE INDEX IF NOT EXISTS idx_sys_options_name ON sys_options(name);
```

```sql
CREATE TABLE IF NOT EXISTS sys_options_mixes (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11) UNSIGNED
  type TEXT NOT NULL, -- No UNA é VARCHAR(64) (ex: 'template', 'language')
  category TEXT NOT NULL, -- No UNA é VARCHAR(64) (para agrupar mixes, ex: 'Light Themes', 'Dark Themes')
  name TEXT NOT NULL UNIQUE, -- No UNA é VARCHAR(64) (nome do mix, ex: 'lucid_light', 'custom_dark')
  title TEXT NOT NULL, -- No UNA é VARCHAR(64) (título amigável do mix)
  dark INTEGER NOT NULL DEFAULT 0, -- No UNA é TINYINT(1) (0 ou 1)
  active INTEGER NOT NULL DEFAULT 0, -- No UNA é TINYINT(1) (0 ou 1) - indica se este mix é o globalmente ativo para seu tipo
  published INTEGER NOT NULL DEFAULT 0, -- No UNA é TINYINT(1) (0 ou 1)
  editable INTEGER NOT NULL DEFAULT 1 -- No UNA é TINYINT(1) (0 ou 1)
);
CREATE INDEX IF NOT EXISTS idx_sys_options_mixes_type_active ON sys_options_mixes(type, active);
```

```sql
CREATE TABLE IF NOT EXISTS sys_options_mixes2options (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11)
  option_name TEXT NOT NULL, -- No UNA é VARCHAR(64), refere-se a sys_options.name (não FK direta no UNA)
  mix_id INTEGER NOT NULL, -- No UNA é INT(11) UNSIGNED, FK para sys_options_mixes.id
  value TEXT NOT NULL, -- No UNA é MEDIUMTEXT. Valor da opção para este mix específico.
  FOREIGN KEY (mix_id) REFERENCES sys_options_mixes(id) ON DELETE CASCADE ON UPDATE CASCADE
  -- Não há FK para option_name para sys_options.name no UNA, mas seria ideal.
  -- UNIQUE (option_name, mix_id)
);
CREATE INDEX IF NOT EXISTS idx_sys_options_mixes2options_mix_id ON sys_options_mixes2options(mix_id);
CREATE INDEX IF NOT EXISTS idx_sys_options_mixes2options_option_name ON sys_options_mixes2options(option_name);
CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_options_mixes2options_option_mix ON sys_options_mixes2options(option_name, mix_id);
```

*   Agrupa categorias de opções (ex: \"System\", \"Modules\").

## Tabela: `sys_options_categories`

*   Define categorias para agrupar opções (ex: \"General\", \"Security\").

## Tabela: `sys_options`

*   Armazena cada configuração individual.
*   `value`: O valor real da opção, armazenado como texto.
*   `type`: Indica como o valor deve ser interpretado/apresentado.
*   `extra`: Pode conter referências a `sys_form_pre_lists` para opções do tipo `select` ou `list`.

## Tabela: `sys_options_mixes`

*   Define \"mixes\" de configurações, frequentemente usados para temas.

## Tabela: `sys_options_mixes2options`

*   Tabela de junção que armazena os valores específicos das opções para cada mix. Se uma opção existe aqui para um mix ativo, seu valor sobrescreve o valor base de `sys_options`.

### Chaves Estrangeiras e Integridade:

*   As chaves estrangeiras foram definidas para manter a integridade referencial onde aplicável.
*   Lembre-se de `PRAGMA foreign_keys = ON;` para SQLite.