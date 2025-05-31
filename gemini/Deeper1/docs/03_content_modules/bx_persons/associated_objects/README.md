# Documentação Deeper: Objetos Associados ao Módulo Pessoas (`bx_persons`)

Este documento descreve como as funcionalidades de interação comuns do UNA (como comentários, votos, favoritos, denúncias) se aplicam aos perfis de \"Pessoas\" (`bx_persons`) e como a API \"Deeper\" facilitará o acesso a essas interações.

Muitas dessas interações no UNA são gerenciadas por sistemas genéricos (ex: `sys_cmts_*` para comentários, `sys_votes_*` para votos) que são instanciados para módulos específicos através da tabela `sys_objects_*` (ex: `sys_objects_cmts`, `sys_objects_vote`). A API \"Deeper\" fornecerá endpoints genéricos para essas interações (a serem detalhados em `04_interaction_systems/`), mas eles serão sempre contextualizados por um `object_id` que, no caso do módulo `bx_persons`, será o `id` da tabela `bx_persons_data`.

## 1. Comentários em Perfis (`bx_persons_cmts` ou sistema genérico)

*   **Tabela UNA:** `bx_persons_cmts` (ou a tabela genérica de comentários como `sys_module_name_cmts` se configurado via `sys_objects_cmts`).
*   **Identificador do Objeto:** `bx_persons_data.id` (será o `cmt_object_id` na tabela de comentários).
*   **API \"Deeper\":**
    *   Os endpoints para listar, criar, atualizar e deletar comentários em um perfil de pessoa seguirão o padrão da API de Comentários Genérica (a ser definida em `04_interaction_systems/sys_comments_system/`).
    *   **Contextualização para `bx_persons`:**
        *   `GET /api/v1/persons/{person_id}/comments`
            *   Internamente, chama a lógica genérica de comentários, passando `person_id` como o `object_id` para filtrar os comentários.
            *   Pode incluir parâmetros de paginação, ordenação.
        *   `POST /api/v1/persons/{person_id}/comments`
            *   Cria um novo comentário. O `person_id` é usado como `cmt_object_id`. O `cmt_author_id` virá do JWT do usuário autenticado.
    *   **Referência à Tabela Específica:** Se `bx_persons_cmts` for uma tabela fisicamente separada (e não apenas uma configuração do sistema genérico), o `Deeper.Content.PersonsRepo` (ou um `PersonsCommentsRepo` dedicado) lidará com as queries para `bx_persons_cmts`. Se for um sistema genérico, o `CommentsRepo` genérico será usado, parametrizado com o nome do objeto de comentários do UNA para \"pessoas\".

## 2. Votos/Avaliações em Perfis (`bx_persons_votes_track` ou sistema genérico)

*   **Tabelas UNA:** `bx_persons_votes` (agregação) e `bx_persons_votes_track` (votos individuais), ou tabelas genéricas `sys_votes` e `sys_votes_track` se configurado via `sys_objects_vote`.
*   **Identificador do Objeto:** `bx_persons_data.id`.
*   **Campos de Agregação em `bx_persons_data`:** `rate` (média), `votes` (contagem).
*   **API \"Deeper\":**
    *   Seguirá o padrão da API de Votos Genérica (a ser definida em `04_interaction_systems/sys_voting_system/`).
    *   **Contextualização para `bx_persons`:**
        *   `GET /api/v1/persons/{person_id}/rating`
            *   Retorna a avaliação atual (`rate`, `votes`) do perfil.
            *   Pode também retornar se o usuário atual já votou e qual foi seu voto.
        *   `POST /api/v1/persons/{person_id}/vote`
            *   Corpo da Requisição: `{\"value\": 5}` (onde 5 é a estrela/nota).
            *   Registra o voto do usuário autenticado para o perfil.
            *   Atualiza `bx_persons_votes_track` e recalcula/atualiza `bx_persons_data.rate` e `bx_persons_data.votes` (ou isso é feito por um job/trigger).
    *   **Lógica no Repo:** `PersonsRepo` ou um `VotingRepo` genérico lidará com as tabelas.

## 3. Favoritos em Perfis (`bx_persons_favorites_track` ou sistema genérico)

*   **Tabela UNA:** `bx_persons_favorites_track` ou tabela genérica de favoritos se configurado via `sys_objects_favorite`.
*   **Identificador do Objeto:** `bx_persons_data.id`.
*   **Campo de Agregação em `bx_persons_data`:** `favorites` (contagem).
*   **API \"Deeper\":**
    *   Seguirá o padrão da API de Favoritos Genérica (a ser definida em `04_interaction_systems/sys_favorites_system/`).
    *   **Contextualização para `bx_persons`:**
        *   `GET /api/v1/persons/{person_id}/favorite-status`
            *   Retorna se o usuário autenticado favoritou este perfil e a contagem total de favoritos.
        *   `POST /api/v1/persons/{person_id}/favorite`
            *   Adiciona o perfil aos favoritos do usuário autenticado.
            *   Atualiza `bx_persons_favorites_track` e `bx_persons_data.favorites`.
        *   `DELETE /api/v1/persons/{person_id}/favorite`
            *   Remove o perfil dos favoritos do usuário.
            *   Atualiza as tabelas correspondentes.

