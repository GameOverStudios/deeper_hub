# Documentação Deeper: Endpoints da API para Organizações (`bx_organizations`)

Este documento especifica os endpoints RESTful da API \"Deeper\" para interagir com as funcionalidades do módulo Organizações (`bx_organizations`).

**Autenticação:** A maioria dos endpoints, especialmente os de escrita (POST, PUT, DELETE), exigirá autenticação via JWT (Bearer Token). Endpoints de listagem e visualização podem ser públicos ou ter acesso restrito.

**Formato de Resposta:** JSON.

---

## 1. Organizações (`/api/v1/organizations`)

### `POST /api/v1/organizations`
*   **Descrição:** Cria um novo perfil de organização. O `author_id` da organização será o `profile_id` do usuário autenticado.
*   **Autenticação:** Requerida.
*   **Corpo da Requisição (JSON):**

```json
    {
      \"org_name\": \"My New Company Inc.\", // Obrigatório
      \"org_uri\": \"my-new-company-inc\", // Obrigatório, slug único
      \"org_cat\": 1, // Opcional, ID da categoria (se categorias de organização existirem)
      \"org_desc\": \"A description of My New Company Inc.\", // Opcional
      \"org_website\": \"https://mynewcompany.com\", // Opcional
      \"org_email\": \"contact@mynewcompany.com\", // Opcional
      \"org_phone\": \"123-456-7890\", // Opcional
      \"org_address_street\": \"123 Main St\", // Opcional
      // ... outros campos de bx_organizations_data como org_logo (ID de arquivo), org_cover (ID de arquivo)
      \"status\": \"active\" // Opcional, default 'active' ou 'pending'
    }
```

```json
    {
      \"data\": {
        \"id\": 201, // ID de bx_organizations_data.id
        \"author_id\": 15, // profile_id do criador
        \"org_name\": \"My New Company Inc.\",
        \"org_uri\": \"my-new-company-inc\",
        \"status\": \"active\",
        \"added\": 1678892400, // Unix Timestamp
        \"profile_id\": 75 // ID do novo perfil criado em sys_profiles
        // ... outros campos da organização
      }
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 201,
          \"org_name\": \"My New Company Inc.\",
          \"org_uri\": \"my-new-company-inc\",
          \"org_desc_snippet\": \"A description of...\", // Snippet da descrição
          \"logo_url\": \"...\", // URL do logo (se preload incluir logo)
          \"category\": { \"id\": 1, \"title\": \"Technology\" }, // Se preload incluir categoria
          \"fans_count\": 150
          // ... outros campos relevantes
        }
        // ... mais organizações
      ],
      \"pagination\": {
        \"total_items\": 73,
        \"total_pages\": 4,
        \"current_page\": 1,
        \"per_page\": 20
      }
    }
```

```json
    {
      \"data\": {
        \"id\": 201,
        \"author_id\": 15,
        \"org_name\": \"My New Company Inc.\",
        \"org_uri\": \"my-new-company-inc\",
        \"org_desc\": \"A description of My New Company Inc. providing excellent services.\",
        \"org_website\": \"https://mynewcompany.com\",
        \"org_email\": \"contact@mynewcompany.com\",
        \"logo_url\": \"...\",
        \"cover_url\": \"...\",
        \"status\": \"active\",
        \"views\": 540,
        \"fans_count\": 150,
        \"added\": 1678892400,
        \"category\": { // Se preload
          \"id\": 1,
          \"title\": \"Technology\",
          \"uri\": \"technology\"
        },
        \"author_profile\": { // Se preload - perfil do criador
          \"profile_id\": 15,
          \"display_name\": \"Jane Founder\",
          \"avatar_url\": \"...\"
        },
        \"members_summary\": { // Se preload - resumo dos membros
            \"count\": 5,
            \"endpoint\": \"/api/v1/organizations/201/members\"
        }
        // ... todos os campos de bx_organizations_data
      }
    }
```

```json
    {
      \"profile_id\": 55, // ID do perfil (sys_profiles.id) a ser adicionado/atualizado
      \"role\": \"editor\" // \"admin\", \"editor\", \"member\"
    }
```

```json
    {
      \"data\": {
        \"id\": 12, // ID da entrada em bx_organizations_members
        \"org_id\": 201,
        \"profile_id\": 55,
        \"role\": \"editor\",
        \"added\": 1678895000
      }
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 12, \"org_id\": 201, \"profile_id\": 55, \"role\": \"editor\", \"added\": 1678895000,
          \"profile_summary\": { \"profile_id\": 55, \"display_name\": \"Member One\", \"avatar_url\": \"...\" }
        }
        // ... mais membros
      ],
      \"pagination\": { ... }
    }
```

