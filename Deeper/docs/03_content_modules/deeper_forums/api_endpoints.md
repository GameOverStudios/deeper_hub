# Documentação Deeper: Endpoints da API para Módulo de Fóruns

Este documento especifica os endpoints RESTful para o módulo de Fóruns (`deeper_forums`) do \"Deeper\".

Lembre-se das [Convenções de Design da API](../../00_core_concepts/api_design_conventions.md). Todos os endpoints abaixo estão sob o prefixo `/api/v1`.

## Categorias de Fóruns (`/forum-categories`)
(Opcional, se `deeper_forum_categories` for usado)

### 1. Criar Nova Categoria de Fórum
*   **`POST /forum-categories`**
*   **Autenticação:** Requerida (Admin).
*   **Corpo (JSON):** `{ \"title\": \"Discussões Gerais\", \"slug\": \"geral\", \"description\": \"...\", \"order_index\": 0 }`
*   **Resposta (201):** Objeto da categoria criada.

### 2. Listar Categorias de Fóruns
*   **`GET /forum-categories`**
*   **Autenticação:** Opcional.
*   **Query Params:** `sort_by` (ex: `order_index_asc`).
*   **Resposta (200):** Lista de categorias.

### 3. Obter Categoria de Fórum Específica
*   **`GET /forum-categories/{id_or_slug}`**
*   **Autenticação:** Opcional.
*   **Resposta (200):** Objeto da categoria.
*   **Erro:** `404`.

### 4. Atualizar Categoria de Fórum
*   **`PUT /forum-categories/{id}`** (ou `PATCH`)
*   **Autenticação:** Requerida (Admin).
*   **Corpo (JSON):** Campos a atualizar.
*   **Resposta (200):** Objeto da categoria atualizada.

### 5. Excluir Categoria de Fórum
*   **`DELETE /forum-categories/{id}`**
*   **Autenticação:** Requerida (Admin).
*   **Resposta (200 OK / 204 No Content):**

## Fóruns (`/forums`)

### 1. Criar Novo Fórum
*   **`POST /forums`**
*   **Autenticação:** Requerida (Admin ou usuário com permissão).
*   **Corpo (JSON):**

```json
    {
      \"title\": \"Desenvolvimento Elixir\",
      \"slug\": \"dev-elixir\", // Opcional
      \"description\": \"Discussões sobre desenvolvimento com Elixir e Phoenix.\",
      \"category_id\": 1, // Opcional
      \"order_index\": 10
      // Outros campos como permissões de visualização/postagem se não gerenciados por ACL global
    }
```

```json
    {
      \"title\": \"Como usar GenServer para background jobs?\",
      \"slug\": \"genserve-background-jobs\", // Opcional
      \"body_of_first_post\": \"Estou com dúvidas sobre a melhor forma de...\"
      // \"is_sticky\": false, // Opcional, admin/mod pode definir
      // \"is_locked\": false  // Opcional, admin/mod pode definir
    }
```

```json
    {
      \"body\": \"Minha resposta detalhada...\",
      \"parent_post_id\": null // ou ID de um post para citar/responder diretamente
    }
```

```json
    {
      \"data\": {
        \"1\": 12340, // topic_id: last_read_post_id
        \"3\": 56780
      }
    }
```

```json
    {
      \"target_type\": \"forum\", // ou \"topic\"
      \"target_id\": 10, // forum_id ou topic_id
      \"subscription_type\": \"instant\" // ou \"none\" para dessubscrever
    }
```

*   **Resposta (201):** Objeto do fórum criado.
*   **Erro:** `400`, `401`, `403`.

### 2. Listar Fóruns
*   **`GET /forums`**
*   **Autenticação:** Opcional (para ver fóruns com restrições de visibilidade).
*   **Query Params:**
    *   `category_id` / `category_slug`
    *   `sort_by` (ex: `order_index_asc`, `last_post_at_desc`, `title_asc`)
    *   `page`, `per_page`
    *   `include` (ex: `last_post_details`, `category_details`)
