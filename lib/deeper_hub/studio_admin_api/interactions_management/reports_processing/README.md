# Documentação Deeper Studio API: Processamento de Denúncias

Este documento descreve os endpoints da API de Administração (\"Studio API\") para o processamento de denúncias (reports) submetidas por usuários contra vários tipos de conteúdo.

**Objetivo Principal:** Permitir que administradores/moderadores visualizem denúncias pendentes, investiguem o conteúdo denunciado, e tomem ações apropriadas, atualizando o status da denúncia.

## Entidades Relevantes:

*   Tabelas de rastreamento de denúncias (ex: `bx_persons_reports_track`, `bx_posts_reports_track`, ou uma tabela genérica referenciada por `sys_objects_report.table_track`). Estas tabelas contêm `status` e `checked_by`.
*   `sys_objects_report`: Para obter o nome da tabela de rastreamento real para um `report_object_name`.
*   As tabelas do conteúdo que foi denunciado (para visualização e tomada de ação).

## Módulos de Acesso a Dados Envolvidos:

*   `Deeper.Interactions.ReportingRepo`: Precisará de funções para:
    *   Listar denúncias com filtros por status, `report_object_name`, `object_id`.
    *   Obter detalhes de uma denúncia específica.
    *   Atualizar o `status` e `checked_by` de uma denúncia na `table_track`.

## Endpoints da API de Admin para Processamento de Denúncias (`/api/v1/admin/moderation/reports`):

O `{report_object_name}` é o nome do sistema de denúncias de `sys_objects_report` (ex: `bx_persons`). O `{report_track_id}` é o ID da denúncia na tabela específica de rastreamento de denúncias (ex: `bx_persons_reports_track.id`).

### 1. Listar Denúncias para Processamento

*   **Endpoint:** `GET /api/v1/admin/moderation/reports`
*   **Autenticação:** Requer JWT de Admin/Moderador.
*   **Query Parameters:**
    *   `page`, `per_page`, `sort_by` (ex: `date_asc`).
    *   `filter_report_object_name` (opcional).
    *   `filter_object_id` (opcional).
    *   `filter_reporter_author_id` (opcional).
    *   `filter_status` (obrigatório ou opcional, ex: `0` para pendente, `1` para aceita, `2` para rejeitada, `all`).
    *   `lang`.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"report_track_id\": 77,
          \"report_object_name\": \"bx_persons\",
          \"object_id\": 123, // ID do perfil/post denunciado
          \"object_title_snippet\": \"Perfil de John Doe...\", // Snippet do conteúdo denunciado
          \"object_admin_link\": \"/admin/content/persons/123\", // Link para ver/gerenciar o conteúdo
          \"reporter\": {
            \"profile_id\": 789,
            \"fullname\": \"Jane Reporter\"
          },
          \"report_type\": \"spam\",
          \"report_text_snippet\": \"Este perfil parece ser falso e está postando...\",
          \"report_date_timestamp\": 1679001000,
          \"status_code\": 0, // 0=pendente, 1=aceita, 2=rejeitada
          \"status_text\": \"Pendente\", // Traduzido
          \"checked_by_admin_id\": null,
          \"checked_by_admin_name\": null
        }
        // ... outras denúncias ...
      ],
      \"pagination\": { /* ... */ }
    }
```

```json
    {
      \"status_code\": 1, // 0=pendente, 1=aceita (ação tomada), 2=rejeitada (sem ação)
      \"moderator_notes\": \"Conteúdo removido por violar termos.\" // Opcional
    }
```

```json
    {
      \"action\": \"mark_rejected\", // \"mark_accepted\", \"mark_rejected\"
      \"report_refs\": [
        {\"report_object_name\": \"bx_posts_entity\", \"report_track_id\": 77},
        {\"report_object_name\": \"bx_persons\", \"report_track_id\": 78}
      ],
      \"moderator_notes\": \"Rejeitadas em lote - sem violação aparente.\"
    }
```

*   **Lógica do Backend:** `ReportingRepo.list_reports_by_status` fará JOINs para obter informações do denunciante e um snippet/link para o conteúdo denunciado.

### 2. Obter Detalhes de uma Denúncia Específica

*   **Endpoint:** `GET /api/v1/admin/moderation/reports/{report_object_name}/track/{report_track_id}`
*   **Autenticação:** Requer JWT de Admin/Moderador.
*   **Resposta de Sucesso (200 OK):** Retorna todos os detalhes da denúncia, incluindo o `text` completo, e mais detalhes sobre o conteúdo denunciado.

### 3. Atualizar Status de uma Denúncia

*   **Endpoint:** `PUT /api/v1/admin/moderation/reports/{report_object_name}/track/{report_track_id}/status`
*   **Autenticação:** Requer JWT de Admin/Moderador.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):** Retorna a denúncia atualizada.
*   **Lógica do Backend:**
    *   `ReportingRepo.update_report_status_admin(report_object_name, report_track_id, new_status_code, admin_profile_id, moderator_notes)`.
    *   Atualiza `status`, `checked_by` (com o `profile_id` do admin), e possivelmente um campo de notas de moderação na `table_track`.
    *   **Importante:** Esta API *apenas atualiza o status da denúncia*. A ação real sobre o conteúdo denunciado (ex: deletar o post, banir o usuário) deve ser feita através de outros endpoints da API de Admin (ex: `DELETE /api/v1/admin/content/posts/{post_id}`). A UI de admin coordenaria essas ações.

### 4. Ações em Lote para Denúncias

*   **Endpoint:** `POST /api/v1/admin/moderation/reports/bulk-action`
*   **Autenticação:** Requer JWT de Admin/Moderador.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):** Resumo das operações.

## Considerações:

*   **Integração com Ações de Conteúdo:** O fluxo de trabalho de um moderador geralmente envolve:
    1.  Visualizar uma denúncia.
    2.  Inspecionar o conteúdo denunciado (usando o `object_admin_link` ou buscando o conteúdo pela API).
    3.  Tomar uma decisão sobre o conteúdo (ex: deletar, editar, avisar o usuário).
    4.  Atualizar o status da denúncia para \"aceita\" ou \"rejeitada\".
    A API de processamento de denúncias foca no passo 4. Os outros passos usam outras partes da API de Admin.
*   **Notificações:** Opcionalmente, o sistema pode notificar o denunciante sobre o resultado da sua denúncia.
*   **Tipos de Denúncia (`type`):** A lista de tipos de denúncia válidos (para filtro ou informação) pode ser obtida de `sys_form_pre_lists` (ex: chave `bx_report_type`).

Esta API de processamento de denúncias é crucial para manter a saúde da comunidade na plataforma \"Deeper\".