# Documentação Deeper: Endpoints da API para Módulo de Grupos

Este documento especifica os endpoints RESTful para o módulo de Grupos (`deeper_groups`) do \"Deeper\".

Lembre-se das [Convenções de Design da API](../../00_core_concepts/api_design_conventions.md). Todos os endpoints abaixo estão sob o prefixo `/api/v1`.

## Grupos (`/groups`)

### 1. Criar um Novo Grupo

*   **`POST /groups`**
*   **Autenticação:** Requerida. O `profile_id` do criador será extraído do token JWT.
*   **Corpo da Requisição (JSON):**

```json
    {
      \"title\": \"Clube de Leitura Elixir BR\",
      \"slug\": \"clube-leitura-elixir-br\", // Opcional, pode ser gerado
      \"description\": \"Um grupo para discutir livros e artigos sobre Elixir e o ecossistema Beam.\",
      \"rules\": \"1. Respeito mútuo.\\n2. Foco em tópicos relevantes.\", // Opcional
      \"avatar_file_id\": 789, // Opcional, ID de `deeper_files`
      \"cover_file_id\": 790, // Opcional
      \"privacy_level\": \"public\", // \"public\", \"private\", \"secret\"
      \"allow_member_invites\": true, // Default: true
      \"join_approval_mode\": \"open\" // \"open\", \"approval\", \"invite_only\"
    }
```

```json
    {
      \"data\": {
        \"id\": 1,
        \"profile_id\": 45, // Criador
        \"title\": \"Clube de Leitura Elixir BR\",
        \"slug\": \"clube-leitura-elixir-br\",
        \"description\": \"Um grupo para discutir livros e artigos sobre Elixir e o ecossistema Beam.\",
        \"rules\": \"1. Respeito mútuo.\\n2. Foco em tópicos relevantes.\",
        \"avatar_file_id\": 789,
        \"avatar_details\": { /* ... detalhes do arquivo ... */ },
        \"cover_file_id\": 790,
        \"cover_details\": { /* ... detalhes do arquivo ... */ },
        \"privacy_level\": \"public\",
        \"allow_member_invites\": 1,
        \"join_approval_mode\": \"open\",
        \"status\": \"active\",
        \"members_count\": 1, // Criador é o primeiro membro
        \"created_at\": 1699980000,
        \"updated_at\": 1699980000,
        \"creator_profile\": { \"id\": 45, \"name\": \"Nome do Criador\" }
      }
    }
```

```json
    {
      \"data\": [ /* ... array de objetos de grupo ... */ ],
      \"pagination\": { /* ... */ }
    }
```

```json
    // Para solicitar entrada (se o grupo for 'approval' ou 'open' e o usuário ainda não for membro)
    {
      // \"message\": \"Gostaria de me juntar a este grupo.\" // Opcional, se houver tabela de join_requests
    }
    // Para aceitar um convite (o backend verifica se há um convite pendente para este profile_id)
    // Nenhum corpo específico necessário, ou pode ser um corpo vazio {}.
```

```json
        { \"data\": { \"group_id\": 1, \"profile_id\": 77, \"role\": \"member\", \"status\": \"active\", ... } }
```

```json
        { \"message\": \"Sua solicitação para entrar no grupo foi enviada para aprovação.\" }
```

```json
    {
      \"data\": [
        {
          \"profile_id\": 77,
          \"profile_details\": { \"name\": \"Membro Um\", \"avatar_url\": \"...\" },
          \"role\": \"member\",
          \"status\": \"active\",
          \"joined_at\": 1699981000
        }
        // ...
      ],
      \"pagination\": { /* ... */ }
    }
```

```json
    {
      \"role\": \"moderator\", // ou \"member\", \"admin\"
      \"status\": \"active\" // ou \"banned\", \"pending_approval\" (para aprovar)
      // \"ban_reason\": \"Violou as regras.\" // Se status=\"banned\"
    }
```

```json
    {
      \"body\": \"Conteúdo do post do grupo...\",
      \"parent_post_id\": null // ou ID de um post pai para um comentário/resposta
    }
```

*   **Resposta de Sucesso (201 Created):**

*   **Respostas de Erro:** `400` (validação, slug duplicado), `401`, `403`.

### 2. Listar Grupos

*   **`GET /groups`**
*   **Autenticação:** Opcional. Se não autenticado, apenas grupos `public` e `private` (sem conteúdo interno) são listados. Se autenticado, pode ver grupos `secret` dos quais é membro.
*   **Query Parameters:**
    *   `profile_id_creator` (integer): Filtrar por criador do grupo.
    *   `member_profile_id` (integer): Listar grupos dos quais este perfil é membro (status 'active').
    *   `privacy_level` (string): `public`, `private`, `secret`.
    *   `status` (string): `active`, `suspended_by_admin`.
    *   `q` (string): Termo de busca (título, descrição).
    *   `page`, `per_page`.
    *   `sort_by` (ex: `created_at_desc`, `members_count_desc`, `title_asc`).
    *   `include` (string CSV, ex: `creator_profile,avatar,cover`).
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:** `400`.

### 3. Obter um Grupo Específico

*   **`GET /groups/{id_or_slug}`**
*   **Autenticação:** Requerida para grupos `private` ou `secret` se o usuário não for membro.
*   **Query Parameters:**
    *   `include` (string CSV, ex: `creator_profile,avatar,cover,members_summary,my_membership_status`).
*   **Resposta de Sucesso (200 OK):** Formato similar à resposta do `POST /groups` (item individual).
    Pode incluir `my_membership_status: {\"role\": \"member\", \"status\": \"active\"}` se o usuário estiver logado.
*   **Respostas de Erro:** `401`, `403` (se privado/secreto e sem permissão), `404`.

