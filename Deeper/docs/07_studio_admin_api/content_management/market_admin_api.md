# API de Administração: Gerenciamento de Conteúdo do Marketplace (`bx_market`)

Esta seção da API de Administração \"Deeper\" fornece endpoints para que administradores e moderadores gerenciem as listagens de produtos/serviços e categorias do módulo Marketplace (`bx_market`).

**Autenticação:** Requerida (nível de administrador ou moderador com permissões para `bx_market`).

## 1. Gerenciamento de Listagens do Marketplace (`/api/v1/admin/market/entries`)

Estes endpoints interagem com a tabela `bx_market_entries`.

### `GET /api/v1/admin/market/entries`
*   **Descrição:** Lista todas as listagens do marketplace com filtros avançados para administração.
*   **Query Parameters:**
    *   `author_id` (integer)
    *   `category_id` (integer)
    *   `status` (string, ex: `\"active\"`, `\"pending\"`, `\"hidden\"`, `\"sold\"`, `\"expired\"` - status público)
    *   `status_admin` (string, ex: `\"active\"`, `\"pending\"`, `\"hidden\"` - status de moderação)
    *   `search_term` (string, busca em `title`, `description`, `name`)
    *   `min_price`, `max_price`, `currency_code`
    *   `has_reports` (boolean, `true` para listar apenas itens com `reports_count > 0`)
    *   `is_featured` (boolean, `true` para listar apenas itens com `featured_until` no futuro)
    *   `page` (integer, default 1)
    *   `per_page` (integer, default 20)
    *   `sort_by` (string, ex: `\"added_desc\"`, `\"price_asc\"`, `\"reports_count_desc\"`)
    *   `preload` (string, ex: `\"category,author_summary,photos_summary\"`)
*   **Resposta de Sucesso (200 OK):** Similar à listagem pública, mas pode incluir campos administrativos como `status_admin`, `reports_count`.

```json
    {
      \"data\": [
        {
          \"id\": 101,
          \"title\": \"Amazing Used Laptop\",
          \"author_id\": 123,
          \"author_summary\": { \"display_name\": \"John Doe\" },
          \"category\": { \"title\": \"Electronics\" },
          \"status\": \"active\",
          \"status_admin\": \"active\",
          \"price\": 499.99,
          \"currency_code\": \"USD\",
          \"reports_count\": 0,
          \"featured_until\": null,
          \"added\": 1678886400
          // ...
        }
      ],
      \"pagination\": { ... }
    }
```

```json
    {
      \"data\": {
        // ... todos os campos de bx_market_entries ...
        \"status_admin\": \"active\",
        \"reports_count\": 1,
        \"author_profile\": { ... }, // Detalhes completos do perfil do autor
        \"all_photos\": [ ... ],
        \"reports_list\": [ // Se preload
          { \"report_id\": 1, \"reporter_profile_id\": 45, \"type\": \"spam\", \"text\": \"...\", \"date\": ... }
        ]
      }
    }
```

```json
    {
      \"action\": \"approve\", // \"approve\", \"reject\", \"hide\", \"unhide\", \"feature\", \"unfeature\"
      \"feature_duration_days\": 30 // Opcional, para action \"feature\"
    }
```

### `GET /api/v1/admin/market/entries/{entry_id}`
*   **Descrição:** Obtém detalhes completos de uma listagem específica, incluindo todos os campos e metadados administrativos.
*   **Query Parameters:** `preload` (ex: `\"all_photos,category_details,author_profile,reports_list\"`)
*   **Resposta de Sucesso (200 OK):** Similar à visualização pública, mas com mais detalhes administrativos.

*   **Respostas de Erro:** `404 Not Found`.

### `PUT /api/v1/admin/market/entries/{entry_id}`
*   **Descrição:** Permite que um administrador atualize qualquer campo de uma listagem.
*   **Corpo da Requisição (JSON):** Campos de `bx_market_entries` a serem atualizados (ex: `title`, `description`, `price`, `status`, `status_admin`, `category_id`, `featured_until`, `author_id` - com cuidado ao mudar o autor).
*   **Resposta de Sucesso (200 OK):** Corpo da listagem atualizada.
*   **Respostas de Erro:** `400`, `404`, `422`.

