# Documentação Deeper: Sistema de Votos (`sys_voting_system`)

Este documento detalha a API \"Deeper\" para um sistema genérico de votos/avaliações, permitindo que usuários avaliem diferentes tipos de conteúdo (artigos, perfis, produtos, etc.), geralmente com uma escala numérica (ex: 1 a 5 estrelas). Ele se baseia no conceito de `sys_objects_vote` e tabelas associadas do UNA.

## Abordagem \"Deeper\" para Votos:

O UNA usa `sys_objects_vote` para definir instâncias de sistemas de votação, especificando tabelas de \"track\" (`TableTrack`) e tabelas principais (`TableMain`) para armazenar os votos e os resultados agregados (`TriggerTable` para atualizar `rate` e `rate_count`).

Para \"Deeper\", podemos ter:

1.  **Tabela de Rastreamento Unificada (Proposta):** `deeper_votes_track`
    *   Armazenaria cada voto individual.
    *   Colunas: `id`, `system_name` (ex: \"deeper_articles_rating\", \"bx_persons_profile_rating\"), `object_id` (ID da entidade votada), `voter_profile_id`, `value` (o voto, ex: 1-5), `voted_at`.
2.  **Atualização de Agregados:**
    *   Os campos `rate` (média) e `votes` (contagem) na tabela da entidade principal (ex: `deeper_articles_entries`, `bx_persons_data`) seriam atualizados após cada novo voto ou alteração de voto.
    *   O UNA usa `sys_votes` (ou `TableMain` do `sys_objects_vote`) para armazenar `count` e `sum` para cada `object_id`, a partir dos quais a média (`rate`) é calculada. Podemos manter uma tabela similar `deeper_object_votes_summary` ou calcular/atualizar a média diretamente na tabela da entidade principal.

Para esta documentação, focaremos na tabela `deeper_votes_track` e na atualização dos contadores/média na entidade principal.

## Responsabilidades Principais da API de Votos:

*   Permitir que usuários enviem um voto (ex: uma avaliação de 1-5 estrelas) para um objeto específico.
*   Permitir que usuários alterem seu voto anterior.
*   (Opcional) Permitir que usuários removam seu voto.
*   Retornar a avaliação média e o número de votos para um objeto.
*   Retornar o voto do usuário atual para um objeto, se houver.

## Estrutura da Documentação para Votos:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define o `CREATE TABLE` para `deeper_votes_track` e discute a atualização de campos agregados nas tabelas de entidade.

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Módulos de migração para criar as tabelas de votos.

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o `Deeper.InteractionSystems.VotingRepo`.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful, geralmente aninhados sob o recurso principal (ex: `/articles/{id}/vote`).

## Considerações de Design:

*   **`system_name`**: Identifica a qual \"instância\" de sistema de votação uma entrada pertence (ex: avaliação de artigos, avaliação de perfis).
*   **`object_id`**: O ID da entidade sendo votada.
*   **Limites de Voto (`MinValue`, `MaxValue` do UNA):** A lógica da API deve validar se o `value` do voto está dentro dos limites configurados para o `system_name` específico.
*   **Uma Vez por Usuário:** Geralmente, um usuário só pode dar um voto por objeto. Votos subsequentes atualizam o voto anterior.
*   **ACL:** Quem pode votar (ex: não pode votar em seu próprio conteúdo).