*   **Resposta (200):** Lista paginada de fóruns. Cada item pode incluir `topics_count`, `posts_count`, e detalhes do último post.
*   **Erro:** `400`.

### 3. Obter Fórum Específico
*   **`GET /forums/{id_or_slug}`**
*   **Autenticação:** Opcional (para fóruns restritos).
*   **Query Params:** `include` (ex: `category_details`, `last_post_details`, `permissions`).
*   **Resposta (200):** Objeto do fórum.
*   **Erro:** `401`, `403`, `404`.

### 4. Atualizar Fórum
*   **`PUT /forums/{id}`** (ou `PATCH`)
*   **Autenticação:** Requerida (Admin ou moderador do fórum com permissão).
*   **Corpo (JSON):** Campos a atualizar.
*   **Resposta (200):** Objeto do fórum atualizado.

### 5. Excluir Fórum
*   **`DELETE /forums/{id}`**
*   **Autenticação:** Requerida (Admin).
*   **Resposta (200 OK / 204 No Content):**

## Tópicos de Fórum (`/forums/{forum_id_or_slug}/topics`)

### 1. Criar Novo Tópico em um Fórum
*   **`POST /forums/{forum_id_or_slug}/topics`**
*   **Autenticação:** Requerida (usuário com permissão para postar no fórum). `profile_id` do autor do JWT.
*   **Corpo (JSON):**

*   **Resposta (201):** Objeto do tópico criado (incluindo o ID do primeiro post).
*   **Erro:** `400`, `401`, `403` (ex: fórum trancado, sem permissão), `404` (fórum não encontrado).

### 2. Listar Tópicos de um Fórum
*   **`GET /forums/{forum_id_or_slug}/topics`**
*   **Autenticação:** Opcional (depende da visibilidade do fórum).
*   **Query Params:**
    *   `q` (string): Buscar no título do tópico.
    *   `author_profile_id` (integer).
    *   `page`, `per_page`.
    *   `sort_by` (ex: `last_post_at_desc`, `created_at_desc`, `views_count_desc`, `replies_count_desc`, `title_asc`).
        *   A ordenação padrão deve ser `is_sticky DESC, last_post_at DESC`.
    *   `include` (ex: `author_profile`, `last_post_profile`, `first_post_excerpt`).
*   **Resposta (200):** Lista paginada de tópicos. Cada item inclui `replies_count`, `views_count`, detalhes do autor e do último post.
*   **Erro:** `400`, `404`.

## Tópicos de Fórum (Individual - `/topics/{topic_id}`)
(Alternativa ou complemento às rotas aninhadas. Pode ser útil para links diretos ou se a estrutura do fórum não for sempre o contexto primário.)

### 1. Obter Tópico Específico
*   **`GET /topics/{topic_id}`** (ou `/topics/{forum_slug}/{topic_slug}` se slugs forem globais ou únicos por fórum)
*   **Autenticação:** Opcional (depende da visibilidade do fórum/tópico).
*   **Query Params:** `include` (ex: `forum_details`, `author_profile`, `first_post_body`, `last_post_details`).
*   **Resposta (200):** Objeto do tópico com detalhes.
*   **Erro:** `401`, `403`, `404`.

### 2. Atualizar Tópico (Título, Sticky, Lock)
*   **`PUT /topics/{topic_id}`** (ou `PATCH`)
*   **Autenticação:** Requerida (Autor do tópico para título, Admin/Mod para sticky/lock).
*   **Corpo (JSON):** `{ \"title\": \"...\", \"is_sticky\": true, \"is_locked\": false }`
*   **Resposta (200):** Objeto do tópico atualizado.

### 3. Excluir Tópico
*   **`DELETE /topics/{topic_id}`**
*   **Autenticação:** Requerida (Autor do tópico ou Admin/Mod).
*   **Resposta (200 OK / 204 No Content):**

