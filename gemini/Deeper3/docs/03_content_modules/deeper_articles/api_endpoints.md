# Documentação Deeper: Endpoints da API para Módulo de Artigos/Posts

Este documento especifica os endpoints RESTful para o módulo de Artigos/Posts (`deeper_articles`) do \"Deeper\".

Lembre-se das [Convenções de Design da API](../../00_core_concepts/api_design_conventions.md). Todos os endpoints abaixo estão sob o prefixo `/api/v1`.

## Artigos (`/articles`)

### 1. Criar um Novo Artigo

*   **`POST /articles`**
*   **Autenticação:** Requerida. O `profile_id` do autor será extraído do token JWT.
*   **Corpo da Requisição (JSON):**

```json
    {
      \"title\": \"Meu Primeiro Artigo sobre Elixir\",
      \"body\": \"<p>Conteúdo extenso do artigo aqui...</p>\", // Pode ser HTML ou Markdown
      \"slug\": \"meu-primeiro-artigo-elixir\", // Opcional, pode ser gerado no backend se omitido
      \"excerpt\": \"Um breve resumo sobre o artigo.\", // Opcional
      \"featured_image_file_id\": 123, // Opcional, ID de um arquivo da tabela `deeper_files`
      \"status\": \"published\", // Opcional, default: \"draft\". Outros: \"pending_review\", \"archived\"
      \"visibility\": \"public\", // Opcional, default: \"public\". Outros: \"private\", \"unlisted\"
      \"allow_comments\": true, // Opcional, default: true
      \"published_at\": 1678886400, // Opcional, Unix timestamp. Se status=\"published\" e omitido, usa now.
      \"category_ids\": [1, 5] // Opcional, lista de IDs de `deeper_article_categories`
    }
```

```json
    {
      \"data\": {
        \"id\": 1,
        \"profile_id\": 45,
        \"title\": \"Meu Primeiro Artigo sobre Elixir\",
        \"slug\": \"meu-primeiro-artigo-elixir\",
        \"body\": \"<p>Conteúdo extenso do artigo aqui...</p>\",
        \"excerpt\": \"Um breve resumo sobre o artigo.\",
        \"featured_image_file_id\": 123,
        \"featured_image_details\": { // Opcional, se a API fizer join
            \"file_name\": \"elixir_logo.png\",
            \"remote_id\": \"xyz.png\",
            \"storage_object\": \"deeper_local_files\",
            \"access_url\": \"/api/v1/files/view/deeper_local_files/xyz.png\"
        },
        \"status\": \"published\",
        \"visibility\": \"public\",
        \"allow_comments\": 1, // 1 para true
        \"published_at\": 1678886400,
        \"views\": 0,
        \"created_at\": 1678886500,
        \"updated_at\": 1678886500,
        \"author\": { // Opcional, se a API fizer join
            \"name\": \"Nome do Autor\",
            \"profile_id\": 45 // ou account_id
        },
        \"categories\": [ // Opcional, se a API fizer join
          {\"id\": 1, \"name\": \"Programação\", \"slug\": \"programacao\"},
          {\"id\": 5, \"name\": \"Elixir\", \"slug\": \"elixir\"}
        ]
        // URLs para comentários, votos, etc., podem ser incluídas aqui (HATEOAS)
      }
    }
```

```json
    {
      \"data\": [
        // ... array de objetos de artigo (formato similar à resposta do POST, mas pode ser mais conciso) ...
      ],
      \"pagination\": {
        \"total_items\": 100,
        \"total_pages\": 5,
        \"current_page\": 1,
        \"per_page\": 20
      }
    }
```

```json
    {
      \"title\": \"Título Atualizado do Artigo\",
      \"status\": \"archived\",
      \"category_ids\": [1, 7] // Substitui completamente as categorias
    }
```

```json
    // Exemplo 200 OK
    { \"message\": \"Artigo excluído com sucesso.\" }
```

```json
    {
      \"name\": \"Tutoriais Elixir\",
      \"slug\": \"tutoriais-elixir\", // Opcional, pode ser gerado
      \"description\": \"Guias passo a passo para aprender Elixir.\", // Opcional
      \"parent_id\": 1 // Opcional, ID de uma categoria pai
    }
```

```json
    {
      \"data\": {
        \"id\": 10,
        \"name\": \"Tutoriais Elixir\",
        \"slug\": \"tutoriais-elixir\",
        \"description\": \"Guias passo a passo para aprender Elixir.\",
        \"parent_id\": 1
      }
    }
```

```json
    {
      \"data\": [
        {\"id\": 1, \"name\": \"Programação\", \"slug\": \"programacao\", \"parent_id\": null},
        {\"id\": 5, \"name\": \"Elixir\", \"slug\": \"elixir\", \"parent_id\": 1},
        {\"id\": 10, \"name\": \"Tutoriais Elixir\", \"slug\": \"tutoriais-elixir\", \"parent_id\": 5}
        // ...
      ]
      // Paginação pode ser adicionada se o número de categorias for muito grande
    }
```

