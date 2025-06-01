# API de Administração: Gerenciamento de Fóruns (`deeper_forums`)

Endpoints da API para administradores e moderadores globais gerenciarem a estrutura e o conteúdo do módulo `deeper_forums`, incluindo categorias de fóruns, fóruns, tópicos e posts.

**Permissões:** Todos os endpoints aqui requerem um papel de administrador do site ou um super-moderador com permissões para gerenciar todo o sistema de fóruns.

## Endpoints para Categorias de Fóruns (`deeper_forum_categories`)
(Se esta funcionalidade estiver implementada)

### 1. Listar Todas as Categorias de Fóruns
*   **`GET /admin/forum-categories`**
*   **Autenticação:** Admin Requerida.
*   **Resposta (200 OK):** Lista de todas as categorias de fóruns.

### 2. Criar Nova Categoria de Fórum
*   **`POST /admin/forum-categories`**
*   **Autenticação:** Admin Requerida.
*   **Corpo (JSON):** `{ \"title\": \"...\", \"slug\": \"...\", \"description\": \"...\", \"order_index\": 0 }`
*   **Resposta (201 Created):** Objeto da categoria criada.

### 3. Atualizar Categoria de Fórum
*   **`PUT /admin/forum-categories/{category_id}`** (ou `PATCH`)
*   **Autenticação:** Admin Requerida.
*   **Corpo (JSON):** Campos a atualizar.
*   **Resposta (200 OK):** Objeto da categoria atualizada.

### 4. Excluir Categoria de Fórum
*   **`DELETE /admin/forum-categories/{category_id}`**
*   **Autenticação:** Admin Requerida.
*   **Ação do Backend:** Remove a categoria. Considerar o que acontece com fóruns dentro dela (`ON DELETE SET NULL` ou proibir exclusão se contiver fóruns).
*   **Resposta (200 OK / 204 No Content):**

## Endpoints para Fóruns (`deeper_forums`)

### 1. Listar Todos os Fóruns (Visão Administrativa)

*   **`GET /admin/forums`**
*   **Autenticação:** Admin Requerida.
*   **Query Parameters:** `category_id`, `q` (buscar por título/descrição), `page`, `per_page`, `sort_by` (ex: `order_index_asc`, `title_asc`, `last_post_at_desc`). `include=category_details,last_post_summary`.
*   **Resposta de Sucesso (200 OK):** Lista paginada de todos os fóruns.

### 2. Obter Detalhes de Qualquer Fórum (Visão Administrativa)

*   **`GET /admin/forums/{id_or_slug}`**
*   **Autenticação:** Admin Requerida.
*   **Query Parameters:** `include=category_details,last_post_full_details,moderation_logs`.
*   **Resposta de Sucesso (200 OK):** Objeto completo do fórum.

### 3. Atualizar Qualquer Fórum (Ação Administrativa)

*   **`PUT /admin/forums/{id}`** (ou `PATCH`)
*   **Autenticação:** Admin Requerida.
*   **Corpo da Requisição (JSON):** Campos a serem atualizados (ex: `title`, `description`, `category_id`, `order_index`, permissões de acesso/postagem se gerenciadas no fórum).
*   **Resposta de Sucesso (200 OK):** Objeto do fórum atualizado.
*   **Ação do Backend:** Atualiza o fórum. Se `category_id` mudar, pode ser necessário reordenar.

### 4. Excluir Qualquer Fórum (Ação Administrativa)

*   **`DELETE /admin/forums/{id}`**
*   **Autenticação:** Admin Requerida.
*   **Ação do Backend:** Deleta o fórum e, devido ao `ON DELETE CASCADE`, seus tópicos e posts. Ação destrutiva.
*   **Resposta de Sucesso (200 OK ou 204 No Content):**

## Endpoints para Tópicos de Fórum (Visão Administrativa)

### 1. Listar Todos os Tópicos de um Fórum (Admin) ou Todos os Tópicos do Sistema (Admin)

*   **`GET /admin/forums/{forum_id_or_slug}/topics`**: Lista tópicos de um fórum específico.
*   **`GET /admin/topics`**: Lista todos os tópicos de todos os fóruns (mais útil para moderação global).
*   **Autenticação:** Admin Requerida.
*   **Query Parameters:**
    *   Para `/admin/topics`: `forum_id` (opcional, para filtrar).
    *   `profile_id` (autor do tópico).
    *   `status` (`active`, `hidden_by_moderator`, `deleted_by_user`).
    *   `is_sticky` (boolean).
    *   `is_locked` (boolean).
    *   `q` (buscar por título).
    *   `page`, `per_page`, `sort_by` (ex: `last_post_at_desc`, `created_at_desc`).
    *   `include=author_profile,forum_details,last_post_profile`.
*   **Resposta de Sucesso (200 OK):** Lista paginada de tópicos.

### 2. Obter Detalhes de Qualquer Tópico (Admin)

*   **`GET /admin/topics/{topic_id}`**
*   **Autenticação:** Admin Requerida.
*   **Query Parameters:** `include=author_profile,forum_details,first_post_body,all_posts_summary`.
*   **Resposta de Sucesso (200 OK):** Objeto completo do tópico.

### 3. Atualizar Qualquer Tópico (Ação Administrativa)

