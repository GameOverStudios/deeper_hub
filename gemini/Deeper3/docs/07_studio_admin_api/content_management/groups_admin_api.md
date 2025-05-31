# API de Administração: Gerenciamento de Grupos (`deeper_groups`)

Endpoints da API para administradores e moderadores globais gerenciarem o conteúdo e a estrutura do módulo `deeper_groups`. As permissões de moderadores *dentro* de um grupo específico são tratadas pelos endpoints públicos com verificações de papel no grupo.

**Permissões:** Todos os endpoints aqui requerem um papel de administrador do site ou um super-moderador com permissões para gerenciar todos os grupos.

## Endpoints para Grupos

### 1. Listar Todos os Grupos (Visão Administrativa)

*   **`GET /admin/groups`**
*   **Autenticação:** Admin Requerida.
*   **Diferenças da API Pública (`GET /groups`):**
    *   Retorna grupos de **todos** os criadores.
    *   Pode listar grupos com **qualquer status** (`active`, `suspended_by_admin`, `deleted_by_owner`) por padrão ou via filtro.
    *   Pode listar grupos com **qualquer nível de privacidade** (`public`, `private`, `secret`).
*   **Query Parameters:**
    *   `profile_id_creator` (integer): Filtrar por criador.
    *   `privacy_level` (string).
    *   `status` (string).
    *   `q` (string): Termo de busca (título, descrição).
    *   `page`, `per_page`.
    *   `sort_by` (ex: `created_at_desc`, `members_count_desc`, `updated_at_desc`).
    *   `include` (ex: `creator_profile,avatar,cover,admin_notes`).
*   **Resposta de Sucesso (200 OK):** Lista paginada de todos os grupos.

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"title\": \"Grupo Suspenso para Revisão\",
          \"status\": \"suspended_by_admin\",
          \"privacy_level\": \"secret\",
          \"creator_profile\": { \"id\": 45, \"name\": \"Usuário Z\" },
          // ... outros campos do grupo ...
          \"admin_notes\": \"Atividade suspeita reportada.\"
        }
      ],
      \"pagination\": { /* ... */ }
    }
```

```json
    {
      \"title\": \"Nome do Grupo Editado por Admin\",
      \"status\": \"active\", // Ex: Admin reativa um grupo suspenso
      \"privacy_level\": \"private\",
      \"creator_profile_id\": 60, // Transferir propriedade (ação poderosa)
      \"admin_notes\": \"Propriedade transferida, grupo reativado.\"
    }
```

```json
    {
      \"profile_id\": 123, // ID do perfil a ser adicionado
      \"role\": \"moderator\", // \"member\", \"moderator\", \"admin\" (owner é geralmente o criador)
      \"status\": \"active\" // Força o status
    }
```

```json
    {
      \"role\": \"admin\",
      \"status\": \"active\" // ou \"banned\", \"left\"
      // \"ban_reason\": \"...\"
    }
