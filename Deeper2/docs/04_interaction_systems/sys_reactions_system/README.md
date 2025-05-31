# Documentação Deeper: Sistema de Reações Genérico

Esta seção detalha a API RESTful \"Deeper\" para interagir com um sistema de reações genérico. Este sistema permite que usuários reajam a diferentes tipos de conteúdo (perfis, posts, etc.) usando um conjunto predefinido de reações (ex: \"like\", \"love\", \"haha\", \"wow\", \"sad\", \"angry\").

## Estrutura de Tabelas Assumida (Similar a outros sistemas de interação):

Como o dump SQL inicial não detalhava explicitamente um `sys_objects_reaction` ou tabelas de track genéricas para reações em conteúdo principal (além de `sys_cmts_reactions` para comentários), vamos definir uma estrutura hipotética, mas comum, para tal sistema:

*   **`sys_objects_reaction` (Hipotética ou Adaptada):** Tabela de configuração.
    *   `name`: Nome único do objeto de reação (ex: `bx_posts_reactions`).
    *   `module`: Módulo associado.
    *   `reactions_available`: Uma lista (TEXT, JSON ou referência a `sys_form_pre_lists`) das reações permitidas (ex: `[\"like\", \"love\", \"haha\"]`).
    *   `table_summary`: Tabela para armazenar a contagem de cada tipo de reação por item (ex: `bx_posts_reactions_summary`).
    *   `table_track`: Tabela para armazenar cada reação individual de usuário (ex: `bx_posts_reactions_track`).
    *   `is_undo`: Se o usuário pode remover/alterar sua reação.
    *   `trigger_table`, `trigger_field_id`, `trigger_field_reactions_count` (ou campos separados por tipo de reação): Para atualizar a tabela de conteúdo principal.
*   **Tabela de Sumário de Reações (Ex: `bx_example_content_reactions_summary`)**:
    *   `object_id`, `reaction_type`, `count`.
*   **Tabela de Rastreamento de Reações (Ex: `bx_example_content_reactions_track`)**:
    *   `object_id`, `author_id`, `reaction_type`, `date`.

**Alternativa:** Se o UNA estiver usando `sys_cmts_reactions` de forma mais genérica, onde `sys_cmts_reactions.object_id` pode ser o ID do conteúdo principal, então adaptaríamos para usar essa tabela. Para este documento, prosseguiremos com a estrutura genérica acima.

## Responsabilidades da API \"Deeper\":

*   Obter a contagem de cada tipo de reação para um item de conteúdo.
*   Permitir que usuários adicionem/alterem/removam sua reação a um item.
*   Verificar a reação de um usuário específico para um item.

## Documentação Detalhada:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite da tabela hipotética `sys_objects_reaction` e exemplos de tabelas de sumário e rastreamento.

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir para criar essas tabelas.

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o `Deeper.InteractionSystems.ReactionsRepo` e suas funções.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful (ex: `POST /reactions/{object_reaction_name}/item/{item_id}`).

## Fluxo Típico:

1.  O cliente exibe um item de conteúdo.
2.  O cliente sabe que o objeto de reação é, por exemplo, `bx_posts_reactions`.
3.  Para exibir as reações, o cliente chama `GET /api/v1/reactions/object/bx_posts_reactions/item/{item_id}`.
4.  A API retorna as contagens de cada tipo de reação e a reação do usuário logado.
5.  Para reagir, o cliente envia `POST /api/v1/reactions/object/bx_posts_reactions/item/{item_id}` com `{\"reaction_type\": \"love\"}`. O `ReactionsRepo` atualiza as tabelas de track e sumário, e o contador na `TriggerTable`.