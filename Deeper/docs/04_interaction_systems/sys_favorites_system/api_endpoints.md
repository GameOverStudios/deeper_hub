# Documentação Deeper: Endpoints da API para o Sistema de Favoritos

Este documento especifica os endpoints RESTful para interagir com o sistema genérico de \"Favoritos\" no \"Deeper\". Os usuários podem marcar/desmarcar vários tipos de conteúdo como favoritos.

**Convenções Gerais:**
*   Endpoints sob `/api/v1`.
*   Respostas e corpos de requisição em JSON.
*   Autenticação JWT obrigatória para todas as operações de favoritar/desfavoritar e para listar os favoritos de um usuário específico.
*   Códigos de status HTTP e formatos de erro seguem as [Convenções de Design da API](../../00_core_concepts/api_design_conventions.md).
*   ACL pode ser aplicado (geralmente, qualquer usuário logado pode favoritar).

**Parâmetros de Path Genéricos:**

*   `{resource_type}`: Identifica o tipo de recurso principal (ex: `articles`, `persons`). Este será usado para determinar o `system_name` do sistema de favoritos.
*   `{resource_id}`: O ID do recurso principal específico que está sendo favoritado/desfavoritado.

---

## 1. Favoritar/Desfavoritar um Recurso (`/{resource_type}/{resource_id}/favorite`)

Este endpoint único lida tanto com favoritar quanto com desfavoritar, usando métodos HTTP diferentes.

### 1.1. Marcar um Recurso como Favorito

*   **Endpoint:** `POST /{resource_type}/{resource_id}/favorite`
*   **Autenticação:** Requerida (JWT).
*   **Descrição:** Marca um recurso específico como favorito para o usuário autenticado.
*   **Corpo da Requisição:** Vazio ou opcionalmente um JSON `{}`.
*   **Resposta de Sucesso (201 Created ou 200 OK se já favoritado e a API for idempotente neste caso):**

```json
    {
      \"data\": {
        \"system_name\": \"deeper_articles_favorites\", // Exemplo
        \"object_id\": \"{resource_id}\",
        \"fan_profile_id\": 15, // ID do perfil do usuário que favoritou
        \"favorited_at\": 1678891000,
        \"status\": \"favorited\",
        \"new_favorites_count\": 25 // Contagem atualizada de favoritos para o objeto
      }
    }
```

```json
    {
      \"data\": {
        \"status\": \"unfavorited\",
        \"new_favorites_count\": 24 // Contagem atualizada de favoritos para o objeto
      }
    }
```

```json
    {
      \"data\": {
        \"object_id\": \"{resource_id}\",
        \"is_favorited\": true, // ou false
        \"favorited_at\": 1678891000 // Presente se is_favorited for true
      }
    }
```

```json
    // Exemplo se system_name NÃO for fornecido (agrupado)
    {
      \"data\": {
        \"deeper_articles_favorites\": [
          {\"object_id\": 101, \"favorited_at\": 1678891000},
          {\"object_id\": 105, \"favorited_at\": 1678890000}
          // O cliente precisaria buscar os detalhes desses object_ids separadamente
        ],
        \"bx_persons_profile_favorites\": [
          {\"object_id\": 22, \"favorited_at\": 1678885000}
        ]
      },
      \"pagination\": { // Paginação pode ser complexa se agrupar; mais simples se system_name for obrigatório
        \"note\": \"Pagination applies per system_name if requested individually.\"
      }
    }

    // Exemplo se system_name = \"deeper_articles_favorites\" FORNECIDO
    {
      \"data\": [ // Lista de IDs de artigos favoritados
        // Para retornar objetos completos, a API faria JOINs ou chamadas subsequentes.
        // Por simplicidade, retornamos IDs, e o cliente busca os detalhes.
        {\"object_id\": 101, \"title\": \"Artigo Favorito 1\", \"favorited_at\": ...},
        {\"object_id\": 105, \"title\": \"Artigo Favorito 2\", \"favorited_at\": ...}
      ],
      \"pagination\": {
        \"total_items\": 2,
        \"current_page\": 1,
        \"per_page\": 20,
        \"total_pages\": 1
      }
    }
```

```json
    {
      \"data\": {
        \"object_id\": \"{resource_id}\",
        \"system_name\": \"deeper_articles_favorites\",
        \"favorites_count\": 25,
        \"current_user_is_fan\": true // ou false, ou null se não autenticado
      }
    }
```

*   **Respostas de Erro:**
    *   `400 Bad Request`: Se `resource_type` não for um sistema de favoritos válido.
    *   `401 Unauthorized`: Não autenticado.
    *   `403 Forbidden`: Usuário não tem permissão para favoritar (raro, mas possível).
    *   `404 Not Found`: Recurso principal (`{resource_id}`) não encontrado.
    *   `409 Conflict`: Se o item já está favoritado (alternativamente, pode retornar 200 OK).
    *   `500 Internal Server Error`.
