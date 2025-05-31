# Documentação Deeper: Esquema do BD para Gerenciamento de Módulos (SQLite)

Este documento define o `CREATE TABLE` statement para SQLite da tabela `sys_modules`, que é a principal tabela do UNA para armazenar informações sobre os módulos do sistema.

As tabelas `sys_modules_file_tracks` e `sys_modules_relations` são mais específicas do ciclo de vida e atualizações dos módulos no ambiente PHP do UNA e podem não ser diretamente consultadas pela API de leitura inicial do \"Deeper\", mas podem ser adicionadas aqui se necessário.

## Tabela: `sys_modules`

```sql
CREATE TABLE IF NOT EXISTS sys_modules (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11) UNSIGNED
  type TEXT NOT NULL DEFAULT 'module', -- No UNA é VARCHAR(16)
  subtypes INTEGER NOT NULL DEFAULT 0, -- No UNA é INT(11) UNSIGNED (bitmask para subtipos)
  name TEXT NOT NULL UNIQUE, -- Nome único do módulo, ex: 'bx_persons'. No UNA é VARCHAR(32)
  title TEXT NOT NULL, -- Título amigável, ex: 'Persons'. No UNA é VARCHAR(255)
  vendor TEXT NOT NULL, -- Fornecedor do módulo, ex: 'UNA'. No UNA é VARCHAR(64)
  version TEXT NOT NULL, -- Versão do módulo, ex: '13.0.0'. No UNA é VARCHAR(32)
  help_url TEXT, -- URL de ajuda. No UNA é VARCHAR(128)
  path TEXT NOT NULL UNIQUE, -- Caminho relativo para os arquivos do módulo. No UNA é VARCHAR(255)
  uri TEXT NOT NULL UNIQUE, -- URI base para o módulo, ex: 'persons'. No UNA é VARCHAR(32)
  class_prefix TEXT NOT NULL UNIQUE, -- Prefixo de classe, ex: 'BxPersons'. No UNA é VARCHAR(32)
  db_prefix TEXT NOT NULL UNIQUE, -- Prefixo de tabela no BD, ex: 'bx_persons_'. No UNA é VARCHAR(32)
  lang_category TEXT NOT NULL, -- Categoria de idioma para traduções, ex: 'Persons'. No UNA é VARCHAR(64)
  dependencies TEXT, -- Nomes de módulos dependentes, separados por vírgula. No UNA é VARCHAR(255)
  date INTEGER NOT NULL, -- Timestamp de instalação/atualização. No UNA é INT(11) UNSIGNED
  enabled INTEGER NOT NULL DEFAULT 0, -- 0 para desabilitado, 1 para habilitado. No UNA é TINYINT(1)
  pending_uninstall INTEGER NOT NULL DEFAULT 0, -- 0 ou 1. No UNA é TINYINT(4)
  hash TEXT, -- Hash dos arquivos do módulo. No UNA é VARCHAR(32)
  updated INTEGER -- Timestamp da última verificação de atualização. No UNA é INT(11) UNSIGNED
);

CREATE INDEX IF NOT EXISTS idx_sys_modules_name ON sys_modules(name);
CREATE INDEX IF NOT EXISTS idx_sys_modules_uri ON sys_modules(uri);
CREATE INDEX IF NOT EXISTS idx_sys_modules_enabled ON sys_modules(enabled);
```

*   Armazena metadados sobre cada módulo instalado no sistema UNA.
*   **`subtypes`**: É uma bitmask no UNA. Para a API, pode ser retornado como um inteiro.
*   **`dependencies`**: Uma string com nomes de módulos separados por vírgula. A API pode retornar isso como está ou tentar parsear para uma lista.
*   **`enabled`**: Crucial para a API \"Deeper\" entender o status do módulo.
*   As constraints `UNIQUE` em `name`, `path`, `uri`, `class_prefix`, `db_prefix` são importantes.