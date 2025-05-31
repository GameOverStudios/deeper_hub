# Documentação Deeper: Esquema do Banco de Dados para Permalinks (SQLite)

Este documento define o `CREATE TABLE` statement para SQLite da tabela `sys_permalinks` do UNA. A tabela `sys_rewrite_rules` é geralmente específica para o ambiente de servidor web do UNA (como Apache mod_rewrite) e pode não ser diretamente portada ou utilizada pelo backend \"Deeper\", que usará o roteamento do Phoenix.

## Tabela: `sys_permalinks`

```sql
CREATE TABLE IF NOT EXISTS sys_permalinks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  standard TEXT NOT NULL, -- A URL padrão do sistema UNA (ex: 'page.php?i=bx_persons_home')
  permalink TEXT NOT NULL, -- A URL amigável (ex: '/m/persons/home')
  \"check\" TEXT NOT NULL, -- Nome de uma classe/método de verificação no UNA PHP (ex: 'BxPersonsModule::check_permalinks')
  compare_by_prefix INTEGER NOT NULL DEFAULT 0 -- 0 ou 1
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_sys_permalinks_permalink ON sys_permalinks(permalink);
CREATE INDEX IF NOT EXISTS idx_sys_permalinks_standard ON sys_permalinks(standard);
CREATE INDEX IF NOT EXISTS idx_sys_permalinks_check ON sys_permalinks(\"check\");
```

*   **`standard`**: A URL interna do sistema UNA que o permalink representa.
*   **`permalink`**: A URL amigável (SEO-friendly).
*   **`\"check\"`**: No UNA PHP, esta é uma chamada de serviço usada para validar ou processar o permalink. Para \"Deeper\", esta coluna pode ser mais informativa sobre a origem/tipo do permalink. A lógica de validação será do Phoenix ou dos controllers da API.
*   **`compare_by_prefix`**: Um flag usado pelo sistema de permalinks do UNA para correspondência.

**Uso no \"Deeper\":**
A tabela `sys_permalinks` pode ser consultada pela API \"Deeper\" para:
1.  Dado um `permalink`, encontrar o `standard` e, a partir do `standard`, extrair o identificador do objeto/página (ex: `bx_persons_home` de `page.php?i=bx_persons_home`).
2.  Para um dado `standard` (ou um objeto de conteúdo), encontrar o `permalink` associado para ser retornado ao cliente.

A lógica de `check` e `compare_by_prefix` é menos relevante para a API \"Deeper\" em si, mas pode informar como os permalinks foram originalmente construídos ou validados no UNA.