### 4. Registrar Visualização de Tópico
*   **`POST /topics/{topic_id}/view`**
*   **Autenticação:** Opcional.
*   **Corpo (JSON):** Vazio.
*   **Resposta (200 OK / 204 No Content):**
*   **Ação:** Incrementa `views_count` no tópico.

## Posts/Respostas em Tópicos (`/topics/{topic_id}/posts`)

### 1. Criar Novo Post/Resposta em um Tópico
*   **`POST /topics/{topic_id}/posts`**
*   **Autenticação:** Requerida (usuário com permissão para responder no tópico). `profile_id` do autor do JWT.
*   **Corpo (JSON):**

*   **Resposta (201):** Objeto do post criado. O backend deve atualizar `replies_count` e `last_post_*` no tópico e no fórum.
*   **Erro:** `400`, `401`, `403` (ex: tópico trancado), `404` (tópico não encontrado).

### 2. Listar Posts de um Tópico
*   **`GET /topics/{topic_id}/posts`**
*   **Autenticação:** Opcional (depende da visibilidade do fórum/tópico).
*   **Query Params:**
    *   `page`, `per_page`.
    *   `sort_by` (geralmente `created_at_asc`).
    *   `include` (ex: `author_profile`).
    *   `after_post_id` (integer): Para carregar posts mais recentes que um certo ID (para \"carregar novas respostas\").
*   **Resposta (200):** Lista paginada de posts. O primeiro post do tópico (`first_post_id`) pode ser excluído desta lista se já for exibido separadamente com os detalhes do tópico.
*   **Erro:** `404`.

## Posts Individuais (`/posts/{post_id}`)
(Para editar/deletar posts específicos)

### 1. Obter Post Específico
*   **`GET /posts/{post_id}`**
*   **Autenticação:** Opcional.
*   **Query Params:** `include` (ex: `author_profile`, `topic_details`).
*   **Resposta (200):** Objeto do post.
*   **Erro:** `404`.

### 2. Atualizar Post
*   **`PUT /posts/{post_id}`** (ou `PATCH`)
*   **Autenticação:** Requerida (Autor do post ou Admin/Mod).
*   **Corpo (JSON):** `{ \"body\": \"Conteúdo editado...\" }`
*   **Resposta (200):** Objeto do post atualizado. O backend deve atualizar `edited_at`, `edited_by_profile_id`.

### 3. Excluir Post
*   **`DELETE /posts/{post_id}`**
*   **Autenticação:** Requerida (Autor do post ou Admin/Mod).
*   **Resposta (200 OK / 204 No Content):** O backend deve recalcular contagens no tópico e fórum.

## Tópicos Lidos e Subscrições

### 1. Marcar Tópico como Lido
*   **`POST /topics/{topic_id}/read`**
*   **Autenticação:** Requerida.
*   **Corpo (JSON):** `{ \"last_read_post_id\": 12345 }`
*   **Resposta (200 OK / 204 No Content):**

### 2. Obter Status de Leitura de Tópicos (para o usuário logado)
*   **`GET /me/forum-read-statuses?topic_ids=1,2,3`**
*   **Autenticação:** Requerida.
*   **Resposta (200):**

### 3. Subscrever/Dessubscrever de Fórum ou Tópico
*   **`POST /subscriptions/forum`**
*   **Autenticação:** Requerida.
*   **Corpo (JSON):**

*   **Resposta (200 OK / 201 Created):** Detalhes da subscrição.

### 4. Listar Minhas Subscrições de Fórum
*   **`GET /me/forum-subscriptions`**
*   **Autenticação:** Requerida.
*   **Query Params:** `target_type` (`forum` ou `topic`).
*   **Resposta (200):** Lista de subscrições.

Esta é uma API abrangente para um módulo de fóruns. Muitas otimizações e lógicas de permissão detalhadas seriam implementadas nos controllers e na camada de contexto/serviço.