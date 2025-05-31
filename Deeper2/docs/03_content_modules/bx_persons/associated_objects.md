# Documentação Deeper: Objetos e Interações Associadas (`bx_persons`)

Este documento descreve como os sistemas de interação genéricos do UNA (como Comentários, Votos, Favoritos, Denúncias, Pontuações) são aplicados e acessados no contexto dos perfis de `bx_persons` através da API \"Deeper\".

No UNA, essas interações são geralmente habilitadas configurando um \"objeto\" correspondente em tabelas como `sys_objects_cmts`, `sys_objects_vote`, `sys_objects_favorite`, etc. Por exemplo, pode haver um objeto chamado `bx_persons` ou `bx_persons_notes` em `sys_objects_cmts` para habilitar comentários em perfis.

A API \"Deeper\" fornecerá endpoints genéricos para esses sistemas de interação (a serem definidos em `04_interaction_systems/`). Esses endpoints geralmente aceitam um `object_name` (o nome do objeto de interação, ex: `bx_persons`) e um `object_content_id` (o ID do item específico sendo comentado/votado, que no caso de `bx_persons` seria o `sys_profiles.id`).

## Mapeamento de Interações para `bx_persons`:

Assumindo que os seguintes \"objetos de interação\" estão configurados no UNA para `bx_persons` (os nomes exatos podem variar):

*   **Objeto de Comentários:** `bx_persons_profile_comments` (ou similar)
*   **Objeto de Votos/Avaliações:** `bx_persons_ratings`
*   **Objeto de Favoritos:** `bx_persons_favorites`
*   **Objeto de Denúncias:** `bx_persons_reports`
*   **Objeto de Pontuações (Up/Down):** `bx_persons_scores`

### 1. Comentários em Perfis de Pessoas

*   **Funcionalidade:** Permitir que usuários comentem em perfis de pessoas.
*   **Tabela de Tracking no UNA (Exemplo):** `bx_persons_cmts` (se específica) ou uma tabela genérica `sys_cmts_NOME_DO_OBJETO`. A API \"Deeper\" usará as tabelas genéricas `sys_cmts_*` e `sys_cmts_ids` se o sistema genérico for usado.
*   **Endpoints da API \"Deeper\" (usando o sistema genérico de comentários):**
    *   `GET /api/v1/comments/object/bx_persons_profile_comments/item/{profile_id}?page=1&per_page=10`
        *   Para listar comentários do perfil `{profile_id}`.
        *   `bx_persons_profile_comments` é o `sys_objects_cmts.Name`.
        *   `{profile_id}` é o `sys_profiles.id` do perfil comentado.
    *   `POST /api/v1/comments/object/bx_persons_profile_comments/item/{profile_id}` (Protegido)
        *   Para adicionar um novo comentário ao perfil.
*   **Contador em `bx_persons_data`:** A coluna `bx_persons_data.comments` deve ser atualizada quando comentários são adicionados/removidos.

### 2. Votos/Avaliações em Perfis de Pessoas

*   **Funcionalidade:** Permitir que usuários avaliem perfis (ex: 1-5 estrelas).
*   **Tabela de Tracking no UNA (Exemplo):** `bx_persons_votes_track`.
*   **Tabela de Sumário no UNA (Exemplo):** `bx_persons_votes` (para `count` e `sum`).
*   **Endpoints da API \"Deeper\" (usando o sistema genérico de votos):**
    *   `GET /api/v1/votes/object/bx_persons_ratings/item/{profile_id}`
        *   Para obter a avaliação média, contagem de votos do perfil.
    *   `POST /api/v1/votes/object/bx_persons_ratings/item/{profile_id}` (Protegido)
        *   Corpo: `{\"value\": 5}`
        *   Para submeter um voto/avaliação.
*   **Contadores em `bx_persons_data`:** As colunas `bx_persons_data.rate` (média) e `bx_persons_data.votes` (contagem) devem ser atualizadas.

### 3. Favoritar Perfis de Pessoas

