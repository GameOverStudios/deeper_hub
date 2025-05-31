# Documentação Deeper: Visão Geral do Banco de Dados (SQLite)

Este documento fornece uma visão geral de como o esquema do banco de dados do UNA (originalmente em MySQL) será portado e representado em SQLite para o projeto \"Deeper\". Todos os `CREATE TABLE` statements para as tabelas do UNA, adaptados para a sintaxe e tipos de dados do SQLite, serão listados aqui como referência central.

**Nota:** Este arquivo servirá como a \"fonte da verdade\" para a estrutura completa do banco de dados. Módulos individuais podem referenciar tabelas específicas, mas a definição completa reside aqui.

## Considerações na Adaptação MySQL para SQLite

Ao converter o esquema do MySQL para SQLite, as seguintes considerações foram (ou serão) aplicadas:

*   **Tipos de Dados:**
    *   `INT(11)`, `INT(10) UNSIGNED`, `TINYINT(4)`, `BIGINT(20)`: Geralmente mapeados para `INTEGER` em SQLite. O atributo `UNSIGNED` não é diretamente suportado como um tipo distinto, mas o comportamento de armazenamento de inteiros grandes é robusto. `AUTOINCREMENT` em SQLite requer `INTEGER PRIMARY KEY AUTOINCREMENT`.
    *   `VARCHAR(N)`, `CHAR(N)`: Mapeados para `TEXT`. SQLite não impõe restrições de comprimento para `TEXT` da mesma forma que `VARCHAR` no MySQL, mas a lógica da aplicação pode precisar manter essas restrições.
    *   `TEXT`, `MEDIUMTEXT`: Mapeados para `TEXT`.
    *   `DATE`: Mapeado para `TEXT`, armazenando datas no formato ISO 8601 (`YYYY-MM-DD`).
    *   `DATETIME`, `TIMESTAMP (com DEFAULT CURRENT_TIMESTAMP)`: Mapeado para `TEXT`, armazenando data/hora no formato ISO 8601 (`YYYY-MM-DD HH:MM:SS`). Timestamps Unix (inteiros) também são uma opção viável. Para `DEFAULT CURRENT_TIMESTAMP`, SQLite usa `DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%S', 'now'))` ou `DEFAULT (UNIXEPOCH())`.
    *   `FLOAT`, `DOUBLE`: Mapeados para `REAL`.
    *   `ENUM(...)`: Mapeado para `TEXT` com uma `CHECK` constraint para restringir os valores permitidos. Ex: `status TEXT CHECK(status IN ('active', 'pending', 'suspended')) DEFAULT 'active'`.
    *   `BLOB` tipos: Mapeados para `BLOB`.
*   **Chaves Primárias:**
    *   `AUTO_INCREMENT`: No SQLite, é obtido com `INTEGER PRIMARY KEY AUTOINCREMENT`.
    *   Chaves primárias compostas são suportadas: `PRIMARY KEY (col1, col2)`.
*   **Chaves Estrangeiras:**
    *   SQLite suporta chaves estrangeiras. Elas devem ser definidas na criação da tabela.
    *   É crucial habilitar o suporte a chaves estrangeiras em tempo de execução com `PRAGMA foreign_keys = ON;` para cada conexão, se não for o padrão.
    *   Ações `ON DELETE` e `ON UPDATE` (como `CASCADE`, `SET NULL`, `RESTRICT`) são suportadas.
*   **Índices:**
    *   `KEY nome_indice (coluna)`: Mapeado para `CREATE INDEX IF NOT EXISTS nome_indice ON nome_tabela (coluna);`.
    *   Índices `UNIQUE` são criados com `CREATE UNIQUE INDEX IF NOT EXISTS ...`.
*   **Valores Padrão (`DEFAULT`):**
    *   `DEFAULT 0` -> `DEFAULT 0`.
    *   `DEFAULT ''` -> `DEFAULT ''`.
    *   `DEFAULT NULL` é o padrão se não especificado.
*   **Collation (`COLLATE utf8mb4_unicode_ci`):**
    *   SQLite usa UTF-8 por padrão para o tipo `TEXT`.
    *   Funções de collation específicas (`NOCASE`, `RTRIM`, `BINARY`) podem ser aplicadas por coluna na definição da tabela ou em queries. Para a maioria dos casos, o comportamento padrão do UTF-8 do SQLite é suficiente.
