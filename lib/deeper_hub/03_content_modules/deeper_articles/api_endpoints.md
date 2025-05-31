# Documentação Deeper: Endpoints da API para Artigos (`deeper_articles`)

Este documento especifica os endpoints RESTful para o gerenciamento de Artigos no sistema \"Deeper\".

**Convenções Gerais:**
*   Endpoints sob `/api/v1`.
*   Respostas e corpos de requisição em JSON.
*   Autenticação JWT para operações que requerem login/permissão.
*   Códigos de status HTTP e formatos de erro seguem as [Convenções de Design da API](../../00_core_concepts/api_design_conventions.md).
*   ACL (Controle de Acesso) será aplicado para determinar quem pode criar, editar, deletar ou ver artigos (especialmente rascunhos ou com privacidade restrita).

---

## 1. Artigos (`/articles`)

### 1.1. Listar Artigos

*   **Endpoint:** `GET /articles`
*   **Autenticação:** Opcional (para ver artigos publicados). Pode ser necessária para ver rascunhos ou artigos com privacidade restrita se o usuário for o autor ou tiver permissão.
*   **Descrição:** Retorna uma lista paginada de artigos, com filtros e ordenação.
*   **Query Parameters:**
    *   `page={integer}` (default: 1)
    *   `per_page={integer}` (default: 20)
    *   `sort_by={string}` (default: `published_at_desc`. Outras opções: `created_at_asc`, `views_desc`, `title_asc`)
    *   `status={string}` (default: `published`. Opções: `draft`, `pending`, `archived`) - Acesso a status não-publicados requer permissão.
    *   `category_slug={string}` (para filtrar por slug de categoria)
    *   `tag_slug={string}` (para filtrar por slug de tag)
    *   `author_profile_id={integer}` (para filtrar por ID do perfil do autor)
    *   `q={string}` (para busca full-text no título e/ou corpo - implementação de busca a definir)
    *   `lang={lang_code}` (para títulos/conteúdo traduzido, se aplicável e suportado)
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"id\": 101,
          \"title\": \"Meu Primeiro Artigo\",
          \"slug\": \"meu-primeiro-artigo\",
          \"summary\": \"Este é um resumo do meu primeiro artigo...\",
          \"featured_image_url\": \"/path/to/image.jpg\", // URL da imagem de destaque
          \"category\": { // Opcional, se category_id estiver presente
            \"name\": \"Tecnologia\",
            \"slug\": \"tecnologia\"
          },
          \"tags\": [\"elixir\", \"api\", \"deep\"], // Lista de nomes de tags
          \"author\": { // Informações básicas do autor
            \"profile_id\": 12,
            \"name\": \"Nome do Autor\" // Pode vir de um JOIN ou busca adicional
            // \"avatar_url\": \"...\"
          },
          \"status\": \"published\",
          \"published_at\": 1678880000, // Unix Timestamp
          \"views\": 150,
          \"created_at\": 1678880000,
          \"updated_at\": 1678880500,
          \"allow_view_to\": \"3\" // Informativo
        }
        // ... mais artigos ...
      ],
      \"pagination\": {
        \"total_items\": 50,
        \"current_page\": 1,
        \"per_page\": 20,
        \"total_pages\": 3
      }
    }
```

```json
    {
      \"title\": \"Novo Artigo Incrível\",
      \"slug\": \"novo-artigo-incrivel\", // Opcional, pode ser gerado a partir do título se não fornecido
      \"summary\": \"Um breve resumo.\",
      \"body\": \"Conteúdo completo do artigo aqui...\",
      \"body_type\": \"markdown\", // 'markdown', 'html', 'text'
      \"featured_image_id\": null, // ID de um arquivo previamente upado, ou null
      \"category_id\": 5, // ID de uma categoria existente, ou null
      \"tags\": [\"elixir\", \"novidade\"], // Lista de nomes de tags (serão criadas se não existirem)
      \"status\": \"draft\", // 'draft', 'published', 'pending'
      \"published_at\": null, // Unix timestamp para agendar, ou null para publicar agora (se status='published')
      \"allow_view_to\": \"3\", // Grupo de privacidade
      \"meta_title\": \"Título SEO do Novo Artigo\",
      \"meta_description\": \"Descrição SEO.\"
    }
