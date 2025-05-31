# Documentação Deeper: Endpoints da API para Marketplace (`bx_market`)

Este documento especifica os endpoints RESTful da API \"Deeper\" para interagir com as funcionalidades do módulo Marketplace (`bx_market`).

**Autenticação:** A maioria dos endpoints, especialmente os de escrita (POST, PUT, DELETE), exigirá autenticação via JWT (Bearer Token). Endpoints de listagem e visualização podem ser públicos ou ter acesso restrito com base nas configurações de privacidade/ACL.

**Formato de Resposta:** JSON.

---

## 1. Categorias de Marketplace (`/api/v1/market/categories`)

### `POST /api/v1/market/categories`
*   **Descrição:** Cria uma nova categoria de marketplace.
*   **Autenticação:** Requerida (nível de admin/moderador).
*   **Corpo da Requisição (JSON):**

```json
    {
      \"name\": \"electronics-slug\", // Obrigatório, único
      \"title\": \"Electronics\", // Obrigatório
      \"uri\": \"electronics\", // Obrigatório, único
      \"parent_id\": 0, // Opcional, default 0
      \"icon\": \"fas fa-tv\", // Opcional
      \"order_index\": 10, // Opcional
      \"active\": true, // Opcional, default true
      \"meta_description\": \"Find the best electronics.\", // Opcional
      \"meta_keywords\": \"electronics, tv, audio\" // Opcional
    }
```

```json
    {
      \"data\": {
        \"id\": 1,
        \"parent_id\": 0,
        \"name\": \"electronics-slug\",
        \"title\": \"Electronics\",
        \"uri\": \"electronics\",
        \"icon\": \"fas fa-tv\",
        \"order_index\": 10,
        \"active\": true,
        // ...outros campos...
      }
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"parent_id\": 0,
          \"name\": \"electronics-slug\",
          \"title\": \"Electronics\",
          \"uri\": \"electronics\",
          // ...
        },
        // ... mais categorias
      ],
      \"pagination\": { // Se a paginação for implementada para categorias
        \"total_items\": 15,
        \"total_pages\": 1,
        \"current_page\": 1,
        \"per_page\": 15
      }
    }
```

```json
    {
      \"data\": {
        \"id\": 1,
        \"parent_id\": 0,
        \"name\": \"electronics-slug\",
        \"title\": \"Electronics\",
        // ...
        \"subcategories\": [ // Opcional, se pré-carregado
            // ...
        ]
      }
    }
```

```json
    {
      \"author_id\": 123, // Geralmente obtido do JWT do usuário logado
      \"category_id\": 1, // Obrigatório
      \"title\": \"Amazing Used Laptop\", // Obrigatório
      \"name\": \"amazing-used-laptop-xyz\", // Obrigatório, slug único
      \"description\": \"A great laptop, slightly used.\", // Obrigatório
      \"tags\": \"laptop, electronics, used\", // String ou array
      \"price\": 499.99, // Obrigatório
      \"currency_code\": \"USD\", // Obrigatório
      \"price_negotiable\": false, // Opcional, default false
      \"location_text\": \"New York, NY\", // Opcional
      \"quantity\": 1, // Opcional, default 1
      \"condition\": \"used_good\", // Opcional
      \"status\": \"pending\" // Opcional, default 'pending' ou 'active' dependendo da política
      // ... outros campos de bx_market_entries
    }
```

```json
    {
      \"data\": {
        \"id\": 101,
        \"author_id\": 123,
        \"category_id\": 1,
        \"title\": \"Amazing Used Laptop\",
        \"name\": \"amazing-used-laptop-xyz\",
        \"status\": \"pending\",
        \"price\": 499.99,
        \"currency_code\": \"USD\",
        \"added\": 1678886400, // Unix Timestamp
        // ... outros campos
      }
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 101,
          \"title\": \"Amazing Used Laptop\",
          \"name\": \"amazing-used-laptop-xyz\",
          \"price\": 499.99,
          \"currency_code\": \"USD\",
          \"main_photo_url\": \"...\", // URL da foto principal (se `preload` incluir fotos)
          \"category\": { \"id\": 1, \"title\": \"Electronics\", \"uri\": \"electronics\" }, // Se `preload` incluir categoria
          \"author_summary\": { \"id\": 123, \"display_name\": \"John Doe\", \"avatar_url\": \"...\" }, // Se `preload` incluir autor
          // ... outros campos relevantes da listagem
        }
        // ... mais listagens
      ],
      \"pagination\": {
        \"total_items\": 55,
        \"total_pages\": 3,
        \"current_page\": 1,
        \"per_page\": 20
      }
    }
```

