# Documentação Deeper: Permalinks e Roteamento da API

Este documento descreve a estratégia para lidar com permalinks (URLs amigáveis) do sistema UNA no contexto da API \"Deeper\" e como o roteamento da API pode ser influenciado ou auxiliar o cliente remoto.

**Objetivo Principal:** Permitir que o cliente remoto possa, opcionalmente, usar URLs amigáveis (semelhantes às do UNA) e que a API \"Deeper\" possa interpretar essas URLs para fornecer os dados corretos da \"página UNA\" correspondente.

## Tabelas Relevantes do UNA:

1.  **`sys_permalinks`**:
    *   Armazena o mapeamento entre URLs \"standard\" (com query parameters, ex: `page.php?i=view-profile&id=123`) e URLs \"permalink\" (amigáveis, ex: `/profile/john-doe`).
    *   Campos: `id`, `standard`, `permalink`, `check` (nome de uma classe/método PHP no UNA para verificar a validade do permalink ou buscar o conteúdo), `compare_by_prefix`.
2.  **`sys_rewrite_rules`** (Relacionado, mas mais para reescrita interna no servidor web Apache/Nginx no UNA):
    *   Regras de reescrita. Para a API \"Deeper\", o foco principal será em como `sys_permalinks` influencia a busca de dados.

## Desafios e Abordagem para a API \"Deeper\":

O sistema de permalinks do UNA é intrinsecamente ligado à forma como o PHP renderiza páginas. Uma URL amigável no UNA é geralmente processada para identificar um \"objeto de página\" (`sys_objects_page.object` ou `uri`) e quaisquer parâmetros (como um ID de conteúdo).

A API \"Deeper\" não vai *executar* o código PHP da coluna `sys_permalinks.check`. Em vez disso, ela pode usar os permalinks para ajudar a identificar qual \"objeto de página\" ou recurso da API deve ser acessado.

**Estratégia Proposta:**

1.  **Cliente Lida com Roteamento Principal:** O cliente remoto (SPA, aplicação mobile) terá seu próprio sistema de roteamento. Ele decide quais componentes renderizar com base na URL atual no navegador do cliente.

2.  **API para Resolver Permalinks (Opcional, mas Útil):**
    *   A API \"Deeper\" pode oferecer um endpoint para \"resolver\" um permalink, ou seja, dado um caminho de URL amigável, ela tenta encontrar a URL \"standard\" do UNA ou, mais utilmente, o **objeto de página UNA** e os **parâmetros** associados.
    *   **Endpoint:** `POST /api/v1/system/routing/resolve-path`
        *   **Corpo da Requisição (JSON):**

```json
            {
              \"path\": \"/profile/john-doe\" // O caminho da URL amigável
            }
```

```json
            {
              \"data\": {
                \"resolved\": true,
                \"una_standard_url\": \"page.php?i=bx_persons_view&id=789\", // A URL standard original do UNA
                \"page_object_uri\": \"bx_persons_view\", // O URI do sys_objects_page
                \"params\": { // Parâmetros extraídos ou associados
                  \"id\": 789 // Ex: ID do perfil
                },
                \"permalink_info\": { // Metadados do permalink encontrado
                    \"id\": 10,
                    \"permalink\": \"/profile/john-doe\",
                    \"check_original\": \"BxPersonsView\" // O valor original da coluna 'check'
                }
              }
            }
```

```json
            {
              \"data\": {
                \"resolved\": false,
                \"path\": \"/profile/john-doe\"
              }
            }
```

```json
    {
      \"data\": {
        \"resolved\": true,
        \"page_object_uri\": \"bx_persons_view\",
        \"params\": { \"id\": 789 } // Supondo que \"john-doe\" mapeia para o perfil com ID 789
      }
    }
```

```sql
CREATE TABLE IF NOT EXISTS sys_permalinks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  standard TEXT NOT NULL, -- ex: 'page.php?i=view-profile&id=123'
  permalink TEXT NOT NULL UNIQUE, -- ex: '/profile/john-doe'
  \"check\" TEXT NOT NULL, -- Nome da classe/método PHP original, armazenado para referência
  compare_by_prefix INTEGER NOT NULL DEFAULT 0 -- 0 ou 1
);

CREATE INDEX IF NOT EXISTS idx_sys_permalinks_permalink ON sys_permalinks(permalink);
-- Um índice em 'standard' pode ser útil se houver busca reversa.
```

        *   **Resposta de Sucesso (200 OK):**

            ou, se não resolvido:

        *   **Lógica do Backend (`Deeper.SystemCore.RoutingRepo`):**
            1.  Buscar em `sys_permalinks` por uma correspondência com `permalink` ou usando `compare_by_prefix`.
                *   SQL: `SELECT id, standard, permalink, \"check\" FROM sys_permalinks WHERE permalink = ? OR (? LIKE permalink || '%' AND compare_by_prefix = 1) ORDER BY LENGTH(permalink) DESC LIMIT 1;`
            2.  Se encontrado, parsear `standard` para extrair o nome da página/parâmetro `i` (que geralmente corresponde a `sys_objects_page.uri`) e outros query parameters (como `id`, `profile_id`, etc.).
            3.  Retornar essas informações.