### 4. Atualizar um Grupo

*   **`PUT /groups/{id}`** ou **`PATCH /groups/{id}`**
*   **Autenticação:** Requerida. Apenas o proprietário ou administrador/moderador do grupo (com permissões específicas) ou um admin do site.
*   **Corpo da Requisição (JSON):** Campos a serem atualizados.
*   **Resposta de Sucesso (200 OK):** Retorna o objeto de grupo atualizado.
*   **Respostas de Erro:** `400`, `401`, `403`, `404`.

### 5. Excluir um Grupo

*   **`DELETE /groups/{id}`**
*   **Autenticação:** Requerida. Apenas o proprietário ou um admin do site.
*   **Resposta de Sucesso (200 OK ou 204 No Content):**
*   **Respostas de Erro:** `401`, `403`, `404`.

## Membros do Grupo (`/groups/{group_id}/members`)

### 1. Solicitar Entrada em um Grupo / Aceitar Convite

*   **`POST /groups/{group_id}/members`** (para solicitar entrada ou aceitar um convite existente)
*   **Autenticação:** Requerida. `profile_id` do solicitante/convidado vem do JWT.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso:**
    *   `201 Created` (se adicionado diretamente ou convite aceito): corpo com detalhes da membresia.

    *   `202 Accepted` (se a solicitação foi para aprovação):

*   **Respostas de Erro:** `400`, `401`, `403` (ex: grupo é `invite_only` e não há convite), `404` (grupo não encontrado), `409` (já é membro, ou já tem solicitação pendente).

### 2. Listar Membros de um Grupo

*   **`GET /groups/{group_id}/members`**
*   **Autenticação:** Requerida (geralmente membros do grupo ou se o grupo for público).
*   **Query Parameters:**
    *   `role` (string): Filtrar por papel (`member`, `admin`, `moderator`).
    *   `status` (string): Filtrar por status (`active`, `pending_approval`, `invited`).
    *   `q` (string): Buscar por nome de membro.
    *   `page`, `per_page`.
    *   `sort_by` (ex: `joined_at_desc`, `member_name_asc`).
    *   `include` (string CSV, ex: `profile_details`).
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:** `401`, `403`, `404`.

### 3. Obter Detalhes de um Membro Específico do Grupo

*   **`GET /groups/{group_id}/members/{member_profile_id}`**
*   **Autenticação:** Requerida (geralmente membros do grupo).
*   **Query Parameters:** `include=profile_details`.
*   **Resposta de Sucesso (200 OK):** Detalhes da membresia.
*   **Respostas de Erro:** `401`, `403`, `404`.

### 4. Atualizar Status/Papel de um Membro (Admin/Mod do Grupo)

*   **`PUT /groups/{group_id}/members/{member_profile_id}`**
*   **Autenticação:** Requerida (Admin/Mod do grupo ou admin do site).
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):** Detalhes da membresia atualizada.
*   **Respostas de Erro:** `400`, `401`, `403`, `404`.

### 5. Remover um Membro / Sair do Grupo

*   **`DELETE /groups/{group_id}/members/{member_profile_id}`** (Admin/Mod remove outro membro)
*   **`DELETE /groups/{group_id}/members/me`** (Usuário logado sai do grupo)
*   **Autenticação:** Requerida.
*   **Resposta de Sucesso (200 OK ou 204 No Content):**
*   **Respostas de Erro:** `401`, `403`, `404`.

## Posts de Conteúdo do Grupo (`/groups/{group_id}/posts`)
(Assumindo a tabela `deeper_group_content_posts`)

### 1. Criar um Post no Grupo

*   **`POST /groups/{group_id}/posts`**
*   **Autenticação:** Requerida (membro do grupo com permissão para postar).
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (201 Created):** Objeto do post criado.
*   **Respostas de Erro:** `400`, `401`, `403`, `404`.

### 2. Listar Posts do Grupo

*   **`GET /groups/{group_id}/posts`**
*   **Autenticação:** Requerida (membro do grupo).
*   **Query Parameters:** `page`, `per_page`, `sort_by` (ex: `created_at_desc`), `parent_post_id` (para listar respostas a um post). `include=author_profile,attachments`.
*   **Resposta de Sucesso (200 OK):** Lista paginada de posts.
*   **Respostas de Erro:** `401`, `403`, `404`.

### 3. Obter, Atualizar, Excluir um Post Específico do Grupo

*   **`GET /groups/{group_id}/posts/{post_id}`**
*   **`PUT /groups/{group_id}/posts/{post_id}`** (ou `PATCH`)
*   **`DELETE /groups/{group_id}/posts/{post_id}`**
*   **Autenticação:** Requerida (lógica de permissão para autor/mod do grupo).

## Convites e Solicitações de Adesão (se tabelas `deeper_group_invites` / `_join_requests` forem implementadas)

*   **Convidar para o Grupo:** `POST /groups/{group_id}/invites`
    *   Corpo: `{ \"invited_profile_id\": 123 }` ou `{ \"invited_email\": \"user@example.com\" }`
*   **Listar Convites Pendentes (para o grupo - admin/mod):** `GET /groups/{group_id}/invites?status=pending`
*   **Listar Solicitações de Adesão Pendentes (para o grupo - admin/mod):** `GET /groups/{group_id}/join-requests?status=pending`
*   **Aprovar/Rejeitar Solicitação:** `PUT /groups/{group_id}/join-requests/{request_id}`
    *   Corpo: `{ \"action\": \"approve\" }` ou `{ \"action\": \"reject\" }`

Estes endpoints cobrem as funcionalidades centrais de um módulo de grupos. Interações como comentários/votos nos posts do grupo ou no grupo em si seriam tratadas pelos endpoints dos sistemas de interação genéricos.