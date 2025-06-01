# Documentação Deeper: Sistema de Denúncias (`sys_reporting_system`)

Este documento detalha a API \"Deeper\" para um sistema genérico de \"Denúncias\" (Reports), permitindo que usuários denunciem diferentes tipos de conteúdo (artigos, perfis, comentários, etc.) ou comportamentos que violem as diretrizes da comunidade. Ele se baseia no conceito de `sys_objects_report` e tabelas associadas do UNA.

## Abordagem \"Deeper\" para Denúncias:

O UNA usa `sys_objects_report` para definir instâncias de sistemas de denúncia, com `TableMain` para contagens agregadas e `TableTrack` para denúncias individuais.

Para \"Deeper\", podemos ter:

1.  **Tabela de Rastreamento Unificada (Proposta):** `deeper_reports_track`
    *   Armazenaria cada denúncia individual.
    *   Colunas: `id`, `system_name` (ex: \"deeper_articles_reports\", \"bx_persons_profile_reports\"), `object_id` (ID da entidade denunciada), `reporter_profile_id` (quem denunciou), `report_type` (categoria da denúncia, ex: \"spam\", \"abuso\", \"copyright\"), `comment` (texto adicional do denunciante), `status` ('new', 'pending_review', 'resolved', 'rejected'), `reported_at`, `checked_by_admin_id` (quem analisou), `checked_at`.
2.  **Atualização de Contadores:**
    *   Um campo de contagem de denúncias (ex: `reports_count` ou `reports` no UNA) na tabela da entidade principal (ex: `deeper_articles_entries`, `bx_persons_data`) seria atualizado quando uma nova denúncia (talvez apenas as ativas/não resolvidas) é feita.
    *   Opcionalmente, uma tabela agregada `deeper_object_reports_summary` (similar a `sys_reports` ou `TableMain` do UNA) poderia manter contagens totais ou por tipo de denúncia para cada objeto.

## Responsabilidades Principais da API de Denúncias:

*   Permitir que um usuário envie uma denúncia para um objeto específico, especificando um tipo e, opcionalmente, um comentário.
*   (Para Admin API) Listar denúncias pendentes.
*   (Para Admin API) Mudar o status de uma denúncia (ex: para \"resolvida\").
*   Retornar a contagem de denúncias (ativas) para um objeto (pode ser restrito a admins/moderadores).

## Estrutura da Documentação para Denúncias:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define o `CREATE TABLE` para `deeper_reports_track` e discute a atualização do contador/status na entidade principal ou tabela de resumo.

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Módulos de migração para criar as tabelas de denúncias.

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o `Deeper.InteractionSystems.ReportingRepo`.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful, geralmente aninhados sob o recurso principal (ex: `/articles/{id}/report`). Foco nos endpoints para usuários; endpoints de admin estarão em `07_studio_admin_api`.

## Considerações de Design:

*   **`system_name`**: Identifica a qual \"instância\" de sistema de denúncias uma entrada pertence.
*   **`object_id`**: O ID da entidade sendo denunciada.
*   **Tipos de Denúncia (`report_type`):** O sistema deve ter uma lista predefinida de tipos de denúncia (ex: spam, assédio, conteúdo impróprio, violação de direitos autorais). Isso pode ser uma configuração ou uma tabela separada (`deeper_report_types`).
*   **Status da Denúncia:** Para rastrear o ciclo de vida de uma denúncia.
*   **Uma Denúncia por Usuário por Objeto?**: Geralmente sim, para um mesmo `report_type`. Um usuário pode denunciar o mesmo objeto por motivos diferentes. A tabela track pode ter uma constraint UNIQUE em `(system_name, object_id, reporter_profile_id, report_type)`.
*   **ACL:** Quem pode denunciar (geralmente qualquer usuário logado). Quem pode gerenciar denúncias (admins/moderadores).
*   **Notificações:** Admins/moderadores devem ser notificados sobre novas denúncias.