## 4. Denúncias de Perfis (`bx_persons_reports_track` ou sistema genérico)

*   **Tabelas UNA:** `bx_persons_reports` (agregação) e `bx_persons_reports_track` (denúncias individuais), ou sistema genérico via `sys_objects_report`.
*   **Identificador do Objeto:** `bx_persons_data.id`.
*   **Campo de Agregação em `bx_persons_data`:** `reports` (contagem).
*   **API \"Deeper\":**
    *   Seguirá o padrão da API de Denúncias Genérica (a ser definida em `04_interaction_systems/sys_reporting_system/`).
    *   **Contextualização para `bx_persons`:**
        *   `POST /api/v1/persons/{person_id}/report`
            *   Corpo da Requisição: `{\"type\": \"spam\", \"text\": \"Este perfil é spam.\"}`.
            *   Registra uma denúncia do usuário autenticado contra o perfil.
            *   Atualiza `bx_persons_reports_track` e `bx_persons_data.reports`.

## 5. Pontuações (Scores) em Perfis (`bx_persons_scores_track` ou sistema genérico)

*   **Tabelas UNA:** `bx_persons_scores` (agregação) e `bx_persons_scores_track` (votos up/down para score), ou sistema genérico via `sys_objects_score`.
*   **Identificador do Objeto:** `bx_persons_data.id`.
*   **Campos de Agregação em `bx_persons_data`:** `score`, `sc_up`, `sc_down`.
*   **API \"Deeper\":**
    *   Seguirá o padrão da API de Scores Genérica (a ser definida em `04_interaction_systems/sys_scoring_system/`).
    *   **Contextualização para `bx_persons`:**
        *   `GET /api/v1/persons/{person_id}/score`
            *   Retorna o score atual (`score`, `sc_up`, `sc_down`) e se o usuário já deu up/down vote.
        *   `POST /api/v1/persons/{person_id}/score`
            *   Corpo da Requisição: `{\"type\": \"up\"}` ou `{\"type\": \"down\"}`.
            *   Registra o voto de score do usuário.

## 6. Visualizações de Perfil (`bx_persons_views_track`)

*   **Tabela UNA:** `bx_persons_views_track`.
*   **Identificador do Objeto:** `bx_persons_data.id`.
*   **Campo de Agregação em `bx_persons_data`:** `views`.
*   **API \"Deeper\":**
    *   Endpoint já mencionado em `03_content_modules/bx_persons/api_endpoints/README.md`:
        *   `POST /api/v1/persons/{person_id}/view`
    *   A lógica de agregação para `bx_persons_data.views` será tratada pelo `PersonsRepo.record_profile_view`.

## 7. Metadados (Palavras-chave, Localizações, Menções)

*   **Tabelas UNA:** `bx_persons_meta_keywords`, `bx_persons_meta_locations`, `bx_persons_meta_mentions`.
*   **Identificador do Objeto:** `bx_persons_data.id`.
*   **API \"Deeper\":**
    *   **Leitura:** Os dados dessas tabelas podem ser incluídos na resposta de `GET /api/v1/persons/{person_id}` se relevantes para exibição (ex: tags, localização formatada).
    *   **Escrita:** A API para adicionar/editar esses metadados (ex: ao editar um perfil) seria parte dos endpoints de atualização de perfil (ex: `PUT /api/v1/profiles/{profile_id}`). O `PersonsRepo` lidaria com a inserção/atualização nessas tabelas meta.
    *   A busca de perfis por palavra-chave ou localização (`GET /api/v1/persons?keyword=...&location=...`) exigiria `JOIN`s com essas tabelas meta no `PersonsRepo.list_persons_with_details`.

## 8. Habilidades (`bx_persons_skills`)

*   **Tabela UNA:** `bx_persons_skills`.
*   **Identificador do Objeto:** `content_id` (que é `bx_persons_data.id`).
*   **API \"Deeper\":**
    *   **Leitura:** Incluído na resposta de `GET /api/v1/persons/{person_id}`.
    *   **Escrita:** Parte do `PUT /api/v1/profiles/{profile_id}`.

## Considerações de Implementação:

*   **Repositórios Genéricos vs. Específicos:**
    *   Para cada sistema de interação (comentários, votos, etc.), decidiremos se o `PersonsRepo` implementará a lógica diretamente para as tabelas `bx_persons_*` OU se haverá um Repositório Genérico (ex: `Deeper.Interactions.CommentsRepo`) que é parametrizado com o nome da tabela de comentários ou o \"objeto de sistema\" do UNA.
    *   A abordagem com Repositórios Genéricos é mais DRY, mas requer um bom design para lidar com as especificidades de cada módulo.
*   **Atualização de Contadores:** A atualização dos campos de contagem em `bx_persons_data` (como `comments`, `votes`, `favorites`) após uma interação deve ser feita de forma eficiente. Isso pode ser na mesma transação da interação ou através de jobs/triggers (embora triggers sejam menos comuns em aplicações Elixir que preferem lógica explícita).
*   **ACL e Permissões:** Todas as APIs de interação devem verificar se o usuário autenticado tem permissão para realizar a ação (ex: postar comentário, votar).

Ao documentar e implementar as APIs genéricas em `04_interaction_systems`, faremos referência a como elas são aplicadas a módulos de conteúdo como `bx_persons`.