3.  **Cliente Usa Informações Resolvidas para Chamar a API de Página:**
    *   Após resolver o caminho, o cliente teria o `page_object_uri` (ex: `bx_persons_view`) e os `params` (ex: `id=789`).
    *   O cliente então chamaria o endpoint da API de páginas: `GET /api/v1/pages?uri=bx_persons_view&param_id=789` (ou uma estrutura de parâmetros mais genérica).
    *   A API de páginas (`Deeper.PageRenderingEngine.PageController`) usaria esses parâmetros para buscar os dados da página e seus blocos, conforme definido em `docs/02_page_rendering_engine/sys_objects_page/README.md`.

4.  **Mapeamento Direto no Roteador do Cliente (Alternativa):**
    *   Se os padrões de permalink forem conhecidos e relativamente estáveis, o cliente pode ter rotas que mapeiam diretamente para chamadas à API de páginas, sem precisar do endpoint de resolução para cada navegação.
    *   Ex: Rota do cliente `/profile/:username` -> Componente que chama `GET /api/v1/pages?uri=bx_persons_view&username=:username`. A API de páginas precisaria então de lógica para buscar `content_id` com base no `username` antes de buscar os blocos.

**Vantagens do Endpoint de Resolução:**

*   **Flexibilidade:** Permite que os permalinks sejam gerenciados no banco de dados do UNA sem exigir alterações constantes no código de roteamento do cliente.
*   **Consistência:** Ajuda a manter a lógica de resolução de URLs centralizada no backend, que tem acesso direto à tabela `sys_permalinks`.
*   **Migração Gradual:** Facilita a transição se o cliente precisar suportar URLs legadas do UNA.

### Módulo de Acesso a Dados (`Deeper.SystemCore.RoutingRepo` ou `PermalinksRepo`):

*   **`resolve_permalink(path :: String.t()) :: {:ok, resolution_map :: map()} | {:error, :not_found}`**
    *   Implementa a lógica de busca em `sys_permalinks` e parsing da URL `standard`.
    *   O `resolution_map` conteria `una_standard_url`, `page_object_uri`, `params`, etc.

## Tabelas de Permalinks (Esquema SQLite):

O `CREATE TABLE` statement para `sys_permalinks` precisará ser definido no `docs/00_core_concepts/database_schema_sqlite.md` e ter sua respectiva migração Elixir.

**Exemplo `sys_permalinks` (SQLite):**

## Fluxo de Roteamento no Cliente (usando o resolver):

1.  Usuário navega para `/profile/john-doe` no cliente.
2.  Roteador do cliente intercepta `/profile/john-doe`.
3.  Cliente faz `POST /api/v1/system/routing/resolve-path` com `{ \"path\": \"/profile/john-doe\" }`.
4.  API \"Deeper\" responde com:

5.  Cliente usa `page_object_uri` e `params` para fazer uma segunda chamada à API: `GET /api/v1/pages?uri=bx_persons_view&param_id=789`.
    *   (A API de páginas precisa ter uma forma de aceitar parâmetros genéricos e passá-los para a lógica de busca de blocos ou para os \"serviços\" de blocos).
6.  API de páginas retorna a estrutura da página e dos blocos.
7.  Cliente renderiza a página.

## Considerações:

*   **Performance:** Fazer duas chamadas API (resolver + buscar página) para cada navegação baseada em permalink pode adicionar latência. O cliente pode cachear os resultados da resolução de permalinks.
*   **Complexidade da Lógica de `check`:** A coluna `sys_permalinks.check` no UNA original contém o nome de uma classe PHP que realiza verificações ou busca dados. A API \"Deeper\" não executará esse PHP. Portanto, o parsing da URL `standard` para extrair o objeto de página e os parâmetros é a abordagem mais viável. A API pode precisar de alguma inteligência para mapear certos padrões em `standard` (como `profile.php?ID=...`) para os parâmetros corretos para a API de páginas.
*   **Parâmetros de Bloco:** Se os blocos de uma página UNA dependem de parâmetros da URL que foram resolvidos pelo permalink, esses parâmetros precisam ser passados para a API de páginas e, subsequentemente, para a lógica que busca/renderiza os dados do bloco. O endpoint `GET /api/v1/pages` deve aceitar um conjunto flexível de `param_KEY=VALUE`.

Esta abordagem fornece uma maneira de desacoplar o roteamento do cliente da complexidade dos permalinks do UNA, ao mesmo tempo que permite que a API \"Deeper\" utilize essas informações para servir o conteúdo correto.