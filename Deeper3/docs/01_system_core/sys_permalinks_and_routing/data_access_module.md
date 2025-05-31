# Documentação Deeper: Módulo de Acesso a Dados para Permalinks e Roteamento (`RoutingRepo`)

Este documento descreve o módulo Elixir `Deeper.SystemCore.RoutingRepo`. Seu objetivo principal é fornecer funcionalidades para ajudar a resolver caminhos de URL (permalinks ou slugs) para recursos específicos dentro do sistema \"Deeper\". Ele interage principalmente com a tabela `sys_permalinks` e pode também precisar consultar campos `uri` em tabelas de conteúdo (como `bx_persons_data.uri`).

A tabela `sys_rewrite_rules` é mais complexa de ser utilizada diretamente devido à sua dependência de \"service calls\" PHP e pode ter um papel limitado ou exigir uma reinterpretação significativa no contexto da API \"Deeper\".

**Localização do Código:** `lib/deeper/system_core/routing_repo.ex`

## Funções Principais (Exemplos):

### 1. Resolver um Permalink (da tabela `sys_permalinks`)

*   **`resolve_permalink(permalink_path :: String.t()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Tenta encontrar uma correspondência para `permalink_path` na coluna `sys_permalinks.permalink`.
    *   **Argumentos:**
        *   `permalink_path`: A URL amigável (ex: `/m/persons/home`).
    *   **Retorno:**
        *   `{:ok, %{standard: \"page.php?i=persons_home\", check: \"BxPersonsPageHome\", permalink: \"/m/persons/home\", ... (outras colunas de sys_permalinks)}}`
        *   `{:error, :not_found}`: Permalink não encontrado.
    *   **SQL:**

```sql
        SELECT id, standard, permalink, \"check\", compare_by_prefix
        FROM sys_permalinks
        WHERE permalink = ?
        LIMIT 1;
```

```sql
        SELECT
            pd.id as content_id,
            p.id as profile_id,
            p.account_id,
            p.type,
            pd.fullname -- e outros campos de bx_persons_data que sejam úteis para identificação inicial
        FROM bx_persons_data pd
        JOIN sys_profiles p ON pd.id = p.content_id AND p.type = 'bx_persons' -- Garantir que é um perfil do tipo pessoa
        WHERE pd.uri = ? -- Assumindo que bx_persons_data tem uma coluna 'uri' para o slug
        LIMIT 1;
```

    *   **Considerações:**
        *   O campo `compare_by_prefix` do UNA original pode indicar que a correspondência não precisa ser exata. Se `compare_by_prefix == 1`, a query SQL pode precisar de `LIKE ? || '%'`.
        *   O campo `\"check\"` refere-se a uma classe/método PHP no UNA. Para a API \"Deeper\", o `standard` path retornado é mais útil. O cliente ou um serviço de API subsequente precisaria interpretar o `standard` path (ex: `page.php?i=nome_da_pagina`) para determinar qual objeto de página (`sys_objects_page`) carregar.

### 2. Resolver um Caminho para um Recurso de Conteúdo (Exemplo: Perfil de Pessoa por URI)

*   **`resolve_path_to_person_profile(uri_slug :: String.t()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Tenta encontrar um perfil de pessoa (`bx_persons_data`) que corresponda ao `uri_slug` fornecido.
    *   **Argumentos:**
        *   `uri_slug`: O slug do perfil (ex: `john-doe`).
    *   **Retorno:**
        *   `{:ok, %{type: \"bx_persons\", profile_id: 456, content_id: 789, account_id: 123, ... (dados do perfil)}}`
        *   `{:error, :not_found}`: Nenhum perfil de pessoa encontrado com esse slug.
    *   **SQL:**

        *   **Nota:** A tabela `bx_persons_data` no dump original não possui um campo `uri` explícito. Se essa funcionalidade for desejada, a tabela `bx_persons_data` (e outras tabelas de conteúdo) precisariam ser estendidas com um campo `uri` (slug) que seria preenchido quando o conteúdo é criado/atualizado. O UNA geralmente armazena esses URIs na tabela principal do módulo de conteúdo.

### 3. Função Genérica de Resolução de Caminho (Mais Complexa)

*   **`resolve_generic_path(path :: String.t()) :: {:ok, %{type: String.t(), resource_id: any(), details: map()}} | {:error, :not_found | any()}`**
    *   Tenta resolver um caminho genérico consultando várias fontes:
        1.  Primeiro, tenta `resolve_permalink/1`. Se encontrar, tenta interpretar o `standard` path para identificar o tipo de recurso (ex: se `standard` contém `page.php?i=`, é uma página).
        2.  Se não for um permalink, tenta buscar em tabelas de conteúdo comuns que possuem campos `uri` (slugs).
            *   Ex: `SELECT id, 'bx_persons' as type FROM bx_persons_data WHERE uri = ?`
            *   Ex: `SELECT id, 'bx_posts' as type FROM bx_posts_data WHERE uri = ?` (para uma futura tabela de posts)
        3.  (Opcional e Complexo) Poderia tentar aplicar regras de `sys_rewrite_rules` se uma lógica de interpretação para o campo `service` puder ser desenvolvida.
    *   **Retorno:** Um mapa indicando o `type` do recurso encontrado (ex: `\"page_object\"`, `\"person_profile\"`, `\"article\"`) e um `resource_id` (ex: nome do objeto de página, ID do perfil, ID do artigo) e `details` adicionais.
    *   **Esta função seria bastante complexa e evoluiria à medida que mais módulos de conteúdo fossem adicionados.**

### Considerações:

*   **Criação de Slugs/URIs:** A lógica para gerar os slugs/URIs únicos para o conteúdo (ex: a partir do título) residiria nos módulos de criação/atualização de conteúdo (ex: `PersonsRepo.create_person_data` geraria e salvaria o `uri`). O `RoutingRepo` apenas os consultaria.
*   **Performance:** Buscas por `permalink` ou `uri` devem ser rápidas. Garantir índices nessas colunas é essencial.
*   **Desambiguação:** Se múltiplos tipos de conteúdo puderem ter o mesmo slug (o que geralmente deve ser evitado por design), a lógica de resolução precisaria de uma forma de priorizar ou desambiguar.
*   **Simplificação:** Para a API \"Deeper\", pode ser mais eficiente que o cliente já saiba o tipo de recurso que espera de um slug. Por exemplo, uma URL no cliente como `/profiles/john-doe` seria traduzida para uma chamada API `GET /api/v1/profiles/slug/john-doe` (ou `GET /api/v1/persons/uri/john-doe`), onde o tipo já está implícito no endpoint da API. Nesse cenário, o `RoutingRepo` se concentraria em funções como `resolve_path_to_person_profile/1`.
*   **Uso de `sys_rewrite_rules`:** Dada a dependência de `service` calls PHP, a utilidade direta de `sys_rewrite_rules` é questionável para a API Elixir, a menos que haja um esforço significativo para mapear esses serviços para funcionalidades da API \"Deeper\".