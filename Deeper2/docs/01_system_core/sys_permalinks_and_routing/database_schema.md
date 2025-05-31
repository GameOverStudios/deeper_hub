# Documentação Deeper: Esquema do BD para Permalinks e Regras de Reescrita (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas do UNA relacionadas ao sistema de permalinks e regras de reescrita de URL.

## Tabela: `sys_permalinks`

```sql
CREATE TABLE IF NOT EXISTS sys_permalinks (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11) UNSIGNED
  standard TEXT NOT NULL, -- URL padrão com query params, ex: 'page.php?i=nome_pagina'. No UNA é VARCHAR(128)
  permalink TEXT NOT NULL, -- URL amigável, ex: '/m/modulo/nome_pagina'. No UNA é VARCHAR(128)
  \"check\" TEXT NOT NULL, -- Nome de uma classe/método de verificação no UNA. No UNA é VARCHAR(64)
  compare_by_prefix INTEGER NOT NULL DEFAULT 0 -- 0 ou 1. No UNA é TINYINT(4)
);

CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_permalinks_check ON sys_permalinks(standard(80), permalink(80), \"check\"(30)); -- Adaptação do índice UNIQUE original. SQLite não suporta prefixos de índice diretamente em CREATE INDEX.
-- Para SQLite, um índice único em todas as colunas seria:
CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_permalinks_all ON sys_permalinks(standard, permalink, \"check\");
-- Ou, se os prefixos são realmente para evitar o limite de tamanho da chave do índice MySQL:
CREATE INDEX IF NOT EXISTS idx_sys_permalinks_permalink ON sys_permalinks(permalink);
CREATE INDEX IF NOT EXISTS idx_sys_permalinks_standard ON sys_permalinks(standard);
```

```sql
CREATE TABLE IF NOT EXISTS sys_rewrite_rules (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(10) UNSIGNED
  preg TEXT NOT NULL, -- Expressão regular Perl-compatible (PCRE). No UNA é VARCHAR(255)
  service TEXT NOT NULL, -- Serviço a ser chamado no UNA PHP (geralmente um service call serializado). No UNA é VARCHAR(255)
  active INTEGER NOT NULL DEFAULT 1 -- 0 ou 1. No UNA é TINYINT(4)
);
```

*   Mapeia URLs \"padrão\" (com parâmetros) para URLs \"amigáveis\" (permalinks).
*   **Índice `uidx_sys_permalinks_check`:** O UNA tem um índice `UNIQUE KEY check (standard(80),permalink(80),check(30))`. O SQLite não suporta especificar comprimentos de prefixo em `CREATE INDEX` da mesma forma.
    *   Uma opção é criar um índice `UNIQUE` nas colunas completas: `CREATE UNIQUE INDEX uidx_sys_permalinks_all ON sys_permalinks(standard, permalink, \"check\");`.
    *   Outra é ter índices separados se a preocupação principal for a busca rápida, e a unicidade for garantida pela aplicação ou por um índice único nas colunas que realmente precisam ser únicas (ex: `permalink`). A coluna `\"check\"` pode não precisar ser parte da unicidade estrita no contexto da API Deeper.
*   A coluna `\"check\"` refere-se a uma lógica de validação no UNA PHP que pode não ser diretamente portável ou necessária para a resolução de caminhos na API Deeper.

## Tabela: `sys_rewrite_rules`

*   Define regras de reescrita de URL mais genéricas usando expressões regulares.
*   A coluna `service` contém uma chamada de serviço PHP, o que torna a portabilidade direta para a API Deeper complexa. A API pode ler essas regras, mas a execução do \"serviço\" precisaria ser reimplementada ou interpretada.

### Considerações para a API \"Deeper\":

*   A tabela `sys_permalinks` pode ser útil para um endpoint `POST /resolve-path` onde o cliente envia um `permalink` e a API retorna o `standard` path ou, idealmente, informações sobre o recurso (tipo, id) que ele representa.
*   A tabela `sys_rewrite_rules` é mais complexa de utilizar diretamente devido à sua dependência da execução de `service` calls PHP. Seu uso na API Deeper pode ser limitado ou exigir uma reinterpretação significativa.
*   Para muitos casos, buscar conteúdo diretamente por um campo `uri` (slug) nas tabelas de conteúdo (ex: `bx_persons_data.uri`) pode ser uma abordagem mais direta e performática para a API.