```json
    {
      \"role\": \"admin\"
    }
```

*   **Resposta de Sucesso (201 Created):**

*   **Respostas de Erro:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `422 Unprocessable Entity`.

### `GET /api/v1/organizations`
*   **Descrição:** Lista perfis de organização com filtros, ordenação e paginação.
*   **Autenticação:** Opcional (organizações ativas podem ser públicas).
*   **Query Parameters:**
    *   `author_id` (integer): ID do perfil do criador.
    *   `org_cat` (integer): ID da categoria da organização.
    *   `status` (string, ex: `\"active\"`).
    *   `search_term` (string, para buscar em `org_name` e `org_desc`).
    *   `featured_only` (boolean, `true`).
    *   `page` (integer, default 1).
    *   `per_page` (integer, default 20).
    *   `sort_by` (string, ex: `\"org_name_asc\"`, `\"added_desc\"`, `\"fans_count_desc\"`).
    *   `preload` (string, comma-separated, ex: `\"category,author_summary,logo,cover\"`).
*   **Resposta de Sucesso (200 OK):**

### `GET /api/v1/organizations/{id_or_uri}`
*   **Descrição:** Obtém detalhes de um perfil de organização específico pelo seu ID (`bx_organizations_data.id`) ou `org_uri`.
*   **Autenticação:** Opcional.
*   **Query Parameters:**
    *   `preload` (string, comma-separated, ex: `\"category,author_profile,members,logo,cover,comments_summary\"`).
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:** `404 Not Found`.

### `PUT /api/v1/organizations/{id}`
*   **Descrição:** Atualiza um perfil de organização existente. O usuário deve ser o autor/admin da organização ou um admin/moderador do sistema.
*   **Autenticação:** Requerida.
*   **Corpo da Requisição (JSON):** Campos a serem atualizados.
*   **Resposta de Sucesso (200 OK):** Corpo da organização atualizada.
*   **Respostas de Erro:** `400`, `401`, `403`, `404`, `422`.

### `DELETE /api/v1/organizations/{id}`
*   **Descrição:** Deleta um perfil de organização. O usuário deve ser o autor/admin da organização ou um admin/moderador do sistema.
*   **Autenticação:** Requerida.
*   **Resposta de Sucesso (204 No Content ou 200 OK com mensagem).**
*   **Respostas de Erro:** `401`, `403`, `404`.

### `POST /api/v1/organizations/{id}/view`
*   **Descrição:** Registra uma visualização para o perfil da organização.
*   **Autenticação:** Opcional.
*   **Corpo da Requisição:** Vazio.
*   **Resposta de Sucesso (200 OK ou 204 No Content).**
*   **Respostas de Erro:** `404`.

---

## 2. Categorias de Organizações (Se Implementado) (`/api/v1/organization-categories`)

*Se a tabela `bx_organizations_categories` for implementada, os endpoints seriam muito similares aos de `market/categories`:*

### `POST /api/v1/organization-categories`
### `GET /api/v1/organization-categories`
### `GET /api/v1/organization-categories/{id_or_uri}`
### `PUT /api/v1/organization-categories/{id}`
### `DELETE /api/v1/organization-categories/{id}`

*   **Responsabilidades e Formatos:** Análogos aos endpoints de categorias do marketplace.

---

## 3. Membros de Organizações (Se Implementado) (`/api/v1/organizations/{org_id}/members`)

*Se a tabela `bx_organizations_members` for implementada:*

### `POST /api/v1/organizations/{org_id}/members`
*   **Descrição:** Adiciona um perfil como membro (ou atualiza seu papel) a uma organização. Requer permissão de admin da organização.
*   **Autenticação:** Requerida.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (201 Created ou 200 OK):** Detalhes da associação do membro.

*   **Respostas de Erro:** `400`, `401`, `403`, `404` (para `org_id` ou `profile_id`), `422`.

### `GET /api/v1/organizations/{org_id}/members`
*   **Descrição:** Lista os membros de uma organização.
*   **Autenticação:** Opcional (dependendo da privacidade da lista de membros).
*   **Query Parameters:**
    *   `role` (string): Filtra por papel.
    *   `page`, `per_page`, `sort_by`.
    *   `preload` (string, ex: `\"profile_summary\"`)
*   **Resposta de Sucesso (200 OK):**

### `PUT /api/v1/organizations/{org_id}/members/{profile_id}`
*   **Descrição:** Atualiza o papel de um membro existente em uma organização. Requer permissão de admin da organização.
*   **Autenticação:** Requerida.
*   **Corpo da Requisição (JSON):**