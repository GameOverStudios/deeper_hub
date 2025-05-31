# Documentação Deeper: Esquema do Banco de Dados para Localização (`sys_localization_*`) (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas do UNA responsáveis pelo gerenciamento da internacionalização e localização.

## Tabela: `sys_localization_languages`

```sql
CREATE TABLE IF NOT EXISTS sys_localization_languages (
  ID INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(10) UNSIGNED
  Name TEXT NOT NULL UNIQUE, -- Código do idioma, ex: 'en', 'pt-BR'. No UNA é VARCHAR(5)
  Flag TEXT, -- Código do país para flag, ex: 'us', 'br'. No UNA é VARCHAR(2)
  Title TEXT NOT NULL, -- Nome amigável do idioma, ex: 'English', 'Português (Brasil)'. No UNA é VARCHAR(255)
  Direction TEXT NOT NULL DEFAULT 'LTR' CHECK(Direction IN ('LTR', 'RTL')), -- ENUM('LTR','RTL') no UNA
  LanguageCountry TEXT, -- Código completo ex: 'en-US', 'pt-BR'. No UNA é VARCHAR(8)
  Enabled INTEGER NOT NULL DEFAULT 0 -- 0 for false, 1 for true. No UNA é TINYINT(1) UNSIGNED
);
CREATE INDEX IF NOT EXISTS idx_sys_localization_languages_name ON sys_localization_languages(Name);
CREATE INDEX IF NOT EXISTS idx_sys_localization_languages_enabled ON sys_localization_languages(Enabled);
```

```sql
CREATE TABLE IF NOT EXISTS sys_localization_categories (
  ID INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(6) UNSIGNED
  Name TEXT NOT NULL UNIQUE -- Nome da categoria, ex: 'System', 'bx_persons'. No UNA é VARCHAR(255)
);
CREATE INDEX IF NOT EXISTS idx_sys_localization_categories_name ON sys_localization_categories(Name);
```

```sql
CREATE TABLE IF NOT EXISTS sys_localization_keys (
  ID INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(10) UNSIGNED
  IDCategory INTEGER NOT NULL, -- FK para sys_localization_categories.ID. No UNA é INT(6) UNSIGNED
  \"Key\" TEXT NOT NULL UNIQUE, -- A chave de tradução, ex: '_sys_txt_hello'. No UNA é VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_bin
  FOREIGN KEY (IDCategory) REFERENCES sys_localization_categories(ID) ON DELETE CASCADE ON UPDATE CASCADE
);
-- O UNA usa utf8_bin para Key para garantir unicidade case-sensitive. SQLite UNIQUE é case-insensitive por padrão para TEXT,
-- a menos que uma collation BINARY seja especificada na coluna ou no índice.
-- CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_localization_keys_key_cs ON sys_localization_keys(\"Key\" COLLATE BINARY);
-- A linha acima pode ser necessária para emular o comportamento case-sensitive do UNA. Por simplicidade inicial, um UNIQUE normal.
CREATE INDEX IF NOT EXISTS idx_sys_localization_keys_idcategory ON sys_localization_keys(IDCategory);
CREATE INDEX IF NOT EXISTS idx_sys_localization_keys_key ON sys_localization_keys(\"Key\"); -- Para buscas pela chave
```

```sql
CREATE TABLE IF NOT EXISTS sys_localization_strings (
  IDKey INTEGER NOT NULL, -- FK para sys_localization_keys.ID. No UNA é INT(10) UNSIGNED
  IDLanguage INTEGER NOT NULL, -- FK para sys_localization_languages.ID. No UNA é INT(10) UNSIGNED
  String TEXT NOT NULL, -- A string traduzida efetiva. No UNA é MEDIUMTEXT
  PRIMARY KEY (IDKey, IDLanguage),
  FOREIGN KEY (IDKey) REFERENCES sys_localization_keys(ID) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (IDLanguage) REFERENCES sys_localization_languages(ID) ON DELETE CASCADE ON UPDATE CASCADE
);
-- O índice FULLTEXT `String` do MySQL não é portado diretamente.
-- Se busca full-text nas traduções for necessária, usar FTS do SQLite.
CREATE INDEX IF NOT EXISTS idx_sys_localization_strings_idlanguage ON sys_localization_strings(IDLanguage);
```

*   Define os idiomas disponíveis no sistema.

## Tabela: `sys_localization_categories`

*   Agrupa chaves de tradução, geralmente por módulo ou funcionalidade.

## Tabela: `sys_localization_keys`

*   Armazena as chaves únicas de tradução.
*   A coluna `Key` é referenciada como `\"Key\"` para evitar conflito com a palavra reservada.

## Tabela: `sys_localization_strings`

*   Contém as traduções reais, ligando uma chave (`IDKey`) a um idioma (`IDLanguage`) e à string traduzida.
*   A chave primária composta `(IDKey, IDLanguage)` garante que cada chave tenha apenas uma tradução por idioma.

### Chaves Estrangeiras e Integridade:
*   As chaves estrangeiras foram definidas para manter a integridade referencial.
*   Lembre-se de `PRAGMA foreign_keys = ON;` para SQLite.