*   **Resposta de Sucesso (201 Created):**

*   **Respostas de Erro:** `400` (validação falhou, slug duplicado), `401`, `403`.

### 2. Listar Artigos

*   **`GET /articles`**
*   **Autenticação:** Opcional. Se autenticado, pode ver artigos privados/rascunhos próprios. Se não, apenas públicos.
*   **Query Parameters:**
    *   `profile_id` (integer): Filtrar por autor.
    *   `status` (string): Filtrar por status (ex: `published`, `draft`).
    *   `category_id` (integer): Filtrar por ID de categoria.
    *   `category_slug` (string): Filtrar por slug de categoria.
    *   `visibility` (string): Filtrar por visibilidade.
    *   `q` (string): Termo de busca (para título e/ou corpo - requer implementação de busca).
    *   `page`, `per_page` (ou `limit`, `offset`).
    *   `sort_by` (ex: `published_at_desc`, `views_desc`, `title_asc`).
    *   `include` (string CSV, ex: `author,categories,featured_image`): Para solicitar dados relacionados.
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:** `400` (parâmetros de query inválidos).

### 3. Obter um Artigo Específico

*   **`GET /articles/{id_or_slug}`**
    *   Pode aceitar tanto o ID numérico quanto o slug do artigo. O backend precisará detectar qual foi fornecido.
*   **Autenticação:** Opcional. Necessária para ver artigos não públicos se não for o autor.
*   **Query Parameters:**
    *   `include` (string CSV, ex: `author,categories,featured_image,comments_summary,votes_summary`): Para solicitar dados relacionados.
*   **Resposta de Sucesso (200 OK):** Formato similar à resposta do `POST /articles` (item individual).
*   **Respostas de Erro:** `401`, `403` (se privado e sem permissão), `404`.

### 4. Atualizar um Artigo

*   **`PUT /articles/{id}`** ou **`PATCH /articles/{id}`**
    *   `PUT` para substituição total, `PATCH` para atualização parcial. `PATCH` é geralmente preferível.
*   **Autenticação:** Requerida. Apenas o autor ou um administrador pode atualizar.
*   **Corpo da Requisição (JSON):** Campos a serem atualizados (mesmo formato do `POST`).

*   **Resposta de Sucesso (200 OK):** Retorna o objeto de artigo atualizado.
*   **Respostas de Erro:** `400`, `401`, `403`, `404`.

### 5. Excluir um Artigo

*   **`DELETE /articles/{id}`**
*   **Autenticação:** Requerida. Apenas o autor ou um administrador pode excluir.
*   **Resposta de Sucesso (200 OK ou 204 No Content):**

*   **Respostas de Erro:** `401`, `403`, `404`.

## Categorias de Artigos (`/article-categories`)

### 1. Criar uma Nova Categoria

*   **`POST /article-categories`**
*   **Autenticação:** Requerida (geralmente apenas administradores).
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (201 Created):**

*   **Respostas de Erro:** `400` (validação, slug duplicado), `401`, `403`.

### 2. Listar Categorias

*   **`GET /article-categories`**
*   **Autenticação:** Não requerida.
*   **Query Parameters:**
    *   `parent_id` (integer): Para listar subcategorias de uma categoria pai específica.
    *   `include_children` (boolean): Se `true`, pode retornar uma estrutura aninhada ou uma forma de indicar a hierarquia. (Implementação pode ser complexa).
    *   `sort_by` (ex: `name_asc`).
*   **Resposta de Sucesso (200 OK):**

### 3. Obter uma Categoria Específica

*   **`GET /article-categories/{id_or_slug}`**
*   **Autenticação:** Não requerida.
*   **Resposta de Sucesso (200 OK):** Formato similar ao item individual da resposta do `POST`.
*   **Respostas de Erro:** `404`.

### 4. Atualizar uma Categoria

*   **`PUT /article-categories/{id}`** ou **`PATCH /article-categories/{id}`**
*   **Autenticação:** Requerida (geralmente apenas administradores).
*   **Corpo da Requisição (JSON):** Campos a serem atualizados.
*   **Resposta de Sucesso (200 OK):** Retorna o objeto de categoria atualizado.
*   **Respostas de Erro:** `400`, `401`, `403`, `404`.

### 5. Excluir uma Categoria

*   **`DELETE /article-categories/{id}`**
*   **Autenticação:** Requerida (geralmente apenas administradores).
*   **Resposta de Sucesso (200 OK ou 204 No Content):**
*   **Respostas de Erro:** `401`, `403`, `404`. (Considerar o que acontece com artigos e subcategorias - `ON DELETE` constraints).

## Integrações (Exemplos)

*   **Comentários para um Artigo:** `GET /articles/{article_id}/comments` (delegaria ao sistema de comentários).
*   **Votar em um Artigo:** `POST /articles/{article_id}/votes` (delegaria ao sistema de votos).

Estes endpoints fornecem uma interface completa para o módulo de artigos. A lógica para gerar slugs, lidar com o parâmetro `include` para carregar dados relacionados, e implementar a busca (`q`) nos controllers será importante.