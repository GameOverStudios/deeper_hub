# Documentação Deeper: Sistema de Pontuações (Scores) Genérico

Esta seção detalha a API RESTful \"Deeper\" para interagir com o sistema de pontuações (scores) genérico do UNA. Este sistema é tipicamente usado para funcionalidades de \"upvote/downvote\" ou \"like/dislike\" em diferentes tipos de conteúdo.

## Tabelas Relevantes do UNA:

*   **`sys_objects_score`**: Tabela de configuração principal. Cada entrada define um \"objeto de score\" para um tipo de conteúdo. Especifica:
    *   `name`: Nome único do objeto de score (ex: `bx_persons_scores`, `bx_posts_scores`). Usado na API.
    *   `module`: Módulo associado.
    *   `table_main`: Nome da tabela SQL que armazena o sumário das pontuações (contagem de upvotes, contagem de downvotes). Ex: `bx_persons_scores`.
    *   `table_track`: Nome da tabela SQL que armazena cada pontuação individual (up/down). Ex: `bx_persons_scores_track`.
    *   `post_timeout`: Tempo antes que um usuário possa pontuar novamente (se a alteração for permitida após timeout).
    *   `is_undo`: Se o usuário pode remover/alterar sua pontuação.
    *   `is_on`: Se este sistema de pontuação está ativo.
    *   `trigger_table`, `trigger_field_id`, `trigger_field_score`, `trigger_field_cup` (count up), `trigger_field_cdown` (count down): Configurações para atualizar a tabela de conteúdo principal com o score total e as contagens de up/down.
*   **Tabela de Sumário de Scores (especificada em `sys_objects_score.table_main`)**:
    *   Geralmente contém `object_id` (ID do item pontuado), `count_up` (total de upvotes), `count_down` (total de downvotes).
*   **Tabela de Rastreamento de Scores (especificada em `sys_objects_score.table_track`)**:
    *   Geralmente contém `object_id`, `author_id` (quem pontuou), `author_nip` (IP), `type` ('up' ou 'down'), `date`.

## Responsabilidades da API \"Deeper\":

*   Obter a pontuação atual (upvotes, downvotes, score total) para um item de conteúdo.
*   Permitir que usuários submetam/alterem suas pontuações (upvote/downvote).
*   Verificar a pontuação de um usuário específico para um item.

## Documentação Detalhada:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite da tabela `sys_objects_score` e exemplos de tabelas `table_main` (sumário) e `table_track` (rastreamento).

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir para criar essas tabelas.

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o `Deeper.InteractionSystems.ScoringRepo` e suas funções para ler e registrar pontuações, usando dinamicamente os nomes das tabelas configuradas.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful (ex: `POST /scores/{object_score_name}/item/{item_id}`).

## Fluxo Típico:

1.  O cliente exibe um item de conteúdo (ex: post com `id=789`).
2.  O cliente sabe que o objeto de score para posts é, por exemplo, `bx_posts_scores`.
3.  Para exibir a pontuação atual e o estado dos botões up/down para o usuário logado, o cliente chama `GET /api/v1/scores/object/bx_posts_scores/item/789`.
4.  A API \"Deeper\" usa o `ScoringRepo` para:
    a.  Buscar a configuração de `bx_posts_scores` em `sys_objects_score`.
    b.  Consultar a `table_main` para obter `count_up` e `count_down`.
    c.  Consultar a `table_track` para ver se o usuário logado já deu um upvote ou downvote.
5.  A API retorna os contadores e o voto do usuário.
6.  Para dar um upvote, o cliente envia `POST /api/v1/scores/object/bx_posts_scores/item/789` com `{\"type\": \"up\"}`. O `ScoringRepo` insere/atualiza na `table_track`, recalcula e atualiza a `table_main`, e atualiza os campos na `TriggerTable` (ex: `bx_posts_data.score`, `bx_posts_data.sc_up`).