# Documentação Deeper: API de Administração - Gerenciamento de Grupos

Este documento descreve os endpoints da API \"Deeper\" para administradores gerenciarem o conteúdo e as configurações do módulo de Grupos (`deeper_groups`).

## Escopo e Funcionalidades:

*   Listar todos os grupos com filtros avançados (status, autor, categoria, privacidade).
*   Visualizar detalhes completos de um grupo (visão de admin).
*   Criar novos grupos (como administrador).
*   Atualizar grupos existentes.
*   Alterar o status de grupos (ativo, suspenso, pendente).
*   Gerenciar categorias de grupos.
*   Gerenciar membros de grupos (adicionar, remover, alterar papel, alterar status de adesão).
*   Moderar conteúdo postado dentro dos grupos (se aplicável).

## Tabelas Relevantes (Já Definidas em `docs/03_content_modules/deeper_groups/`):

*   `deeper_groups_entries`
*   `deeper_groups_categories`
*   `deeper_groups_members`
*   `deeper_groups_invites`
*   `deeper_groups_content_feed` (e outras tabelas de conteúdo do grupo)

## Módulo de Acesso a Dados (a ser definido em `docs/03_content_modules/deeper_groups/data_access_module.md`):

*   `Deeper.Content.GroupsRepo` será utilizado.

## Endpoints da API de Administração para Grupos

Todos os endpoints estão sob `/api/v1/admin/content/groups/...` e requerem autenticação de administrador.

### Gerenciamento de Categorias de Grupos (Admin)
*(Endpoints similares aos de `events_admin_api.md` para categorias)*
*   `GET /api/v1/admin/content/groups/categories`
*   `POST /api/v1/admin/content/groups/categories`
*   `GET /api/v1/admin/content/groups/categories/{categoryId}`
*   `PUT /api/v1/admin/content/groups/categories/{categoryId}`
*   `DELETE /api/v1/admin/content/groups/categories/{categoryId}`

### Gerenciamento de Entradas de Grupos (`deeper_groups_entries`)

#### 1. Listar Grupos (Visão de Admin)
*   **Endpoint:** `GET /api/v1/admin/content/groups/entries`
*   **Query Parameters:** `offset`, `limit`, `search_term` (por `title`, `group_name`, `description`), `status`, `author_profile_id`, `category_id`, `privacy_type`, `sort_by`.
*   **Resposta (200 OK):** Lista paginada de grupos com campos relevantes para admin.

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"title\": \"Grupo de Admin de Elixir\",
          \"group_name\": \"elixir-admins\",
          \"author_profile_id\": 1,
          \"author_fullname\": \"Super Admin\",
          \"category_name\": \"Desenvolvimento\",
          \"privacy_type\": \"private\",
          \"status\": \"active\",
          \"members_count\": 15,
          \"created_at\": 1679500000
        }
      ],
      \"pagination\": { /* ... */ }
    }
```

```json
    {
      \"data\": [
        {
          \"membership_id\": 1, // deeper_groups_members.id
          \"group_id\": 10,
          \"profile_id\": 25,
          \"profile_fullname\": \"Membro Ativo\",
          \"profile_email\": \"membro@example.com\",
          \"role\": \"member\",
          \"status\": \"active\",
          \"joined_at\": 1679510000
        }
      ],
      \"pagination\": { /* ... */ }
    }
```

```json
    {
      \"profile_id\": 30,
      \"role\": \"moderator\",
      \"status\": \"active\" // Admin pode adicionar diretamente como ativo
    }
```

```json
    {
      \"role\": \"admin\", // Promover para admin do grupo
      \"status\": \"active\" // Ex: Aprovar um pedido pendente
    }