*   **`PUT /admin/topics/{topic_id}`** (ou `PATCH`)
*   **Autenticação:** Admin Requerida.
*   **Corpo da Requisição (JSON):**

```json
    {
      \"title\": \"Título do Tópico Editado por Admin\",
      \"forum_id\": 2, // Mover tópico para outro fórum (ação complexa, recalcular contagens)
      \"is_sticky\": true,
      \"is_locked\": true,
      \"status\": \"active\", // ou \"hidden_by_moderator\"
      \"admin_notes\": \"Tópico fixado e trancado por relevância.\"
    }
```

```json
    {
      \"body\": \"Conteúdo do post editado por admin devido a violação de termos.\",
      \"status\": \"hidden_by_moderator\", // ou \"active\"
      // \"profile_id\": 100 // Reatribuir autoria do post (ação poderosa)
      \"admin_notes\": \"Editado por conter linguagem inadequada.\"
    }
```

*   **Ação do Backend:** Atualiza o tópico. Se `forum_id` mudar, as contagens dos fóruns antigo e novo devem ser recalculadas (`update_forum_stats`).
*   **Resposta de Sucesso (200 OK):** Objeto do tópico atualizado.

### 4. Excluir Qualquer Tópico (Ação Administrativa)

*   **`DELETE /admin/topics/{topic_id}`**
*   **Autenticação:** Admin Requerida.
*   **Ação do Backend:** Deleta o tópico e seus posts (`ON DELETE CASCADE`). Recalcula estatísticas do fórum pai.
*   **Resposta de Sucesso (200 OK ou 204 No Content):**

## Endpoints para Posts de Fórum (Visão Administrativa)

### 1. Listar Todos os Posts de um Tópico (Admin) ou Todos os Posts do Sistema (Admin)

*   **`GET /admin/topics/{topic_id}/posts`**: Lista posts de um tópico específico.
*   **`GET /admin/posts`**: Lista todos os posts de todos os tópicos (útil para moderação global de conteúdo).
*   **Autenticação:** Admin Requerida.
*   **Query Parameters:**
    *   Para `/admin/posts`: `topic_id`, `forum_id` (opcional, para filtrar).
    *   `profile_id` (autor do post).
    *   `status` (`active`, `hidden_by_moderator`, `deleted_by_user`).
    *   `q` (buscar no corpo do post).
    *   `page`, `per_page`, `sort_by` (ex: `created_at_desc`).
    *   `include=author_profile,topic_details,forum_details`.
*   **Resposta de Sucesso (200 OK):** Lista paginada de posts.

### 2. Obter Detalhes de Qualquer Post (Admin)

*   **`GET /admin/posts/{post_id}`**
*   **Autenticação:** Admin Requerida.
*   **Query Parameters:** `include=author_profile,topic_details`.
*   **Resposta de Sucesso (200 OK):** Objeto completo do post.

### 3. Atualizar Qualquer Post (Ação Administrativa)

*   **`PUT /admin/posts/{post_id}`** (ou `PATCH`)
*   **Autenticação:** Admin Requerida.
*   **Corpo da Requisição (JSON):**

*   **Ação do Backend:** Atualiza o post. Se o status mudar ou o post for editado, pode ser necessário atualizar `updated_at` e `last_post_*` no tópico e fórum pai.
*   **Resposta de Sucesso (200 OK):** Objeto do post atualizado.

### 4. Excluir Qualquer Post (Ação Administrativa)

*   **`DELETE /admin/posts/{post_id}`**
*   **Autenticação:** Admin Requerida.
*   **Ação do Backend:** Deleta o post. Recalcula `replies_count` e `last_post_*` no tópico pai, e subsequentemente no fórum pai. Se for o `first_post_id` de um tópico, o tópico pode precisar ser excluído ou tratado de forma especial.
*   **Resposta de Sucesso (200 OK ou 204 No Content):**

## Considerações para Repositórios e Contextos:

*   **`Deeper.Content.ForumsRepo`:**
    *   Todas as funções de listagem e obtenção precisarão de variantes ou flags `as_admin: true` para ignorar restrições de visibilidade ou status padrão.
    *   Funções CRUD para todas as entidades (categorias, fóruns, tópicos, posts) precisarão permitir operações por administradores em qualquer item.
    *   A lógica de atualização de contadores denormalizados (`topics_count`, `posts_count` em fóruns; `replies_count` em tópicos) e dos campos `last_post_*` é crítica e deve ser acionada corretamente após qualquer modificação feita por um admin. Mover um tópico para outro fórum é uma operação particularmente complexa para os contadores.
*   **`Deeper.Content.Forums` (Contexto/Serviço):**
    *   Verificará as permissões de administrador do `current_user_profile`.
    *   Orquestrará operações complexas, como mover um tópico (que envolve atualizar contadores em dois fóruns e potencialmente o `forum_id` no tópico e seus posts).
    *   Lidará com a lógica de \"soft delete\" vs. \"hard delete\" se implementada.
*   **Log de Auditoria:** Todas as ações administrativas (editar/excluir fóruns, tópicos, posts; mover tópicos; mudar status) devem ser extensivamente logadas.

A administração de um sistema de fóruns é multifacetada, cobrindo desde a estrutura dos fóruns até a moderação de posts individuais. Esta API fornece os ganchos necessários para um painel de administração completo.