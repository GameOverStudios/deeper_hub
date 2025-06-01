# Documentação Deeper: Sistema de Pontuações (`sys_scoring_system`)

Este documento detalha a API \"Deeper\" para um sistema genérico de \"Pontuações\" (Scoring), permitindo que usuários deem upvotes (votos positivos) ou downvotes (votos negativos) em diferentes tipos de conteúdo (artigos, comentários, perfis, etc.). O resultado é um score líquido, e contagens separadas de upvotes e downvotes. Ele se baseia no conceito de `sys_objects_score` e tabelas associadas do UNA.

## Abordagem \"Deeper\" para Pontuações:

O UNA usa `sys_objects_score` para definir instâncias de sistemas de pontuação, com `TableMain` para os agregados (score, up, down) e `TableTrack` para os votos individuais.

Para \"Deeper\", podemos ter:

1.  **Tabela de Rastreamento Unificada (Proposta):** `deeper_scores_track`
    *   Armazenaria cada voto individual (upvote/downvote).
    *   Colunas: `id`, `system_name` (ex: \"deeper_articles_score\", \"deeper_comments_score\"), `object_id` (ID da entidade pontuada), `voter_profile_id` (quem votou), `type` ('up' ou 'down'), `voted_at`.
2.  **Atualização de Agregados:**
    *   Campos de contagem (`score_net`, `score_up_count`, `score_down_count`) na tabela da entidade principal (ex: `deeper_articles_entries`, `deeper_comments`) seriam atualizados após cada voto.
    *   O UNA usa `sys_scores` (ou `TableMain` do `sys_objects_score`) para armazenar `count_up` e `count_down`. O score líquido é calculado a partir disso. Podemos manter uma tabela similar `deeper_object_scores_summary` ou calcular/atualizar os três campos diretamente na tabela da entidade principal.

Para esta documentação, focaremos na tabela `deeper_scores_track` e na atualização dos contadores na entidade principal.

## Responsabilidades Principais da API de Pontuações:

*   Permitir que um usuário dê um upvote ou um downvote para um objeto específico.
*   Permitir que um usuário mude seu voto (ex: de upvote para downvote, ou remova o voto).
*   Retornar o score líquido, contagem de upvotes e downvotes para um objeto.
*   Retornar o voto do usuário atual para um objeto, se houver.

## Estrutura da Documentação para Pontuações:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define o `CREATE TABLE` para `deeper_scores_track` e discute a atualização de campos agregados nas tabelas de entidade.

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Módulos de migração para criar as tabelas de pontuações.

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o `Deeper.InteractionSystems.ScoringRepo`.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful, geralmente aninhados sob o recurso principal (ex: `/articles/{id}/score`).

## Considerações de Design:

*   **`system_name`**: Identifica a qual \"instância\" de sistema de pontuação uma entrada pertence.
*   **`object_id`**: O ID da entidade sendo pontuada.
*   **Tipos de Voto (`type`):** 'up' e 'down'.
*   **Comportamento de Votação:**
    *   Um usuário pode dar upvote OU downvote, não ambos.
    *   Clicar em upvote novamente pode remover o upvote (ou não fazer nada).
    *   Clicar em downvote quando já deu upvote pode mudar para downvote (e vice-versa).
    *   Esta lógica precisa ser claramente definida na API e no backend. O UNA tem uma flag `is_undo` no objeto `sys_objects_score`.
*   **ACL:** Quem pode pontuar (ex: não pode pontuar seu próprio conteúdo).