```

#### 2. Obter Detalhes de um Grupo (Visão de Admin)
*   **Endpoint:** `GET /api/v1/admin/content/groups/entries/{groupId}`
*   **Resposta (200 OK):** Detalhes completos do grupo, incluindo contadores, configurações, e talvez uma prévia de membros ou conteúdo recente.

#### 3. Criar Novo Grupo (como Admin)
*   **Endpoint:** `POST /api/v1/admin/content/groups/entries`
*   **Corpo (JSON):** Campos de `deeper_groups_entries` (ex: `author_profile_id`, `title`, `group_name`, `description`, `category_id`, `privacy_type`, `status`).
*   **Resposta (201 Created).**

#### 4. Atualizar Grupo (como Admin)
*   **Endpoint:** `PUT /api/v1/admin/content/groups/entries/{groupId}`
*   **Corpo (JSON):** Campos de `deeper_groups_entries` a atualizar.
*   **Resposta (200 OK).**

#### 5. Deletar Grupo (Soft ou Hard Delete - como Admin)
*   **Endpoint:** `DELETE /api/v1/admin/content/groups/entries/{groupId}`
*   **Query Parameters:** `permanent` (Boolean, Opcional).
*   **Lógica:** Soft delete muda `status`. Hard delete remove o grupo e, via `CASCADE`, seus membros, convites, conteúdo do feed, etc.
*   **Resposta (204 No Content).**

### Gerenciamento de Membros de Grupos (`deeper_groups_members`) - Admin

#### 1. Listar Membros de um Grupo (Admin)
*   **Endpoint:** `GET /api/v1/admin/content/groups/entries/{groupId}/members`
*   **Query Parameters:** `offset`, `limit`, `role_filter`, `status_filter` (ex: `pending_approval`), `search_term` (pelo nome do membro).
*   **Resposta (200 OK):** Lista paginada de membros com detalhes do perfil e do status da membresia.

#### 2. Adicionar Membro a um Grupo (Admin)
*   **Endpoint:** `POST /api/v1/admin/content/groups/entries/{groupId}/members`
*   **Corpo (JSON):**

*   **Resposta (201 Created).**

#### 3. Atualizar Membresia (Papel, Status) de um Usuário em um Grupo (Admin)
*   **Endpoint:** `PUT /api/v1/admin/content/groups/members/{membershipId}` (onde `{membershipId}` é `deeper_groups_members.id`)
*   **Corpo (JSON):**

*   **Resposta (200 OK).**

#### 4. Remover Membro de um Grupo (Admin)
*   **Endpoint:** `DELETE /api/v1/admin/content/groups/members/{membershipId}`
*   **Resposta (204 No Content).**

### Gerenciamento de Convites para Grupos (`deeper_groups_invites`) - Admin

#### 1. Listar Convites de um Grupo (Admin)
*   **Endpoint:** `GET /api/v1/admin/content/groups/entries/{groupId}/invites`
*   **Query Parameters:** `offset`, `limit`, `status_filter` (`pending`, `accepted`, etc.), `search_term` (por email do convidado ou nome do convidante).
*   **Resposta (200 OK):** Lista paginada de convites.

#### 2. (Opcional) Criar Convite (Admin)
*   **Endpoint:** `POST /api/v1/admin/content/groups/entries/{groupId}/invites`
*   **Corpo (JSON):** `{ \"invited_profile_id\": 45 }` ou `{ \"invited_email\": \"novo@example.com\" }`, `expires_at` (opcional).
*   **Lógica:** O `inviter_profile_id` seria o admin logado.
*   **Resposta (201 Created).**

#### 3. (Opcional) Revogar/Deletar Convite (Admin)
*   **Endpoint:** `DELETE /api/v1/admin/content/groups/invites/{inviteId}`
*   **Resposta (204 No Content).**

### Moderação de Conteúdo do Feed do Grupo (`deeper_groups_content_feed`) - Admin

#### 1. Listar Posts do Feed de um Grupo (Admin)
*   **Endpoint:** `GET /api/v1/admin/content/groups/entries/{groupId}/feed-posts`
*   **Query Parameters:** `offset`, `limit`, `author_profile_id_filter`, `search_term`.
*   **Resposta (200 OK):** Lista paginada de posts.

#### 2. Obter Detalhes de um Post do Feed (Admin)
*   **Endpoint:** `GET /api/v1/admin/content/groups/feed-posts/{postId}`
*   **Resposta (200 OK).**

#### 3. Atualizar Post do Feed (Admin)
*   **Endpoint:** `PUT /api/v1/admin/content/groups/feed-posts/{postId}`
*   **Corpo (JSON):** `{ \"content_text\": \"Conteúdo editado pelo admin.\" }`
*   **Resposta (200 OK).**

#### 4. Deletar Post do Feed (Admin)
*   **Endpoint:** `DELETE /api/v1/admin/content/groups/feed-posts/{postId}`
*   **Resposta (204 No Content).**

Esta API de administração para grupos permite um controle robusto sobre as comunidades dentro da plataforma \"Deeper\".