# Documentação Deeper: Sistema de Comentários (`sys_comments_system`)

Este documento detalha a API \"Deeper\" para o sistema genérico de comentários, permitindo que usuários comentem em diferentes tipos de conteúdo (artigos, perfis, fotos, etc.). Ele se baseia nas tabelas de comentários do UNA (como `sys_cmts_ids` e tabelas de comentários específicas de módulos como `bx_persons_cmts`, mas para \"Deeper\" podemos visar um sistema mais unificado).

## Abordagem \"Deeper\" para Comentários:

O UNA frequentemente usa tabelas de comentários separadas para cada módulo (ex: `bx_persons_cmts`, `bx_articles_cmts`). Para simplificar no \"Deeper\" e promover a reutilização:

1.  **Tabela de Comentários Unificada (Proposta):** `deeper_comments`
    *   Esta tabela armazenaria todos os comentários.
    *   Conteria colunas como: `id`, `system_name` (ex: \"deeper_articles_comments\", \"bx_persons_profile_comments\" - identificando a qual \"objeto de comentário\" do UNA isto se refere ou qual sistema de comentários está ativo para este tipo de conteúdo), `object_id` (ID da entidade comentada, ex: ID do artigo, ID do perfil), `author_profile_id`, `parent_id` (para respostas aninhadas), `text`, `status`, `created_at`, `updated_at`.
    *   Contadores como `cmt_rate`, `cmt_rate_count`, `cmt_replies` do UNA seriam atualizados nesta tabela ou em uma tabela agregada.
2.  **Tabelas de \"Track\" e Agregados do UNA (Opcional/Adaptar):**
    *   Tabelas como `sys_cmts_votes_track`, `sys_cmts_scores_track`, `sys_cmts_reports_track` poderiam ser generalizadas ou usadas com um `system_id` para apontar para a definição do objeto de votação/score/report associado a este sistema de comentários.
    *   A tabela `sys_cmts_ids` do UNA mapeia um `system_id` (de `sys_objects_cmts.ID`) e `cmt_id` (o ID real do comentário na tabela específica do módulo) para contadores. Com uma tabela unificada `deeper_comments`, esta tabela poderia ser simplificada ou seus campos incorporados.

Para esta documentação inicial, vamos focar em uma tabela `deeper_comments` unificada e como a API interagiria com ela.

## Responsabilidades Principais da API de Comentários:

*   Listar comentários para um objeto específico (ex: um artigo), com paginação e ordenação.
*   Permitir a criação de novos comentários (e respostas) por usuários autorizados.
*   Permitir a edição de comentários por seus autores ou administradores.
*   Permitir a exclusão de comentários por seus autores ou administradores.
*   (Opcional) Integrar com votação/score/reações em comentários.

## Estrutura da Documentação para Comentários:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define o `CREATE TABLE` para `deeper_comments` e, se necessário, tabelas de track para votos/scores em comentários.

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Módulos de migração para criar as tabelas de comentários.

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o `Deeper.InteractionSystems.CommentsRepo`.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful, geralmente aninhados sob o recurso principal (ex: `/articles/{id}/comments`).

## Considerações de Design:

*   **`system_name`**: Crucial para identificar a qual \"instância\" de sistema de comentários uma entrada pertence. Isso permite que diferentes tipos de conteúdo tenham seus próprios conjuntos de comentários, mesmo que armazenados na mesma tabela.
*   **`object_id`**: O ID da entidade sendo comentada.
*   **Aninhamento (`parent_id`):** Suporte a comentários encadeados.
*   **Status:** Comentários podem ser `pending_approval`, `active`, `spam`, `deleted`.
*   **ACL:** Quem pode postar, quem pode moderar.