# Documentação Deeper Studio API: Moderação de Comentários

Este documento descreve os endpoints da API de Administração (\"Studio API\") especificamente para a moderação de comentários feitos em vários tipos de conteúdo na plataforma \"Deeper\".

**Objetivo Principal:** Fornecer aos administradores/moderadores as ferramentas para revisar, aprovar, editar, marcar como spam ou deletar comentários.

## Entidades Relevantes:

*   Tabelas de comentários (ex: `bx_persons_cmts`, `bx_posts_cmts`, ou uma tabela genérica referenciada por `sys_objects_cmts.Table`).
*   `sys_objects_cmts`: Para obter o nome da tabela de comentários real para um `comments_object_name`.
*   `sys_cmts_ids` (se implementado e usado para status administrativo centralizado): Contém `status_admin` para comentários. Se não, o status pode ser um campo na própria tabela de comentários ou inferido. O UNA original usa `sys_cmts_ids.status_admin`. Para simplificar, vamos assumir por enquanto que o status de moderação pode ser um campo na própria tabela de comentários (ex: `cmt_status` podendo ser `approved`, `pending`, `spam`, `deleted`) ou gerenciado via `sys_cmts_ids`.

## Módulos de Acesso a Dados Envolvidos:

*   `Deeper.Interactions.CommentsRepo`: Precisará de funções para:
    *   Listar comentários com filtros por status de moderação, `cmt_object_id`, `comments_object_name`.
    *   Atualizar o status de moderação de um comentário.
    *   Editar o texto de um comentário.
    *   Deletar um comentário (hard delete ou soft delete com status).

## Endpoints da API de Admin para Moderação de Comentários (`/api/v1/admin/moderation/comments`):

O `{comments_object_name}` é o nome do sistema de comentários de `sys_objects_cmts` (ex: `bx_persons_profile`). O `{comment_id}` é o ID do comentário na tabela específica de comentários.

### 1. Listar Comentários para Moderação

*   **Endpoint:** `GET /api/v1/admin/moderation/comments`
*   **Autenticação:** Requer JWT de Admin/Moderador.
*   **Query Parameters:**
    *   `page`, `per_page`, `sort_by` (ex: `cmt_time_asc`).
    *   `filter_comments_object_name` (opcional, para filtrar por um sistema de comentários específico).
    *   `filter_object_id` (opcional, para filtrar comentários de um item de conteúdo específico).
    *   `filter_author_id` (opcional, para filtrar comentários de um autor específico).
    *   `filter_status` (obrigatório ou opcional, ex: `pending`, `approved`, `spam`, `all`).
    *   `filter_text_like`.
    *   `lang` (para tradução de títulos de conteúdo associado, etc.).
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"comment_id\": 501,
          \"comments_object_name\": \"bx_posts_entity\", // De onde veio (sys_objects_cmts.Name)
          \"object_id\": 1024, // ID do post comentado
          \"object_title\": \"Título do Post Comentado\", // Buscado da tabela do conteúdo pai
          \"object_url_admin\": \"/admin/content/posts/1024\", // Link para gerenciar o conteúdo pai
          \"text\": \"Este é um comentário aguardando moderação.\",
          \"author\": {
            \"profile_id\": 789,
            \"fullname\": \"Jane Doe\",
            \"avatar_url\": \"...\"
          },
          \"timestamp\": 1679000000,
          \"status\": \"pending\", // 'pending', 'approved', 'spam', 'deleted_by_mod'
          \"parent_id\": 0
        }
        // ... outros comentários ...
      ],
      \"pagination\": { /* ... */ }
    }
```

```json
    {
      \"status\": \"approved\" // Valores: \"approved\", \"spam\", \"pending\"
    }
```

```json
    {
      \"text\": \"Texto do comentário editado pelo moderador.\"
    }
```

```json
    {
      \"reason\": \"Violação dos termos de serviço.\", // Opcional
      \"delete_type\": \"soft\" // \"soft\" (marca como deletado) ou \"hard\" (remove do DB)
    }
