# Documentação Deeper: Esquema do Banco de Dados para Localização (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas do sistema de localização do UNA: `sys_localization_languages`, `sys_localization_categories`, `sys_localization_keys`, e `sys_localization_strings`.

## Tabela: `sys_localization_languages`

```sql
CREATE TABLE IF NOT EXISTS sys_localization_languages (
  ID INTEGER PRIMARY KEY AUTOINCREMENT,
  Name TEXT NOT NULL UNIQUE, -- Código do idioma, ex: 'en', 'pt-BR'
  Flag TEXT, -- Código do país para ícone, ex: 'us', 'br'
  Title TEXT NOT NULL, -- Nome amigável do idioma, ex: 'English', 'Português (Brasil)'
  Direction TEXT NOT NULL DEFAULT 'LTR' CHECK(Direction IN ('LTR', 'RTL')),
  LanguageCountry TEXT, -- Código de localidade completo, ex: 'en-US', 'pt-BR'
  Enabled INTEGER NOT NULL DEFAULT 0 -- 0 para desabilitado, 1 para habilitado
);
```

```sql
CREATE TABLE IF NOT EXISTS sys_localization_categories (
  ID INTEGER PRIMARY KEY AUTOINCREMENT,
  Name TEXT NOT NULL UNIQUE -- Nome da categoria, ex: 'System', 'bx_persons'
);
```

```sql
CREATE TABLE IF NOT EXISTS sys_localization_keys (
  ID INTEGER PRIMARY KEY AUTOINCREMENT,
  IDCategory INTEGER NOT NULL, -- FK para sys_localization_categories.ID
  \"Key\" TEXT NOT NULL UNIQUE, -- A chave de tradução, ex: '_sys_txt_welcome' (Aspas por ser palavra reservada)
  FOREIGN KEY (IDCategory) REFERENCES sys_localization_categories(ID) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sys_localization_keys_idcategory ON sys_localization_keys(IDCategory);
```

```sql
CREATE TABLE IF NOT EXISTS sys_localization_strings (
  IDKey INTEGER NOT NULL, -- FK para sys_localization_keys.ID
  IDLanguage INTEGER NOT NULL, -- FK para sys_localization_languages.ID
  String TEXT NOT NULL, -- O texto traduzido
  PRIMARY KEY (IDKey, IDLanguage),
  FOREIGN KEY (IDKey) REFERENCES sys_localization_keys(ID) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (IDLanguage) REFERENCES sys_localization_languages(ID) ON DELETE CASCADE ON UPDATE CASCADE
);
```

## Tabela: `sys_localization_categories`

## Tabela: `sys_localization_keys`

*   **`\"Key\"`**: A string literal que é usada no código/templates para buscar uma tradução. Colocada entre aspas pois `KEY` é uma palavra reservada SQL.

## Tabela: `sys_localization_strings`

*   A chave primária composta `(IDKey, IDLanguage)` garante uma única tradução por chave por idioma.