*   **Lógica de Backend (Controller):**
    1.  Extrair `fan_profile_id` do JWT.
    2.  Mapear `{resource_type}` para o `system_name` apropriado (ex: `articles` -> `\"deeper_articles_favorites\"`).
    3.  Verificar permissão ACL.
    4.  Chamar `Deeper.InteractionSystems.FavoritesRepo.add_favorite/3` com `system_name`, `{resource_id}`, `fan_profile_id`.
    5.  Se `add_favorite` retornar `{:error, :already_favorited}`, o controller pode optar por retornar `200 OK` com o status atual ou `409 Conflict`.
    6.  Buscar a nova contagem de favoritos para o objeto.
    7.  Retornar os detalhes.

### 1.2. Desmarcar um Recurso como Favorito

*   **Endpoint:** `DELETE /{resource_type}/{resource_id}/favorite`
*   **Autenticação:** Requerida (JWT).
*   **Descrição:** Remove um recurso da lista de favoritos do usuário autenticado.
*   **Resposta de Sucesso (200 OK ou 204 No Content):**

*   **Respostas de Erro:**
    *   `401 Unauthorized`.
    *   `403 Forbidden`.
    *   `404 Not Found`: Recurso principal ou o favorito do usuário para este recurso não encontrado.
*   **Lógica de Backend:**
    1.  Extrair `fan_profile_id` do JWT.
    2.  Mapear `{resource_type}` para o `system_name`.
    3.  Verificar permissão ACL.
    4.  Chamar `Deeper.InteractionSystems.FavoritesRepo.remove_favorite/3`.
    5.  Se `remove_favorite` retornar `{:error, :not_favorited}`, o controller pode optar por retornar `200 OK` (idempotência) ou `404 Not Found`.
    6.  Buscar a nova contagem de favoritos para o objeto.
    7.  Retornar o status.

### 1.3. Verificar Status de Favorito de um Recurso (para o usuário atual)

*   **Endpoint:** `GET /{resource_type}/{resource_id}/favorite/status`
*   **Autenticação:** Requerida (JWT).
*   **Descrição:** Verifica se o usuário autenticado favoritou um recurso específico.
*   **Resposta de Sucesso (200 OK):**

*   **Lógica de Backend:**
    1.  Extrair `fan_profile_id` do JWT.
    2.  Mapear `{resource_type}` para o `system_name`.
    3.  Chamar `Deeper.InteractionSystems.FavoritesRepo.is_favorited?/3`.
    4.  Se `true`, opcionalmente buscar `favorited_at` da tabela track.

---

## 2. Favoritos de um Usuário (`/profiles/{profile_id}/favorites`)

Estes endpoints são para listar os itens que um usuário específico favoritou.

### 2.1. Listar Objetos Favoritados por um Usuário

*   **Endpoint:** `GET /profiles/{profile_id}/favorites`
    *   `profile_id`: O ID do perfil do usuário cujos favoritos estão sendo listados. Pode ser \"me\" para o usuário autenticado.
*   **Autenticação:** Requerida (JWT) - Para ver os favoritos de \"me\". Para ver os favoritos de outro usuário, pode depender das configurações de privacidade da lista de favoritos desse usuário (se tal configuração existir). Para a API inicial, podemos restringir a \"me\" ou a perfis públicos.
*   **Descrição:** Retorna uma lista paginada dos IDs dos objetos favoritados por um usuário específico, agrupados por `system_name` ou para um `system_name` específico.
*   **Query Parameters:**
    *   `page={integer}` (default: 1)
    *   `per_page={integer}` (default: 20)
    *   `system_name={string}` (Opcional: para filtrar por um tipo de sistema de favoritos, ex: `deeper_articles_favorites`). Se não fornecido, pode listar todos ou agrupar.
*   **Resposta de Sucesso (200 OK):**

*   **Lógica de Backend:**
    1.  Resolver `profile_id` (se \"me\", usar `fan_profile_id` do JWT).
    2.  Verificar permissão para ver os favoritos (se não for \"me\").
    3.  Chamar `Deeper.InteractionSystems.FavoritesRepo.list_user_favorite_object_ids/3` (se `system_name` fornecido).
    4.  Se a API for retornar detalhes dos objetos (não apenas IDs), o controller precisará, para cada `object_id` e `system_name`, chamar o repo apropriado (ex: `ArticlesRepo.get_article_by_id`) para buscar os detalhes. Isso pode levar a problemas N+1 se não for otimizado.
    5.  Uma abordagem mais eficiente para retornar objetos completos seria o `FavoritesRepo` ter uma função que já faz JOINs (complexo se `system_name` for variado).

---

## 3. Informações de Favoritos para um Objeto (`/{resource_type}/{resource_id}/favorites-info`)

### 3.1. Obter Contagem de Favoritos para um Recurso

*   **Endpoint:** `GET /{resource_type}/{resource_id}/favorites-info`
*   **Autenticação:** Opcional.
*   **Descrição:** Retorna a contagem total de quantos usuários favoritaram um recurso específico e se o usuário atual (se autenticado) o favoritou.
*   **Resposta de Sucesso (200 OK):**