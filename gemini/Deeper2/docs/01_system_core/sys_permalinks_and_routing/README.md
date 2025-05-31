# Documentação Deeper: Permalinks e Roteamento da API (`sys_permalinks`)

Esta seção da API \"Deeper\" aborda como o sistema de permalinks do UNA (principalmente a tabela `sys_permalinks` e `sys_rewrite_rules`) será utilizado ou adaptado para o roteamento dentro da API Elixir e para ajudar o cliente a construir URLs amigáveis.

No UNA PHP, os permalinks transformam URLs amigáveis (ex: `/m/persons/home`) em parâmetros internos (`page.php?i=persons_home`). Para a API \"Deeper\", o objetivo é um pouco diferente:

1.  **Resolução de Caminhos (Opcional via API):** O cliente pode ter um \"caminho\" (ex: `/nome-do-perfil` ou `/artigo/titulo-do-artigo`) e precisar que a API o resolva para um tipo de recurso e ID específico (ex: `type: 'profile', id: 123` ou `type: 'article', content_uri: 'titulo-do-artigo'`).
2.  **Geração de Links (Lógica do Cliente):** A API fornecerá dados, e o cliente será o principal responsável por gerar as URLs amigáveis que usa para navegação interna. A API pode, no entanto, fornecer os \"slugs\" ou URIs de conteúdo (ex: `bx_persons_data.uri`) que o cliente usará para compor essas URLs.
3.  **Roteamento Interno da API (Phoenix Router):** O roteador do Phoenix precisará de uma estratégia para lidar com rotas dinâmicas que podem corresponder a perfis, páginas de conteúdo, etc., baseadas em slugs ou URIs armazenados no banco de dados.

## Tabelas Relevantes do UNA:

*   **`sys_permalinks`**: Contém mapeamentos de URLs \"standard\" (com query params) para permalinks (URLs amigáveis). Ex: `page.php?i=nome_pagina` -> `/m/modulo/nome_pagina`.
*   **`sys_rewrite_rules`**: Regras de reescrita mais genéricas baseadas em regex para transformar URLs.
*   Muitos módulos de conteúdo (como `bx_persons_data`) têm um campo `uri` que armazena o \"slug\" do item de conteúdo (ex: `john-doe-profile`).

## Abordagem para a API \"Deeper\":

*   **Foco nos URIs/Slugs de Conteúdo:** A API, ao retornar dados de entidades como perfis ou artigos, incluirá o `uri` (slug) desses itens. O cliente usará esses slugs para construir as URLs amigáveis.
*   **Endpoint de Resolução (Opcional):** Um endpoint como `POST /api/v1/resolve-path` pode ser criado. O cliente envia um caminho (ex: `/john-doe`) e a API tenta identificar a que recurso (tipo e ID) esse caminho corresponde, consultando `sys_permalinks` ou os campos `uri` das tabelas de conteúdo.
*   **Roteamento no Phoenix:**
    *   Rotas explícitas para coleções e recursos conhecidos (ex: `GET /api/v1/profiles`, `GET /api/v1/profiles/{id}`).
    *   Para URLs mais dinâmicas que representam conteúdo (ex: `/{user_slug}` ou `/{article_slug}` no frontend, que o cliente traduziria para chamadas API como `GET /api/v1/profiles/slug/{user_slug}`), o Phoenix pode ter rotas com parâmetros dinâmicos. A lógica no controller correspondente tentaria encontrar o recurso pelo slug.

## Documentação Detalhada:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite das tabelas `sys_permalinks` e `sys_rewrite_rules`.

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir para criar essas tabelas.

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o `Deeper.SystemCore.RoutingRepo` (ou `PermalinksRepo`) e suas funções para consultar `sys_permalinks` e `sys_rewrite_rules`, ou para buscar conteúdo por `uri`/slug.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica o endpoint `POST /resolve-path` (se implementado).

## Considerações:

*   A complexidade do sistema de permalinks e reescrita do UNA pode ser alta. Para a API \"Deeper\", uma abordagem simplificada focada em slugs de conteúdo e um endpoint de resolução pode ser mais pragmática inicialmente.
*   A maior parte da \"magia\" do roteamento acontecerá no cliente (para navegação) e no roteador do Phoenix (para direcionar para os controllers corretos da API). A tabela `sys_permalinks` pode ser mais uma fonte de dados para o endpoint de resolução do que um motor de roteamento direto para a API REST.