```

```json
    {
      \"data\": {
        \"id\": 101,
        \"title\": \"Meu Primeiro Artigo\",
        \"slug\": \"meu-primeiro-artigo\",
        \"summary\": \"Este é um resumo...\",
        \"body\": \"Conteúdo completo...\",
        \"body_type\": \"markdown\",
        \"featured_image_url\": \"/path/to/image.jpg\",
        \"category\": {\"id\": 3, \"name\": \"Tecnologia\", \"slug\": \"tecnologia\"},
        \"tags\": [\"elixir\", \"api\"], // Lista de nomes de tags
        \"author\": {
          \"profile_id\": 12,
          \"name\": \"Nome do Autor\",
          \"avatar_url\": \"/path/to/autor_avatar.jpg\"
          // Mais detalhes do autor podem ser incluídos
        },
        \"status\": \"published\",
        \"published_at\": 1678880000,
        \"views\": 152, // Pode ser incrementado aqui ou por um endpoint separado
        \"allow_view_to\": \"3\",
        \"meta_title\": \"Título SEO\",
        \"meta_description\": \"Descrição SEO\",
        \"created_at\": 1678880000,
        \"updated_at\": 1678880500
        // Poderia incluir contagem de comentários/votos aqui se desejado (requer mais JOINs/queries)
      }
    }
```

```json
    {
      \"title\": \"Título do Artigo Atualizado\",
      \"body\": \"Conteúdo atualizado.\",
      \"tags\": [\"elixir\", \"atualizado\", \"core\"], // Nova lista de tags (sobrescreve a anterior)
      \"status\": \"published\"
      // ... outros campos ...
    }