### `POST /api/v1/admin/market/entries/{entry_id}/action`
*   **Descrição:** Executa ações de moderação específicas na listagem.
*   **Corpo da Requisição (JSON):**

    *   `approve`: muda `status_admin` para 'active', `status` para 'active'.
    *   `reject`/`hide`: muda `status_admin` para 'hidden', `status` para 'hidden'.
    *   `feature`: define `featured_until` para `agora + feature_duration_days`.
    *   `unfeature`: define `featured_until` para `null` ou passado.
*   **Resposta de Sucesso (200 OK):** Corpo da listagem atualizada.
*   **Respostas de Erro:** `400`, `404`, `422`.

### `DELETE /api/v1/admin/market/entries/{entry_id}`
*   **Descrição:** Deleta permanentemente uma listagem do marketplace.
*   **Resposta de Sucesso (204 No Content ou 200 OK com mensagem).**
*   **Respostas de Erro:** `404`.

## 2. Gerenciamento de Categorias do Marketplace (`/api/v1/admin/market/categories`)

Estes endpoints permitem aos administradores gerenciar as categorias do marketplace (`bx_market_categories`). A estrutura dos endpoints é idêntica à API pública para categorias (`/api/v1/market/categories`), mas estes endpoints requerem autenticação de administrador.

### `POST /api/v1/admin/market/categories`
*   **Descrição:** Cria uma nova categoria.
*   **Corpo da Requisição e Resposta:** Idêntico a `POST /api/v1/market/categories`.

### `GET /api/v1/admin/market/categories`
*   **Descrição:** Lista todas as categorias, incluindo inativas, com opções de paginação e ordenação.
*   **Query Parameters e Resposta:** Similar a `GET /api/v1/market/categories`, mas pode mostrar todas por padrão.

### `GET /api/v1/admin/market/categories/{category_id}`
*   **Descrição:** Obtém detalhes de uma categoria específica.
*   **Resposta:** Idêntica a `GET /api/v1/market/categories/{id_or_uri}`.

### `PUT /api/v1/admin/market/categories/{category_id}`
*   **Descrição:** Atualiza uma categoria existente.
*   **Corpo da Requisição e Resposta:** Idêntico a `PUT /api/v1/market/categories/{id}`.

### `DELETE /api/v1/admin/market/categories/{category_id}`
*   **Descrição:** Deleta uma categoria. (Pode falhar se houver produtos nela e a FK for `RESTRICT`).
*   **Resposta:** Idêntica a `DELETE /api/v1/market/categories/{id}`.

## 3. Gerenciamento de Fotos de Listagens (Admin)

Administradores podem precisar gerenciar fotos associadas a listagens (ex: remover fotos inadequadas).

### `GET /api/v1/admin/market/entries/{entry_id}/photos`
*   **Descrição:** Lista todas as fotos de uma listagem específica para administração.
*   **Resposta:** Similar a `GET /api/v1/market/entries/{entry_id}/photos`, pode incluir mais metadados do arquivo.

### `DELETE /api/v1/admin/market/entries/{entry_id}/photos/{photo_id}`
*   **Descrição:** Administrador remove uma foto de uma listagem (remove a entrada em `bx_market_photos` e, opcionalmente, pode marcar o arquivo original para revisão ou exclusão no sistema de arquivos, dependendo da política).
*   **Resposta de Sucesso (204 No Content).**
*   **Respostas de Erro:** `404`.

## Considerações para API de Admin do Marketplace:

*   **Logs de Auditoria:** Todas as ações administrativas (mudança de status, edição, exclusão) devem ser registradas em `sys_audit`.
*   **Permissões Granulares:** Idealmente, o sistema ACL poderia definir permissões separadas para \"moderar marketplace\" vs. \"gerenciar categorias do marketplace\".
*   **Busca e Filtros:** A capacidade de encontrar rapidamente listagens específicas com base em vários critérios é fundamental para a moderação eficaz.

Esta API de administração fornecerá as ferramentas necessárias para manter a qualidade e a integridade do conteúdo no módulo Marketplace da plataforma \"Deeper\".