```

*   **Respostas de Erro:** `401`, `403`.

### 2. Obter Detalhes de Qualquer Grupo (Visão Administrativa)

*   **`GET /admin/groups/{id_or_slug}`**
*   **Autenticação:** Admin Requerida.
*   **Query Parameters:** `include` (ex: `creator_profile,avatar,cover,all_members_summary,moderation_logs`).
*   **Resposta de Sucesso (200 OK):** Objeto completo do grupo.
*   **Respostas de Erro:** `401`, `403`, `404`.

### 3. Atualizar Qualquer Grupo (Ação Administrativa)

*   **`PUT /admin/groups/{id}`** (ou `PATCH`)
*   **Autenticação:** Admin Requerida.
*   **Diferenças da API Pública:** Permite editar grupos de qualquer criador. Pode permitir a alteração de campos como `creator_profile_id` (transferir propriedade), forçar status ou nível de privacidade.
*   **Corpo da Requisição (JSON):** Campos a serem atualizados.

*   **Resposta de Sucesso (200 OK):** Objeto do grupo atualizado.
*   **Respostas de Erro:** `400`, `401`, `403`, `404`.

### 4. Excluir Qualquer Grupo (Ação Administrativa)

*   **`DELETE /admin/groups/{id}`**
*   **Autenticação:** Admin Requerida.
*   **Opções (Query Param ou Corpo):**
    *   `reason` (string): Motivo da exclusão.
    *   `notify_creator` (boolean, default: true).
*   **Resposta de Sucesso (200 OK ou 204 No Content):**
*   **Respostas de Erro:** `401`, `403`, `404`.

## Endpoints para Membros de Grupos (Visão Administrativa)

Estes endpoints permitem que um administrador do site gerencie membros de *qualquer* grupo.

### 1. Listar Membros de Qualquer Grupo

*   **`GET /admin/groups/{group_id}/members`**
*   **Autenticação:** Admin Requerida.
*   **Diferenças da API Pública:** Acesso irrestrito à lista de membros de qualquer grupo.
*   **Query Parameters:** `role`, `status`, `q` (buscar por nome), `page`, `per_page`, `include=profile_details`.
*   **Resposta de Sucesso (200 OK):** Lista paginada de membros do grupo.

### 2. Adicionar Membro a Qualquer Grupo (Ação Administrativa)

*   **`POST /admin/groups/{group_id}/members`**
*   **Autenticação:** Admin Requerida.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (201 Created):** Detalhes da nova membresia.
*   **Ação do Backend:** Adiciona o membro e recalcula `members_count` no grupo.

### 3. Atualizar Membro de Qualquer Grupo (Ação Administrativa)

*   **`PUT /admin/groups/{group_id}/members/{member_profile_id}`**
*   **Autenticação:** Admin Requerida.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):** Detalhes da membresia atualizada.
*   **Ação do Backend:** Atualiza a membresia e recalcula `members_count` se o status mudar de/para 'active'.

### 4. Remover Membro de Qualquer Grupo (Ação Administrativa)

*   **`DELETE /admin/groups/{group_id}/members/{member_profile_id}`**
*   **Autenticação:** Admin Requerida.
*   **Resposta de Sucesso (200 OK ou 204 No Content):**
*   **Ação do Backend:** Remove a membresia e recalcula `members_count`.

## Endpoints para Conteúdo Interno de Grupos (Ex: `deeper_group_content_posts` - Visão Administrativa)

Se os grupos tiverem seu próprio conteúdo (como posts de discussão), os administradores do site precisariam de endpoints para moderá-los.

### 1. Listar Posts de Conteúdo de Qualquer Grupo

*   **`GET /admin/groups/{group_id}/posts`**
*   **Autenticação:** Admin Requerida.
*   **Query Parameters:** `author_profile_id`, `q`, `page`, `per_page`, `sort_by`, `include=author_profile`.
*   **Resposta de Sucesso (200 OK):** Lista paginada de posts do grupo.

### 2. Obter Detalhes de Qualquer Post de Conteúdo de Grupo

*   **`GET /admin/group-posts/{post_id}`** (Rota não aninhada para acesso direto por ID do post)
*   **Autenticação:** Admin Requerida.
*   **Resposta de Sucesso (200 OK):** Objeto completo do post do grupo.

### 3. Atualizar Qualquer Post de Conteúdo de Grupo

*   **`PUT /admin/group-posts/{post_id}`** (ou `PATCH`)
*   **Autenticação:** Admin Requerida.
*   **Corpo da Requisição (JSON):** `{ \"body\": \"Conteúdo editado pelo admin.\", \"status\": \"active\" }`
*   **Resposta de Sucesso (200 OK):** Objeto do post atualizado.

### 4. Excluir Qualquer Post de Conteúdo de Grupo

*   **`DELETE /admin/group-posts/{post_id}`**
*   **Autenticação:** Admin Requerida.
*   **Resposta de Sucesso (200 OK ou 204 No Content):**

## Considerações para Repositórios e Contextos:

*   **`Deeper.Content.GroupsRepo`:**
    *   Funções de listagem (`list_groups`, `list_group_members`, `list_group_posts`) precisarão de variantes ou flags `as_admin: true` para bypassar filtros de privacidade, status ou propriedade.
    *   Funções CRUD (create, update, delete) para grupos, membros e posts de grupo precisarão aceitar chamadas de administradores que podem modificar dados de outros usuários ou alterar status protegidos.
    *   A lógica de atualização de `members_count` e outros contadores denormalizados permanece crucial.
*   **`Deeper.Content.Groups` (Contexto/Serviço):**
    *   Implementará a lógica de verificação de permissões: o `current_user_profile` é o proprietário/moderador do grupo específico (para ações de moderação de grupo) OU um administrador do site (para ações de superusuário)?
    *   Coordenará ações que afetam múltiplas entidades (ex: transferir propriedade de um grupo envolve atualizar `deeper_groups.profile_id` e potencialmente o papel do antigo e novo proprietário em `deeper_group_members`).
*   **Log de Auditoria:** Todas as ações administrativas (suspender grupo, transferir propriedade, banir membro de grupo, deletar conteúdo de grupo) devem ser rigorosamente logadas.

Estes endpoints administrativos fornecem as ferramentas necessárias para a moderação e gerenciamento global de grupos e seu conteúdo associado.