```

```json
    {
      \"action\": \"approve\", // \"approve\", \"mark_spam\", \"delete_hard\", \"delete_soft\"
      \"comment_refs\": [ // Referências aos comentários
        {\"comments_object_name\": \"bx_posts_entity\", \"comment_id\": 501},
        {\"comments_object_name\": \"bx_persons_profile\", \"comment_id\": 502}
      ]
    }
```

```json
    {
      \"data\": {
        \"processed_count\": 2,
        \"success_count\": 2,
        \"errors_count\": 0,
        \"errors\": []
      }
    }
```

*   **Lógica do Backend:**
    *   O `CommentsRepo.list_comments_for_moderation` precisará de JOINs para buscar o título/link do conteúdo pai e informações do autor.
    *   A filtragem por `comments_object_name` implica que o Repo pode precisar iterar sobre múltiplas tabelas de comentários se não houver uma tabela centralizada como `sys_cmts_ids` com status global. Se `sys_cmts_ids` for usada, a query seria mais simples.

### 2. Atualizar Status de um Comentário

*   **Endpoint:** `PUT /api/v1/admin/moderation/comments/{comments_object_name}/{comment_id}/status`
*   **Autenticação:** Requer JWT de Admin/Moderador.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):** Retorna o comentário atualizado.
*   **Lógica do Backend:**
    *   `CommentsRepo.update_comment_status(comments_object_name, comment_id, new_status, admin_profile_id)`.
    *   Atualiza o status na tabela de comentários ou em `sys_cmts_ids.status_admin`.
    *   Pode precisar ajustar contadores de comentários no conteúdo pai se um comentário for de \"pending\" para \"approved\" ou vice-versa, ou se for marcado como spam e não deve contar.

### 3. Editar o Texto de um Comentário

*   **Endpoint:** `PUT /api/v1/admin/moderation/comments/{comments_object_name}/{comment_id}/text`
*   **Autenticação:** Requer JWT de Admin/Moderador.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):** Retorna o comentário atualizado.
*   **Lógica do Backend:** `CommentsRepo.edit_comment_text(comments_object_name, comment_id, new_text, admin_profile_id)`. Pode adicionar uma nota de que foi editado por um moderador.

### 4. Deletar um Comentário (Ação de Moderação)

*   **Endpoint:** `DELETE /api/v1/admin/moderation/comments/{comments_object_name}/{comment_id}`
*   **Autenticação:** Requer JWT de Admin/Moderador.
*   **Corpo da Requisição (Opcional JSON):**

*   **Resposta de Sucesso (204 No Content ou 200 OK).**
*   **Lógica do Backend:**
    *   `CommentsRepo.delete_comment_by_moderator(...)`.
    *   Se \"soft\", atualiza um status para \"deleted_by_moderator\".
    *   Se \"hard\", remove o registro.
    *   Ajusta contadores de comentários e respostas.

### 5. Ações em Lote para Comentários

*   **Endpoint:** `POST /api/v1/admin/moderation/comments/bulk-action`
*   **Autenticação:** Requer JWT de Admin/Moderador.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):**

*   **Lógica do Backend:** Itera sobre `comment_refs` e aplica a ação a cada um. Deve ser transacional por comentário ou para o lote inteiro se possível.

## Considerações:

*   **`sys_cmts_ids`:** Se o sistema UNA depende fortemente de `sys_cmts_ids.status_admin` para o status de moderação, o `CommentsRepo` deve priorizar a atualização desta tabela. Se o status estiver na tabela de comentários específica (ex: `bx_persons_cmts.cmt_status_moderation`), então essa é atualizada.
*   **Notificações ao Usuário:** Ações de moderação (especialmente deleção ou marcação como spam) podem opcionalmente notificar o autor do comentário.
*   **Logs de Moderação:** Todas as ações de moderação devem ser registradas em um log de auditoria (`sys_audit`) para rastreabilidade.