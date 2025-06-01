# Documentação Deeper: Endpoints da API para Conexões de Perfil (`sys_connections`)

Este documento especifica os endpoints RESTful da API \"Deeper\" para gerenciar conexões entre perfis, como amizades, seguir/assinaturas e bloqueios.

**Autenticação:** Todos os endpoints que modificam conexões ou listam conexões privadas exigirão autenticação via JWT (Bearer Token).

**Formato de Resposta:** JSON.

**Convenção:**
*   `{profile_id}` refere-se ao `id` da tabela `sys_profiles`.
*   `{user_profile_id}` geralmente se refere ao `profile_id` do usuário autenticado, obtido do JWT.
*   `{target_profile_id}` refere-se ao `profile_id` do outro usuário envolvido na ação.

---

## 1. Amizades (`/api/v1/profiles/{user_profile_id}/friendships`)

### `POST /api/v1/profiles/{user_profile_id}/friendships/request/{target_profile_id}`
*   **Descrição:** Envia uma solicitação de amizade de `{user_profile_id}` para `{target_profile_id}`.
*   **Autenticação:** Requerida (o `{user_profile_id}` deve ser o do usuário autenticado).
*   **Corpo da Requisição:** Vazio.
*   **Resposta de Sucesso (200 OK ou 201 Created):**

```json
    {
      \"data\": {
        \"status\": \"request_sent\",
        \"requester_id\": 1, // user_profile_id
        \"target_id\": 2     // target_profile_id
      }
    }
```

```json
    {
      \"data\": {
        \"status\": \"friends\",
        \"profile1_id\": 1, // user_profile_id
        \"profile2_id\": 2  // requester_profile_id
      }
    }
```

```json
    {
      \"data\": [
        {
          \"profile_id\": 3,
          \"display_name\": \"Alice Friend\",
          \"avatar_url\": \"...\",
          \"friendship_added_at\": 1678890000 // Timestamp da amizade
        }
        // ... mais amigos
      ],
      \"pagination\": { ... }
    }
```

```json
    {
      \"data\": [
        {
          \"requester_profile_id\": 4,
          \"display_name\": \"Bob Requester\",
          \"avatar_url\": \"...\",
          \"request_added_at\": 1678891000
        }
      ],
      \"pagination\": { ... }
    }
```

```json
    {
      \"data\": [
        {
          \"target_profile_id\": 5,
          \"display_name\": \"Charlie Target\",
          \"avatar_url\": \"...\",
          \"request_added_at\": 1678892000
        }
      ],
      \"pagination\": { ... }
    }
```

```json
    {
      \"data\": {
        \"status\": \"following\",
        \"follower_id\": 1, // user_profile_id
        \"followed_id\": 2  // target_profile_id
      }
    }
```

```json
    {
      \"data\": [
        {
          \"profile_id\": 6,
          \"display_name\": \"David Follower\",
          \"avatar_url\": \"...\",
          \"followed_at\": 1678893000
        }
      ],
      \"pagination\": { ... }
    }
```

```json
    {
      \"data\": [
        {
          \"profile_id\": 7,
          \"display_name\": \"Eve Followed\",
          \"avatar_url\": \"...\",
          \"following_since\": 1678894000
        }
      ],
      \"pagination\": { ... }
    }
```

```json
    {
      \"data\": {
        \"status\": \"blocked\",
        \"blocker_id\": 1, // user_profile_id
        \"blocked_id\": 2  // target_profile_id
      }
    }
```

```json
    {
      \"data\": [
        {
          \"profile_id\": 8,
          \"display_name\": \"Frank Blocked\",
          \"avatar_url\": \"...\",
          \"blocked_at\": 1678895000
        }
      ],
      \"pagination\": { ... }
    }
```

```json
    {
      \"data\": {
        \"profile1_id\": 1,
        \"profile2_id\": 2,
        \"friendship_status\": \"friends\", // \"not_friends\", \"request_sent_by_profile1\", \"request_received_by_profile1\"
        \"following_status_profile1_to_profile2\": \"following\", // \"not_following\"
        \"following_status_profile2_to_profile1\": \"not_following\", // \"following\" (se profile2 segue profile1)
        \"block_status\": \"none\" // \"profile1_blocked_profile2\", \"profile2_blocked_profile1\"
      }
    }
```

*   **Respostas de Erro:** `400 Bad Request` (ex: tentar adicionar a si mesmo), `401 Unauthorized`, `403 Forbidden` (ex: alvo bloqueou o usuário), `404 Not Found` (target_profile_id não existe), `409 Conflict` (ex: solicitação já existe, já são amigos).

### `POST /api/v1/profiles/{user_profile_id}/friendships/accept/{requester_profile_id}`
*   **Descrição:** `{user_profile_id}` aceita uma solicitação de amizade de `{requester_profile_id}`.
*   **Autenticação:** Requerida.
*   **Corpo da Requisição:** Vazio.
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:** `401`, `403`, `404` (solicitação não encontrada ou requester_profile_id inválido).

### `POST /api/v1/profiles/{user_profile_id}/friendships/reject/{requester_profile_id}`
*   **Descrição:** `{user_profile_id}` rejeita uma solicitação de amizade de `{requester_profile_id}`.
*   **Autenticação:** Requerida.
*   **Corpo da Requisição:** Vazio.
*   **Resposta de Sucesso (200 OK ou 204 No Content).**
*   **Respostas de Erro:** `401`, `403`, `404`.