```

```json
    // Se hierarchical=false (lista plana)
    {
      \"data\": [
        {\"id\": 1, \"parent_id\": 0, \"name\": \"Tecnologia\", \"slug\": \"tecnologia\", \"item_count\": 25, \"order\": 1},
        {\"id\": 2, \"parent_id\": 0, \"name\": \"Notícias\", \"slug\": \"noticias\", \"item_count\": 10, \"order\": 2},
        {\"id\": 3, \"parent_id\": 1, \"name\": \"Elixir\", \"slug\": \"elixir\", \"item_count\": 15, \"order\": 1}
      ]
    }
    // Se hierarchical=true
    {
      \"data\": [
        {
          \"id\": 1, \"parent_id\": 0, \"name\": \"Tecnologia\", \"slug\": \"tecnologia\", \"item_count\": 25,
          \"sub_categories\": [
            {\"id\": 3, \"parent_id\": 1, \"name\": \"Elixir\", \"slug\": \"elixir\", \"item_count\": 15}
          ]
        },
        {\"id\": 2, \"parent_id\": 0, \"name\": \"Notícias\", \"slug\": \"noticias\", \"item_count\": 10, \"sub_categories\": []}
      ]
    }
```

```json
    {
      \"data\": [
        {\"id\": 1, \"name\": \"elixir\", \"slug\": \"elixir\", \"item_count\": 30},
        {\"id\": 2, \"name\": \"api\", \"slug\": \"api\", \"item_count\": 22}
      ]
    }
```

*   **Lógica de Backend:**
    1.  Controller recebe os query params.
    2.  Obtém o `current_user_profile_id` e `current_user_level_id` do JWT (se presente).
    3.  Constrói o mapa `opts` para `Deeper.Content.ArticlesRepo.list_articles/1`.
    4.  Aplica lógica de ACL para determinar quais status de artigos o usuário pode ver.
    5.  O `ArticlesRepo` executa a query, incluindo JOINs para filtros e dados básicos do autor/categoria.
    6.  (Opcional) Para cada artigo, pode ser necessário buscar detalhes adicionais do autor (ex: nome completo de `bx_persons_data`) se não incluído no JOIN principal.

### 1.2. Criar Novo Artigo

*   **Endpoint:** `POST /articles`
*   **Autenticação:** Requerida (JWT). Permissão ACL para \"criar artigo\" será verificada.
*   **Descrição:** Cria um novo artigo.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (201 Created):**
    *   Corpo contém o artigo recém-criado (similar à resposta de `GET /articles/{id}`).
    *   Header `Location` apontando para o novo recurso (ex: `/api/v1/articles/{new_id}`).
*   **Respostas de Erro:** `400`, `401`, `403`, `422` (ex: slug duplicado, falha de validação).
*   **Lógica de Backend:**
    1.  Extrair `author_profile_id` do JWT.
    2.  Verificar permissão ACL para criar artigos.
    3.  Validar dados de entrada (ex: `title` e `body` obrigatórios).
    4.  Gerar `slug` a partir do `title` se não fornecido (garantindo unicidade).
    5.  Chamar `Deeper.Content.ArticlesRepo.create_article/1`. (O repo internamente chamará `handle_article_tags`).

### 1.3. Obter Artigo Específico

*   **Endpoint:** `GET /articles/{id_or_slug}`
    *   `id_or_slug`: Pode ser o ID numérico do artigo ou seu slug.
*   **Autenticação:** Opcional (similar a `GET /articles`).
*   **Descrição:** Retorna os detalhes de um artigo específico.
*   **Resposta de Sucesso (200 OK):**

*   **Lógica de Backend:**
    1.  Resolver `id_or_slug`. Se for string, tentar como slug; se for número, como ID.
    2.  Chamar `Deeper.Content.ArticlesRepo.get_article_by_id/1` ou `get_article_by_slug/1`.
    3.  Verificar permissão de visualização (status, `allow_view_to`) para o usuário atual.
    4.  (Opcional) Incrementar visualizações via `Deeper.Content.ArticlesRepo.increment_article_views/1` (se esta for a estratégia de contagem de views).
    5.  (Opcional) Buscar detalhes adicionais do autor.

### 1.4. Atualizar Artigo Existente

*   **Endpoint:** `PUT /articles/{id}`
*   **Autenticação:** Requerida. O usuário deve ser o autor do artigo ou ter permissão de administrador/moderador.
*   **Descrição:** Atualiza um artigo existente.
*   **Corpo da Requisição (JSON):**
    *   Similar ao corpo de `POST /articles`, contendo os campos a serem atualizados. Campos não fornecidos não são alterados (comportamento de `PATCH` é mais apropriado para atualizações parciais, mas `PUT` pode ser usado se o cliente sempre enviar o recurso completo ou se o backend tratar campos ausentes como \"não alterar\"). Se for `PUT` \"puro\", o cliente deveria enviar todos os campos. Para API, `PATCH` é geralmente preferido para atualizações parciais. Por simplicidade, podemos tratar este `PUT` como um `PATCH` na prática.

*   **Resposta de Sucesso (200 OK):**
    *   Corpo contém o artigo atualizado.
*   **Respostas de Erro:** `400`, `401`, `403`, `404`, `422`.
*   **Lógica de Backend:**
    1.  Verificar permissão ACL para editar o artigo (autor ou admin).
    2.  Validar dados.
    3.  Chamar `Deeper.Content.ArticlesRepo.update_article/2`. (O repo internamente chamará `handle_article_tags` se `:tags` estiver presente).

### 1.5. Deletar Artigo

*   **Endpoint:** `DELETE /articles/{id}`
*   **Autenticação:** Requerida. O usuário deve ser o autor ou ter permissão de admin.
*   **Descrição:** Deleta um artigo.
*   **Resposta de Sucesso (204 No Content).**
*   **Respostas de Erro:** `401`, `403`, `404`.
*   **Lógica de Backend:**
    1.  Verificar permissão ACL para deletar o artigo.
    2.  Chamar `Deeper.Content.ArticlesRepo.delete_article/1`.

---

## 2. Categorias de Artigos (`/articles/categories`)

### 2.1. Listar Categorias de Artigos

*   **Endpoint:** `GET /articles/categories`
*   **Autenticação:** Nenhuma (público).
*   **Descrição:** Retorna uma lista de todas as categorias de artigos.
*   **Query Parameters:**
    *   `hierarchical={true|false}` (default: `false`. Se `true`, retorna estrutura aninhada).
*   **Resposta de Sucesso (200 OK):**

*   **Lógica de Backend:** Chamar `Deeper.Content.ArticlesRepo.list_categories/1`.

### 2.2. Obter Categoria Específica

*   **Endpoint:** `GET /articles/categories/{slug}`
*   **Autenticação:** Nenhuma.
*   **Descrição:** Retorna detalhes de uma categoria específica.
*   **Resposta de Sucesso (200 OK):** (Objeto similar ao item da lista acima).
*   **Lógica de Backend:** Chamar `Deeper.Content.ArticlesRepo.get_category_by_slug/1`.

---

## 3. Tags de Artigos (`/articles/tags`)

### 3.1. Listar Tags Populares/Todas

*   **Endpoint:** `GET /articles/tags`
*   **Autenticação:** Nenhuma.
*   **Descrição:** Retorna uma lista de tags.
*   **Query Parameters:**
    *   `popular={true|false}` (default: `false`. Se `true`, retorna as mais usadas).
    *   `limit={integer}` (default: 20, usado com `popular=true`).
*   **Resposta de Sucesso (200 OK):**