```json
    {
      \"data\": {
        \"id\": 101,
        \"author_id\": 123,
        \"category_id\": 1,
        \"title\": \"Amazing Used Laptop\",
        \"name\": \"amazing-used-laptop-xyz\",
        \"description\": \"A great laptop, slightly used. Comes with charger and original box.\",
        \"tags\": \"laptop, electronics, used\",
        \"price\": 499.99,
        \"currency_code\": \"USD\",
        \"price_negotiable\": false,
        \"location_text\": \"New York, NY\",
        \"quantity\": 1,
        \"condition\": \"used_good\",
        \"status\": \"active\",
        \"views\": 150,
        \"favorites\": 12,
        \"comments_count\": 3,
        \"score\": 4.5,
        \"added\": 1678886400,
        \"changed\": 1678890000,
        \"category\": {
          \"id\": 1,
          \"title\": \"Electronics\",
          \"uri\": \"electronics\"
        },
        \"author_profile\": { // Detalhes do perfil do autor
          \"profile_id\": 789, // sys_profiles.id
          \"account_id\": 123,
          \"type\": \"bx_persons\",
          \"display_name\": \"John Doe\", // bx_persons_data.fullname
          \"avatar_url\": \"...\",
          // ... outros detalhes do perfil do autor
        },
        \"photos\": [
          { \"id\": 1, \"file_id\": 5001, \"file_url\": \"...\", \"title\": \"Laptop Front\", \"is_main\": true },
          { \"id\": 2, \"file_id\": 5002, \"file_url\": \"...\", \"title\": \"Laptop Keyboard\", \"is_main\": false }
        ],
        \"comments\": { // Se `preload` incluir comentários, pode ser um link para o endpoint de comentários ou os primeiros N comentários
            \"endpoint\": \"/api/v1/market/entries/101/comments\",
            \"count\": 3
        }
        // ... todos os campos de bx_market_entries
      }
    }
```

```json
    {
      \"file_id\": 5003, // ID do arquivo já existente no sistema
      \"title\": \"Laptop with accessories\", // Opcional
      \"is_main\": false, // Opcional, default false
      \"order_index\": 2 // Opcional
    }
```

```json
    {
      \"data\": {
        \"id\": 3, // ID da entrada em bx_market_photos
        \"entry_id\": 101,
        \"file_id\": 5003,
        \"title\": \"Laptop with accessories\",
        \"is_main\": false,
        \"order_index\": 2,
        \"file_url\": \"...\" // URL do arquivo
      }
    }
```

```json
    {
      \"data\": [
        { \"id\": 1, \"entry_id\": 101, \"file_id\": 5001, \"file_url\": \"...\", \"title\": \"Laptop Front\", \"is_main\": true, \"order_index\": 0 },
        { \"id\": 2, \"entry_id\": 101, \"file_id\": 5002, \"file_url\": \"...\", \"title\": \"Laptop Keyboard\", \"is_main\": false, \"order_index\": 1 }
      ]
    }
```

```json
    {
      \"title\": \"Updated Laptop Front View\",
      \"is_main\": true,
      \"order_index\": 0
    }
```

*   **Resposta de Sucesso (201 Created):**

*   **Respostas de Erro:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `422 Unprocessable Entity`.

### `GET /api/v1/market/categories`
*   **Descrição:** Lista todas as categorias de marketplace. Suporta filtragem.
*   **Autenticação:** Opcional (categorias ativas podem ser públicas).
*   **Query Parameters:**
    *   `parent_id` (integer): Filtra por ID da categoria pai (para listar subcategorias).
    *   `active` (boolean, `true` ou `false`): Filtra por status de ativação.
    *   `sort_by` (string, ex: `\"order_index_asc\"`, `\"title_asc\"`).
*   **Resposta de Sucesso (200 OK):**

### `GET /api/v1/market/categories/{id_or_uri}`
*   **Descrição:** Obtém detalhes de uma categoria específica pelo seu ID ou URI.
*   **Autenticação:** Opcional.
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:** `404 Not Found`.

### `PUT /api/v1/market/categories/{id}`
*   **Descrição:** Atualiza uma categoria existente.
*   **Autenticação:** Requerida (nível de admin/moderador).
*   **Corpo da Requisição (JSON):** Campos a serem atualizados (similar ao POST).
*   **Resposta de Sucesso (200 OK):** Corpo da categoria atualizada.
*   **Respostas de Erro:** `400`, `401`, `403`, `404`, `422`.