### `DELETE /api/v1/profiles/{user_profile_id}/friendships/{friend_profile_id}`
*   **Descrição:** Remove a amizade entre `{user_profile_id}` e `{friend_profile_id}`. Também pode ser usado para cancelar uma solicitação enviada.
*   **Autenticação:** Requerida.
*   **Resposta de Sucesso (200 OK ou 204 No Content).**
*   **Respostas de Erro:** `401`, `403`, `404` (não são amigos ou solicitação não existe).

### `GET /api/v1/profiles/{profile_id}/friends`
*   **Descrição:** Lista os amigos do perfil especificado (`{profile_id}`).
*   **Autenticação:** Opcional (depende da privacidade da lista de amigos do perfil).
*   **Query Parameters:**
    *   `page` (integer, default 1)
    *   `per_page` (integer, default 20)
    *   `search_term` (string, para buscar no nome dos amigos)
    *   `preload` (string, ex: `\"profile_summary\"`)
*   **Resposta de Sucesso (200 OK):**

### `GET /api/v1/profiles/{user_profile_id}/friendships/requests/received`
*   **Descrição:** Lista as solicitações de amizade recebidas por `{user_profile_id}`.
*   **Autenticação:** Requerida.
*   **Query Parameters:** `page`, `per_page`.
*   **Resposta de Sucesso (200 OK):**

### `GET /api/v1/profiles/{user_profile_id}/friendships/requests/sent`
*   **Descrição:** Lista as solicitações de amizade enviadas por `{user_profile_id}`.
*   **Autenticação:** Requerida.
*   **Query Parameters:** `page`, `per_page`.
*   **Resposta de Sucesso (200 OK):**

---

## 2. Seguir/Assinaturas (`/api/v1/profiles/{user_profile_id}/subscriptions`)

### `POST /api/v1/profiles/{user_profile_id}/follow/{target_profile_id}`
*   **Descrição:** `{user_profile_id}` começa a seguir `{target_profile_id}`.
*   **Autenticação:** Requerida.
*   **Corpo da Requisição:** Vazio.
*   **Resposta de Sucesso (200 OK ou 201 Created):**

*   **Respostas de Erro:** `400`, `401`, `403` (ex: alvo bloqueou), `404`, `409 Conflict` (já está seguindo).

### `DELETE /api/v1/profiles/{user_profile_id}/unfollow/{target_profile_id}`
*   **Descrição:** `{user_profile_id}` deixa de seguir `{target_profile_id}`.
*   **Autenticação:** Requerida.
*   **Resposta de Sucesso (200 OK ou 204 No Content).**
*   **Respostas de Erro:** `401`, `403`, `404` (não estava seguindo).

### `GET /api/v1/profiles/{profile_id}/followers`
*   **Descrição:** Lista os perfis que seguem `{profile_id}` (seus fãs/seguidores).
*   **Autenticação:** Opcional.
*   **Query Parameters:** `page`, `per_page`, `search_term`, `preload`.
*   **Resposta de Sucesso (200 OK):**

### `GET /api/v1/profiles/{profile_id}/following`
*   **Descrição:** Lista os perfis que `{profile_id}` está seguindo.
*   **Autenticação:** Opcional (mas geralmente privado para o próprio usuário).
*   **Query Parameters:** `page`, `per_page`, `search_term`, `preload`.
*   **Resposta de Sucesso (200 OK):**

---

## 3. Bloqueios (`/api/v1/profiles/{user_profile_id}/bans`)

### `POST /api/v1/profiles/{user_profile_id}/block/{target_profile_id}`
*   **Descrição:** `{user_profile_id}` bloqueia `{target_profile_id}`.
*   **Autenticação:** Requerida.
*   **Corpo da Requisição:** Vazio.
*   **Resposta de Sucesso (200 OK ou 201 Created):**

*   **Respostas de Erro:** `400`, `401`, `403`, `404`, `409 Conflict` (já bloqueado).

### `DELETE /api/v1/profiles/{user_profile_id}/unblock/{target_profile_id}`
*   **Descrição:** `{user_profile_id}` desbloqueia `{target_profile_id}`.
*   **Autenticação:** Requerida.
*   **Resposta de Sucesso (200 OK ou 204 No Content).**
*   **Respostas de Erro:** `401`, `403`, `404` (não estava bloqueado).

### `GET /api/v1/profiles/{user_profile_id}/blocked`
*   **Descrição:** Lista os perfis que `{user_profile_id}` bloqueou.
*   **Autenticação:** Requerida (apenas o próprio usuário pode ver sua lista de bloqueados).
*   **Query Parameters:** `page`, `per_page`, `preload`.
*   **Resposta de Sucesso (200 OK):**

---

## 4. Status da Conexão (`/api/v1/profiles/{profile1_id}/connection-status/{profile2_id}`)

### `GET /api/v1/profiles/{profile1_id}/connection-status/{profile2_id}`
*   **Descrição:** Obtém o status de conexão entre `{profile1_id}` e `{profile2_id}` do ponto de vista de `{profile1_id}` (assumindo que `{profile1_id}` é o usuário autenticado ou a perspectiva desejada).
*   **Autenticação:** Requerida (para obter o status preciso, especialmente bloqueios).
*   **Resposta de Sucesso (200 OK):**