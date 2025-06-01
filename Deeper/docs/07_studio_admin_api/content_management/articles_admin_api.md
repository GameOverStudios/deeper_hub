# Documentação Deeper: API de Administração - Gerenciamento de Artigos

Este documento descreve os endpoints da API \"Deeper\" para administradores gerenciarem o conteúdo do módulo de Artigos (`deeper_articles`).

## Escopo e Funcionalidades:

*   Listar todos os artigos com filtros avançados (status, autor, categoria, etc.).
*   Visualizar detalhes completos de um artigo (visão de admin).
*   Criar novos artigos (como administrador, potencialmente em nome de outros usuários).
*   Atualizar artigos existentes.
*   Alterar o status de artigos (publicado, rascunho, pendente, deletado).
*   Gerenciar categorias e tags de artigos.
*   Destacar/Desdestacar artigos.

## Tabelas Relevantes (Já Definidas em `docs/03_content_modules/deeper_articles/`):

*   `deeper_articles_entries`
*   `deeper_articles_categories`
*   `deeper_articles_tags`
*   `deeper_articles_tags_to_entries`

## Módulo de Acesso a Dados (Já Definido em `docs/03_content_modules/deeper_articles/data_access_module.md`):

*   `Deeper.Content.ArticlesRepo` será utilizado para todas as interações com o banco de dados.

## Endpoints da API de Administração para Artigos

Todos os endpoints estão sob `/api/v1/admin/content/articles/...` e requerem autenticação de administrador.

### 1. Listar Artigos (Visão de Admin)

*   **Endpoint:** `GET /api/v1/admin/content/articles/entries`
*   **Propósito:** Retorna uma lista paginada de todos os artigos no sistema, com filtros para administração.
*   **Autenticação:** Administrador.
*   **Query Parameters:**
    *   `offset` (Integer, Opcional, Default: 0)
    *   `limit` (Integer, Opcional, Default: 20)
    *   `search_term` (String, Opcional): Buscar por `title`, `content_text_summary`, `author_fullname`.
    *   `status` (String, Opcional): Filtrar por `deeper_articles_entries.status` (ex: `published`, `draft`, `pending_approval`, `archived`).
    *   `author_profile_id` (Integer, Opcional): Filtrar por ID do perfil do autor.
    *   `category_id` (Integer, Opcional): Filtrar por ID da categoria.
    *   `tag_id` (Integer, Opcional): Filtrar por ID da tag.
    *   `featured` (Integer, Opcional): Filtrar por `0` ou `1`.
    *   `sort_by` (String, Opcional): Campo para ordenação (ex: `created_at_desc`, `title_asc`, `views_count_desc`).
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"title\": \"Artigo de Exemplo para Admin\",
          \"author_profile_id\": 10,
          \"author_fullname\": \"John Doe\",
          \"category_name\": \"Notícias\",
          \"status\": \"published\",
          \"views_count\": 150,
          \"comments_count\": 5,
          \"featured\": 1,
          \"created_at\": 1678886400,
          \"updated_at\": 1678887000
        }
        // ... mais artigos ...
      ],
      \"pagination\": {
        \"total_items\": 75,
        \"offset\": 0,
        \"limit\": 20
        // ...
      }
    }
```

```json
    {
      \"id\": 1,
      \"author_profile_id\": 10,
      \"author_account_email\": \"john.doe@example.com\", // Info de admin
      \"category_id\": 3,
      \"title\": \"Título do Artigo\",
      \"slug\": \"titulo-do-artigo\",
      \"content_html\": \"<p>Conteúdo completo do artigo...</p>\",
      \"content_text_summary\": \"Resumo do artigo...\",
      \"cover_image_file_id\": 25,
      \"cover_image_url\": \"/files/article_cover_25.jpg\",
      \"status\": \"published\",
      \"visibility_group_id\": \"3\",
      \"allow_comments\": 1,
      \"featured\": 1,
      \"tags\": [\"elixir\", \"phoenix\", \"development\"], // Nomes das tags
      \"created_at\": 1678886400,
      \"updated_at\": 1678887000,
      \"published_at\": 1678886500, // Se houver data de publicação separada
      \"internal_notes\": \"Artigo revisado por Admin X.\" // Campo apenas para admin
      // ... outros campos e contadores ...
    }
```

```json
    {
      \"author_profile_id\": 15, // ID do perfil do autor (pode ser diferente do admin logado)
      \"category_id\": 3,
      \"title\": \"Novo Artigo Criado por Admin\",
      \"content_html\": \"<p>Conteúdo aqui...</p>\",
      \"content_text_summary\": \"Resumo...\",
      \"status\": \"published\", // Admin pode publicar diretamente
      \"featured\": 0,
      \"tags\": [\"anúncio\", \"importante\"], // Lista de nomes de tags
      \"visibility_group_id\": \"1\" // Ex: Público
      // ...
    }
