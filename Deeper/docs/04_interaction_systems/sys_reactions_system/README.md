# Documentação Deeper: Sistema de Reações (`sys_reactions_system`)

Este documento detalha a API \"Deeper\" para um sistema genérico de \"Reações\", permitindo que usuários expressem diferentes tipos de reações (ex: Like, Love, Haha, Wow, Sad, Angry) a diversos tipos de conteúdo. No UNA, isso pode ser uma extensão ou uma variação do sistema de votos ou scores, ou um sistema próprio (`sys_objects_reaction`).

## Abordagem \"Deeper\" para Reações:

O UNA pode ter um `sys_objects_reaction` que define o conjunto de reações disponíveis para um tipo de conteúdo.

Para \"Deeper\", podemos ter:

1.  **Tabela de Tipos de Reação (Opcional, mas Recomendado):** `deeper_reaction_types`
    *   Se os tipos de reação forem dinâmicos ou muitos.
    *   Colunas: `id`, `reaction_key` (ex: \"like\", \"love\", \"haha\"), `icon_class` (para UI), `title_lkey` (chave de tradução), `order`, `active`.
    *   Se os tipos de reação forem fixos e poucos, podem ser definidos na aplicação.
2.  **Tabela de Rastreamento Unificada:** `deeper_reactions_track`
    *   Armazenaria cada reação individual.
    *   Colunas: `id`, `system_name` (ex: \"deeper_articles_reactions\"), `object_id`, `reactor_profile_id`, `reaction_type_key` (ou `reaction_type_id` se usar a tabela acima), `reacted_at`.
3.  **Atualização de Agregados:**
    *   Na tabela da entidade principal (ex: `deeper_articles_entries`), poderia haver colunas para cada tipo de reação (ex: `reactions_like_count`, `reactions_love_count`) ou um campo JSON para armazenar contagens de todas as reações.
    *   Uma tabela de resumo `deeper_object_reactions_summary` também é uma opção, contendo `object_id`, `reaction_type_key`, e `count`.

Para esta documentação, vamos assumir que os tipos de reação são definidos (fixos ou de uma tabela `deeper_reaction_types`) e que atualizaremos contadores agregados na entidade principal ou em uma tabela de resumo.

## Responsabilidades Principais da API de Reações:

*   Permitir que um usuário adicione uma reação a um objeto.
*   Permitir que um usuário altere sua reação para o mesmo objeto (ex: de \"Like\" para \"Love\").
*   Permitir que um usuário remova sua reação.
*   Retornar a contagem de cada tipo de reação para um objeto.
*   Retornar a reação do usuário atual para um objeto, se houver.
*   (Opcional) Listar os tipos de reação disponíveis.

## Estrutura da Documentação para Reações:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define `CREATE TABLE` para `deeper_reaction_types` (opcional) e `deeper_reactions_track`.

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Módulos de migração.

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o `Deeper.InteractionSystems.ReactionsRepo`.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful.

## Considerações de Design:

*   **Um Usuário, Uma Reação por Objeto:** Geralmente, um usuário só pode ter uma reação ativa para um determinado objeto. Se ele reage novamente, a reação anterior é substituída ou removida.
*   **Tipos de Reação:** A lista de reações disponíveis (`like`, `love`, `haha`, `wow`, `sad`, `angry`) deve ser consistente e conhecida pelo cliente.