*   **Storage Engines (`ENGINE=MyISAM`, `ENGINE=InnoDB`):**
    *   Irrelevante para SQLite, pois ele não possui o conceito de múltiplos storage engines.
*   **`SET SQL_MODE = \"NO_AUTO_VALUE_ON_ZERO\"` e `SET time_zone = \"+00:00\"`:**
    *   `NO_AUTO_VALUE_ON_ZERO`: Não diretamente aplicável. O comportamento de `AUTOINCREMENT` do SQLite é diferente.
    *   `time_zone`: SQLite armazena datas/horas como texto ou números sem informação de fuso horário intrínseca. A aplicação deve gerenciar conversões de fuso horário. É recomendado armazenar tudo em UTC.
*   **`FULLTEXT KEY`:**
    *   SQLite possui módulos FTS (FTS3, FTS4, FTS5) para busca full-text. A sintaxe e implementação são diferentes do MySQL.
    *   **Ação Inicial:** Para a primeira passagem, as `FULLTEXT KEY` serão **omitidas**. Elas podem ser adicionadas posteriormente usando as extensões FTS do SQLite se a funcionalidade for crítica. Isso simplifica a portabilidade inicial do esquema.

## Estrutura das Tabelas (Esquema UNA Portado para SQLite)

**Atenção:** Dada a extensão do esquema original do UNA (mais de 150 tabelas), listar todos os `CREATE TABLE` statements aqui de uma vez seria excessivamente longo para esta interação.

**Proposta de Abordagem para este Documento:**

1.  **Listagem Progressiva:** À medida que avançamos no desenvolvimento de cada módulo (ex: `sys_accounts`, `bx_persons_data`), os `CREATE TABLE` statements correspondentes serão adicionados a este documento.
2.  **Referência Cruzada:** Os documentos `database_schema.md` dentro de cada subdiretório de módulo (`docs/01_system_core/sys_accounts_and_profiles/database_schema.md`) conterão os `CREATE TABLE` para *suas* tabelas específicas, e este arquivo central servirá como um agregador ou um índice para todas elas, garantindo consistência.

**Exemplo Inicial (para ilustrar o formato):**

```sql
-- Tabela: schema_migrations (do exemplo original, não faz parte do core UNA diretamente, mas útil para o versionamento do esquema do Deeper)
CREATE TABLE IF NOT EXISTS schema_migrations (
  version INTEGER PRIMARY KEY, -- SQLite BIGINT é INTEGER
  inserted_at TEXT -- DATETIME como TEXT
);

-- Tabela: sys_accounts (adaptada)
CREATE TABLE IF NOT EXISTS sys_accounts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  profile_id INTEGER,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  email_confirmed INTEGER NOT NULL DEFAULT 0, -- 0 for false, 1 for true
  phone TEXT,
  phone_confirmed INTEGER NOT NULL DEFAULT 0,
  receive_updates INTEGER NOT NULL DEFAULT 1,
  receive_news INTEGER NOT NULL DEFAULT 1,
  password_hash TEXT NOT NULL,
  -- password_changed INTEGER, -- Unix Timestamp
  -- salt TEXT, -- Se o hash já inclui salt
  role INTEGER NOT NULL DEFAULT 1,
  lang_id INTEGER DEFAULT 0,
  added INTEGER NOT NULL, -- Unix Timestamp
  changed INTEGER NOT NULL, -- Unix Timestamp
  logged INTEGER, -- Unix Timestamp
  ip TEXT,
  referred TEXT,
  login_attempts INTEGER NOT NULL DEFAULT 0,
  locked INTEGER NOT NULL DEFAULT 0,
  active INTEGER NOT NULL DEFAULT 0,
  -- FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) -- Adicionar quando sys_profiles for definido
);

CREATE INDEX IF NOT EXISTS idx_sys_accounts_email ON sys_accounts(email);
CREATE INDEX IF NOT EXISTS idx_sys_accounts_profile_id ON sys_accounts(profile_id);

-- ... (Outras tabelas do UNA serão adicionadas aqui progressivamente) ...
```

**Próximos Passos:**

À medida que documentamos cada módulo do UNA para portabilidade para \"Deeper\", os `CREATE TABLE` statements relevantes serão definidos e adicionados aqui e nos respectivos `database_schema.md` dos módulos.