# Endpoints da API de Admin para Gerenciamento de Posts (`bx_posts`)

Endpoints para administrar posts (artigos, notícias, etc.). O `{post_id}` aqui se refere ao `id` da tabela principal de posts (ex: `bx_posts_data.id`).

## Endpoints (`/api/v1/admin/content/posts`):

### 1. Listar Todos os Posts (Visão Administrativa)

*   **Endpoint:** `GET /api/v1/admin/content/posts`
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:**
    *   `page`, `per_page`, `sort_by` (ex: `title_asc`, `added_ts_desc`, `views_desc`).
    *   Filtros: `filter_title_like`, `filter_author_id`, `filter_status` (`active`, `pending`, `draft`), `filter_category_id`, `filter_tag`, `filter_is_featured`. `lang` (para títulos de categoria, etc.).
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"post_id\": 101,
          \"title\": \"Título do Primeiro Post\",
          \"author\": { // Informações resumidas do autor
            \"profile_id\": 789,
            \"fullname\": \"Jane Doe\"
          },
          \"status\": \"active\",
          \"category\": \"Notícias\", // Nome da categoria
          \"tags\": [\"elixir\", \"api\", \"deeper\"],
          \"views_count\": 150,
          \"comments_count\": 12,
          \"is_featured\": false,
          \"date_added_timestamp\": 1679000000
        }
        // ... outros posts ...
      ],
      \"pagination\": { /* ... */ }
    }
```

```json
    {
      \"title\": \"Novo Post Criado pelo Admin\",
      \"text_content\": \"Corpo completo do post...\",
      \"author_profile_id\": 789, // Opcional: ID do perfil do autor (pode ser o próprio admin ou outro usuário)
      \"category_id\": 3,
      \"tags_csv\": \"anúncio,importante\", // Ou um array [\"anúncio\", \"importante\"]
      \"status\": \"active\", // Ou \"draft\"
      \"allow_view_to\": \"3\", // ID do grupo de privacidade
      \"allow_comments\": true,
      \"is_featured\": false
      // Outros campos de bx_posts_data
    }
```

```json
    {
      \"title\": \"Título do Post Atualizado pelo Admin\",
      \"text_content\": \"Conteúdo atualizado...\",
      \"category_id\": 4,
      \"tags_csv\": \"atualizado,api\",
      \"status\": \"active\",
      \"is_featured\": true
    }
```

### 2. Criar Novo Post (Administrativo)

*   **Endpoint:** `POST /api/v1/admin/content/posts`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (201 Created):** Retorna o post criado.

### 3. Obter Detalhes Completos de um Post (Visão Administrativa)

*   **Endpoint:** `GET /api/v1/admin/content/posts/{post_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (200 OK):** Retorna um objeto JSON com todos os campos de `bx_posts_data`, informações do autor, categoria, tags, contadores, etc.

### 4. Atualizar Dados de um Post (Administrativo)

*   **Endpoint:** `PUT /api/v1/admin/content/posts/{post_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** Um objeto com os campos de `bx_posts_data` a serem atualizados.

*   **Resposta de Sucesso (200 OK):** Retorna os dados do post atualizado.

### 5. Atualizar Status de um Post

*   **Endpoint:** `PUT /api/v1/admin/content/posts/{post_id}/status`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** `{\"status\": \"hidden\"}` (Valores: `active`, `pending`, `draft`, `hidden`, etc., conforme definido pelo módulo).
*   **Resposta de Sucesso (200 OK).**

### 6. Deletar um Post (Administrativo)

*   **Endpoint:** `DELETE /api/v1/admin/content/posts/{post_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (204 No Content).**
*   **Lógica do Backend:** Remove o post e, potencialmente, seus arquivos associados, comentários, votos, etc. (dependendo das regras de cascata ou limpeza).

### 7. Gerenciar Destaque (Featured) de um Post

*   **Endpoint:** `PUT /api/v1/admin/content/posts/{post_id}/feature`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** `{\"is_featured\": true, \"featured_until_timestamp\": 1699999999}` (timestamp opcional).
*   **Resposta de Sucesso (200 OK).**

### 8. Gerenciamento de Categorias e Tags para Posts (Exemplos)

*   **Listar Categorias de Posts:** `GET /api/v1/admin/content/posts/categories`
*   **Criar Categoria de Posts:** `POST /api/v1/admin/content/posts/categories` (`{\"title_key\": \"_bx_posts_cat_tech\"}`)
*   **Atualizar Categoria de Posts:** `PUT /api/v1/admin/content/posts/categories/{category_id}`
*   **Deletar Categoria de Posts:** `DELETE /api/v1/admin/content/posts/categories/{category_id}`
*   *(Endpoints similares podem existir para gerenciar um vocabulário global de Tags se não forem apenas texto livre).*

## Considerações:

*   **Riqueza de Campos:** Módulos de conteúdo como `bx_posts` podem ter muitos campos personalizados, campos meta, e relações. A API de admin deve ser flexível para lidar com eles.
*   **Upload de Mídia:** Se posts podem ter imagens de destaque ou galerias, a API de admin para posts precisará se integrar com a API de Gerenciamento de Arquivos (`06_file_management/`) para associar arquivos ao post.
*   **Moderação de Comentários/Denúncias:** Comentários e denúncias em posts seriam gerenciados através da API de Admin de Interações (`07_studio_admin_api/interactions_management/`), usando o `post_id` como `object_id`.

Esta estrutura para `bx_posts` pode servir de modelo para a API de administração de outros módulos de conteúdo. O nível de detalhe e os endpoints específicos variariam de acordo com as funcionalidades de cada módulo.