*   **Funcionalidade:** Permitir que usuários adicionem perfis à sua lista de favoritos.
*   **Tabela de Tracking no UNA (Exemplo):** `bx_persons_favorites_track`.
*   **Endpoints da API \"Deeper\" (usando o sistema genérico de favoritos):**
    *   `GET /api/v1/favorites/object/bx_persons_favorites/item/{profile_id}/status` (Protegido)
        *   Para verificar se o usuário logado favoritou este perfil.
    *   `POST /api/v1/favorites/object/bx_persons_favorites/item/{profile_id}/toggle` (Protegido)
        *   Para favoritar ou desfavoritar o perfil.
    *   `GET /api/v1/favorites/object/bx_persons_favorites/item/{profile_id}/users?page=1&per_page=10`
        *   Para listar usuários que favoritaram este perfil.
*   **Contador em `bx_persons_data`:** A coluna `bx_persons_data.favorites` deve ser atualizada.

### 4. Denunciar Perfis de Pessoas

*   **Funcionalidade:** Permitir que usuários denunciem perfis.
*   **Tabela de Tracking no UNA (Exemplo):** `bx_persons_reports_track`.
*   **Endpoints da API \"Deeper\" (usando o sistema genérico de denúncias):**
    *   `POST /api/v1/reports/object/bx_persons_reports/item/{profile_id}` (Protegido)
        *   Corpo: `{\"type\": \"spam\", \"text\": \"Este perfil parece falso.\"}`
        *   Para submeter uma denúncia.
*   **Contador em `bx_persons_data`:** A coluna `bx_persons_data.reports` deve ser atualizada.

### 5. Pontuar Perfis de Pessoas (Up/Down Votes)

*   **Funcionalidade:** Permitir que usuários deem um \"upvote\" ou \"downvote\" em perfis.
*   **Tabela de Tracking no UNA (Exemplo):** `bx_persons_scores_track`.
*   **Tabela de Sumário no UNA (Exemplo):** `bx_persons_scores` (para `count_up`, `count_down`).
*   **Endpoints da API \"Deeper\" (usando o sistema genérico de scores):**
    *   `GET /api/v1/scores/object/bx_persons_scores/item/{profile_id}`
        *   Para obter a contagem de up/down votes.
    *   `POST /api/v1/scores/object/bx_persons_scores/item/{profile_id}` (Protegido)
        *   Corpo: `{\"type\": \"up\"}` ou `{\"type\": \"down\"}`
        *   Para submeter um score.
*   **Contadores em `bx_persons_data`:** As colunas `bx_persons_data.score` (calculado), `bx_persons_data.sc_up`, e `bx_persons_data.sc_down` devem ser atualizadas.

## Considerações de Implementação:

*   **Nomes dos Objetos de Interação:** Os nomes exatos dos objetos de interação (ex: `bx_persons_profile_comments`, `bx_persons_ratings`) precisam ser obtidos da configuração do sistema UNA (tabelas `sys_objects_cmts`, `sys_objects_vote`, etc.). A API \"Deeper\" pode precisar de um mecanismo para descobrir esses nomes ou eles podem ser hardcoded se forem consistentes.
*   **Atualização de Contadores:** Os Repos dos sistemas de interação genéricos (ex: `CommentsRepo`, `VotingRepo`) devem ser responsáveis por atualizar os contadores nas tabelas de conteúdo principais (como `bx_persons_data`) quando uma interação ocorre. Isso pode ser feito através de callbacks, eventos, ou lógica direta após a inserção na tabela de track. A configuração do objeto de interação (`sys_objects_cmts.TriggerFieldComments`, etc.) informa qual campo na tabela de conteúdo deve ser atualizado.
*   **Contexto `profile_id`:** Para todas essas interações, o `{profile_id}` passado na URL da API refere-se ao `sys_profiles.id` do perfil de pessoa que está sendo comentado, votado, favoritado, etc.

Esta abordagem permite reutilizar a lógica dos sistemas de interação genéricos para diferentes tipos de conteúdo, apenas variando o `object_name` e o `object_content_id`.