```

```json
    {
      \"title\": \"Título do Artigo Atualizado por Admin\",
      \"content_html\": \"<p>Conteúdo atualizado.</p>\",
      \"status\": \"archived\",
      \"featured\": 1,
      \"category_id\": 4,
      \"tags\": [\"atualizado\", \"importante\"]
    }
```

```json
    {
      \"action\": \"publish\", // ou \"unpublish\", \"archive\", \"feature\", \"unfeature\"
      \"article_ids\": [10, 25, 33]
    }
```

### 2. Obter Detalhes de um Artigo (Visão de Admin)

*   **Endpoint:** `GET /api/v1/admin/content/articles/entries/{articleId}`
*   **Propósito:** Retorna os detalhes completos de um artigo, incluindo informações que podem não ser públicas.
*   **Autenticação:** Administrador.
*   **Parâmetros de URL:**
    *   `{articleId}` (Integer, Obrigatório).
*   **Resposta de Sucesso (200 OK):**
    Semelhante ao endpoint público `GET /api/v1/articles/{articleId}`, mas pode incluir:
    *   Histórico de status.
    *   Informações de moderação.
    *   Notas internas do admin.
    *   Dados completos do autor, incluindo email da conta.

### 3. Criar Novo Artigo (como Admin)

*   **Endpoint:** `POST /api/v1/admin/content/articles/entries`
*   **Propósito:** Cria um novo artigo. O administrador pode especificar o autor.
*   **Autenticação:** Administrador.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (201 Created):** Corpo do artigo criado.
    *   Cabeçalho `Location`: `/api/v1/admin/content/articles/entries/{newArticleId}`.

### 4. Atualizar Artigo (como Admin)

*   **Endpoint:** `PUT /api/v1/admin/content/articles/entries/{articleId}`
*   **Propósito:** Atualiza os dados de um artigo existente.
*   **Autenticação:** Administrador.
*   **Parâmetros de URL:**
    *   `{articleId}` (Integer, Obrigatório).
*   **Corpo da Requisição (JSON):** Campos a serem atualizados.

*   **Resposta de Sucesso (200 OK):** Corpo do artigo atualizado.

### 5. Deletar Artigo (Soft ou Hard Delete - como Admin)

*   **Endpoint:** `DELETE /api/v1/admin/content/articles/entries/{articleId}`
*   **Propósito:** Remove um artigo. Pode ser um soft delete (mudando o status para `deleted` ou `archived`) ou um hard delete.
*   **Autenticação:** Administrador.
*   **Parâmetros de URL:**
    *   `{articleId}` (Integer, Obrigatório).
*   **Query Parameters:**
    *   `permanent` (Boolean, Opcional, Default: `false`): Se `true`, realiza um hard delete. Caso contrário, um soft delete (ex: muda status).
*   **Resposta de Sucesso (204 No Content ou 200 OK com mensagem).**

### Gerenciamento de Metadados de Artigos (Categorias, Tags - Admin)

Os endpoints para gerenciar as entidades `deeper_articles_categories` e `deeper_articles_tags` em si (CRUD para as próprias categorias e tags) seriam separados:

*   `GET /api/v1/admin/content/articles/categories`
*   `POST /api/v1/admin/content/articles/categories`
*   `PUT /api/v1/admin/content/articles/categories/{categoryId}`
*   `DELETE /api/v1/admin/content/articles/categories/{categoryId}`
*   Endpoints similares para `/tags`.

A associação de tags a um artigo é feita durante a criação/atualização do artigo (passando uma lista de nomes ou IDs de tags). O `ArticlesRepo` lidaria com a sincronização da tabela `deeper_articles_tags_to_entries`.

### Ações em Massa em Artigos (Opcional)

*   **Endpoint:** `POST /api/v1/admin/content/articles/entries/bulk-actions`
*   **Propósito:** Realizar ações em múltiplos artigos (ex: publicar, despublicar, arquivar, destacar).
*   **Autenticação:** Administrador.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):** Mensagem de status e resultados por artigo.

### Moderação de Comentários/Votos/Denúncias de Artigos

Estes endpoints seriam parte das APIs de administração dos respectivos sistemas de interação (Comentários, Votos, Denúncias), mas permitiriam filtrar pelo `object_id` do artigo.

*   Ex: `GET /api/v1/admin/interactions/comments?object_type=article&object_id={articleId}`
*   Ex: `PUT /api/v1/admin/interactions/comments/{commentId}/status` (Corpo: `{\"status\": \"approved\"}`)

Esta API de administração para artigos fornece aos administradores as ferramentas necessárias para gerenciar efetivamente o conteúdo de artigos na plataforma \"Deeper\". Uma estrutura similar seria aplicada para os endpoints de administração de outros módulos de conteúdo.