### `DELETE /api/v1/market/categories/{id}`
*   **Descrição:** Deleta uma categoria. (Pode falhar se houver produtos associados e a FK tiver `ON DELETE RESTRICT`).
*   **Autenticação:** Requerida (nível de admin/moderador).
*   **Resposta de Sucesso (204 No Content ou 200 OK com mensagem).**
*   **Respostas de Erro:** `401`, `403`, `404`, `409 Conflict` (se não puder ser deletada).

---

## 2. Listagens de Marketplace (`/api/v1/market/entries`)

### `POST /api/v1/market/entries`
*   **Descrição:** Cria uma nova listagem de produto/serviço.
*   **Autenticação:** Requerida.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (201 Created):**

*   **Respostas de Erro:** `400`, `401`, `403`, `422`.

### `GET /api/v1/market/entries`
*   **Descrição:** Lista os produtos/serviços do marketplace com filtros, ordenação e paginação.
*   **Autenticação:** Opcional (listagens ativas podem ser públicas).
*   **Query Parameters:**
    *   `author_id` (integer)
    *   `category_id` (integer)
    *   `category_uri` (string)
    *   `status` (string, ex: `\"active\"`)
    *   `min_price` (float)
    *   `max_price` (float)
    *   `currency_code` (string)
    *   `condition` (string, ex: `\"new\"`)
    *   `location_text_like` (string, para busca parcial em localização)
    *   `search_term` (string, para buscar em `title` e `description`)
    *   `tags` (string, tags separadas por vírgula, para filtro \"contém qualquer uma\" ou \"contém todas\")
    *   `featured_only` (boolean, `true`)
    *   `page` (integer, default 1)
    *   `per_page` (integer, default 20)
    *   `sort_by` (string, ex: `\"price_asc\"`, `\"added_desc\"`, `\"views_desc\"`, `\"score_desc\"`)
    *   `preload` (string, comma-separated, ex: `\"photos,category,author_summary\"`)
*   **Resposta de Sucesso (200 OK):**

### `GET /api/v1/market/entries/{id_or_name}`
*   **Descrição:** Obtém detalhes de uma listagem específica pelo seu ID ou `name` (slug).
*   **Autenticação:** Opcional.
*   **Query Parameters:**
    *   `preload` (string, comma-separated, ex: `\"photos,category,author_profile,comments\"`)
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:** `404 Not Found`.

### `PUT /api/v1/market/entries/{id}`
*   **Descrição:** Atualiza uma listagem existente. O usuário deve ser o autor ou um admin/moderador.
*   **Autenticação:** Requerida.
*   **Corpo da Requisição (JSON):** Campos a serem atualizados.
*   **Resposta de Sucesso (200 OK):** Corpo da listagem atualizada.
*   **Respostas de Erro:** `400`, `401`, `403`, `404`, `422`.

### `DELETE /api/v1/market/entries/{id}`
*   **Descrição:** Deleta uma listagem. O usuário deve ser o autor ou um admin/moderador.
*   **Autenticação:** Requerida.
*   **Resposta de Sucesso (204 No Content ou 200 OK com mensagem).**
*   **Respostas de Erro:** `401`, `403`, `404`.

### `POST /api/v1/market/entries/{id}/view`
*   **Descrição:** Registra uma visualização para a listagem.
*   **Autenticação:** Opcional (mas pode ser rastreado por IP ou ID de usuário se autenticado).
*   **Corpo da Requisição:** Vazio.
*   **Resposta de Sucesso (200 OK ou 204 No Content).**
*   **Respostas de Erro:** `404`.

---

## 3. Fotos de Listagens (`/api/v1/market/entries/{entry_id}/photos`)

### `POST /api/v1/market/entries/{entry_id}/photos`
*   **Descrição:** Adiciona uma nova foto a uma listagem. Requer o `file_id` de um arquivo previamente enviado via API de Gerenciamento de Arquivos (`06_file_management`).
*   **Autenticação:** Requerida (autor da listagem ou admin).
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (201 Created):** Detalhes da associação da foto.

*   **Respostas de Erro:** `400`, `401`, `403`, `404` (para `entry_id` ou `file_id`), `422`.

### `GET /api/v1/market/entries/{entry_id}/photos`
*   **Descrição:** Lista todas as fotos associadas a uma listagem.
*   **Autenticação:** Opcional.
*   **Resposta de Sucesso (200 OK):**

### `PUT /api/v1/market/entries/{entry_id}/photos/{photo_id}`
*   **Descrição:** Atualiza os detalhes de uma foto de uma listagem (ex: título, `is_main`, `order_index`).
*   **Autenticação:** Requerida (autor da listagem ou admin).
*   **Corpo da Requisição (JSON):**