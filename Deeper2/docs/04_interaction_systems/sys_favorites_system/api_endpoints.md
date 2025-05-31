# Documentação Deeper: Endpoints da API para Sistema de Favoritos Genérico

Este documento especifica os endpoints RESTful da API \"Deeper\" para interagir com o sistema de favoritos genérico. Estes endpoints permitem que usuários favoritem/desfavoritem itens, verifiquem o status de favorito e listem favoritos.

## Convenções Gerais:

*   **Base URL:** `/api/v1/favorites`
*   **Identificadores:**
    *   `{object_fav_name}`: O nome do \"objeto de favorito\" (de `sys_objects_favorite.name`, ex: `bx_persons_favorites`, `bx_posts_favorites`). Identifica qual sistema de favoritos está sendo usado.
    *   `{item_id}`: O ID do item de conteúdo principal que está sendo favoritado.
*   **Autenticação:** Ações de favoritar/desfavoritar (POST/DELETE) são protegidas. A listagem de quem favoritou pode ser pública ou protegida dependendo da configuração `is_public` do objeto de favorito.
*   **Formato de Resposta:** JSON.
*   **Códigos de Status e Erros:** Conforme `docs/00_core_concepts/api_design_conventions.md`.

## Endpoints

### 1. Favoritar/Desfavoritar um Item (Toggle)

*   **Endpoint:** `POST /favorites/object/{object_fav_name}/item/{item_id}/toggle`
*   **Status:** Protegido
*   **Descrição:** Permite que um usuário autenticado favorite um item se ainda não o fez, ou desfavorite se já o fez (se `is_undo` for permitido na configuração do objeto de favorito).
*   **Parâmetros de URL:**
    *   `{object_fav_name}`: Nome do objeto de favorito.
    *   `{item_id}`: ID do item de conteúdo.
*   **Corpo da Requisição:** Vazio (ou opcionalmente `{\"favorite\": true/false}` se não for um toggle e sim uma definição explícita de estado). Para um toggle, o corpo pode ser omitido.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": {
        \"item_id\": \"{item_id}\",
        \"object_fav_name\": \"{object_fav_name}\",
        \"is_favorited_by_user\": true, // Novo estado
        \"favorites_count\": 124 // Novo contador total de favoritos para o item
      }
    }
```

```json
    {
      \"data\": {
        \"item_id\": \"{item_id}\",
        \"object_fav_name\": \"{object_fav_name}\",
        \"is_favorited_by_user\": true // ou false
      }
    }
```

```json
    {
      \"data\": [
        {
          \"profile_id\": 789,
          \"fullname\": \"Jane Favoriter\",
          \"avatar_url\": \"/path/to/jane_avatar.jpg\",
          \"favorited_at_timestamp\": 1680001111
        }
        // ... outros usuários
      ],
      \"pagination\": { ... }
    }
```

```json
    {
      \"data\": [
        {
          \"item_id\": 789, // ID do item de conteúdo favoritado
          \"favorited_at_timestamp\": 1680001111,
          // Detalhes resumidos do item_id (título, imagem, link) podem ser incluídos aqui.
          // Exemplo, se o item for um perfil:
          \"item_details\": {
              \"type\": \"bx_persons\", // Para o cliente saber como renderizar/linkar
              \"fullname\": \"John Doe Favorited\",
              \"uri_slug\": \"john-doe-favorited\",
              \"main_picture_url\": \"/path/to/john_avatar.jpg\"
          }
        }
        // ... outros itens favoritados
      ],
      \"pagination\": { ... }
    }
```

```json
    {
      \"data\": {
        \"item_id\": \"{item_id}\",
        \"object_fav_name\": \"{object_fav_name}\",
        \"favorites_count\": 124
      }
    }
```

*   **Erros Comuns:**
    *   `401 Unauthorized`: Usuário não autenticado.
    *   `403 Forbidden`: Se `is_undo = false` e o usuário tenta desfavoritar, ou outras restrições de ACL.
    *   `404 Not Found`: Objeto de favorito ou item não encontrado.
*   **Lógica do Backend (Controller):**
    1.  Extrair `author_profile_id` do JWT.
    2.  Chamar `FavoritesRepo.get_favorite_system_config/1`.
    3.  Verificar `config.is_on`.
    4.  Chamar `FavoritesRepo.is_item_favorited_by_user/3`.
    5.  Se já favoritado:
        *   Se `config.is_undo == true`, chamar `FavoritesRepo.remove_favorite/3`.
        *   Senão, retornar erro ou status inalterado.
    6.  Se não favoritado:
        *   Chamar `FavoritesRepo.add_favorite/3`.
    7.  Obter a nova contagem de favoritos para o item.
    8.  Retornar o novo estado.

### 2. Verificar se um Item é Favorito do Usuário Logado

*   **Endpoint:** `GET /favorites/object/{object_fav_name}/item/{item_id}/status`
*   **Status:** Protegido
*   **Descrição:** Verifica se o item especificado foi favoritado pelo usuário autenticado.
*   **Parâmetros de URL:**
    *   `{object_fav_name}`: Nome do objeto de favorito.
    *   `{item_id}`: ID do item de conteúdo.
*   **Resposta de Sucesso (200 OK):**

*   **Lógica do Backend (Controller):**
    1.  Extrair `author_profile_id` do JWT.
    2.  Chamar `FavoritesRepo.is_item_favorited_by_user/3`.

### 3. Listar Usuários que Favoritaram um Item

*   **Endpoint:** `GET /favorites/object/{object_fav_name}/item/{item_id}/users`
*   **Status:** Público (se `is_public = true` na config do objeto) ou Protegido (Admin/Dono do item)
*   **Descrição:** Retorna uma lista paginada de usuários que favoritaram o item especificado.
*   **Parâmetros de URL:**
    *   `{object_fav_name}`: Nome do objeto de favorito.
    *   `{item_id}`: ID do item de conteúdo.
*   **Query Parameters:**
    *   `page=1`, `per_page=20`
*   **Resposta de Sucesso (200 OK):**

*   **Erros Comuns:**
    *   `403 Forbidden`: Se a lista não for pública e o usuário não tiver permissão para vê-la.
    *   `404 Not Found`: Objeto de favorito ou item não encontrado.
*   **Lógica do Backend (Controller):**
    1.  Verificar permissões de acesso a esta lista (baseado em `config.is_public` e ACL do usuário).
    2.  Chamar `FavoritesRepo.list_users_who_favorited_item/3`.

### 4. Listar Itens Favoritados pelo Usuário Logado (para um tipo de objeto)

*   **Endpoint:** `GET /favorites/object/{object_fav_name}/my-favorites`
*   **Status:** Protegido
*   **Descrição:** Retorna uma lista paginada dos itens (de um tipo específico `object_fav_name`) que foram favoritados pelo usuário autenticado.
*   **Parâmetros de URL:**
    *   `{object_fav_name}`: Nome do objeto de favorito.
*   **Query Parameters:**
    *   `page=1`, `per_page=20`
*   **Resposta de Sucesso (200 OK):**

*   **Lógica do Backend (Controller):**
    1.  Extrair `author_profile_id` do JWT.
    2.  Chamar `FavoritesRepo.list_items_favorited_by_user/3`.
    3.  O Repo pode, opcionalmente, tentar fazer JOINs ou chamadas adicionais para enriquecer os `item_details` com informações básicas do `item_id`. Isso depende da complexidade e se os `trigger_table` / `trigger_field_id` estão bem definidos e se o tipo de item é homogêneo para um `object_fav_name`.

### 5. Obter Contagem de Favoritos para um Item

*   **Endpoint:** `GET /favorites/object/{object_fav_name}/item/{item_id}/count`
*   **Status:** Público
*   **Descrição:** Retorna o número total de vezes que um item foi favoritado.
*   **Resposta de Sucesso (200 OK):**

*   **Lógica do Backend (Controller):**
    1.  Chamar `FavoritesRepo.get_favorites_count_for_item/2`.

### Considerações:

*   **Toggle vs. Métodos Separados:** O endpoint de \"toggle\" é conveniente, mas ter `POST /favorites/.../item/{item_id}` (para favoritar) e `DELETE /favorites/.../item/{item_id}/my-favorite` (para desfavoritar) também é uma abordagem RESTful válida e pode ser mais explícita.
*   **Detalhes do Item em Listas de Favoritos:** Ao listar itens favoritados por um usuário, decidir quantos detalhes de cada item retornar na API é importante. Retornar apenas IDs pode exigir que o cliente faça muitas chamadas subsequentes. Retornar detalhes resumidos é um bom equilíbrio.
*   **Atualização de Contadores:** O `FavoritesRepo` deve garantir que o contador na `TriggerTable` seja atualizado corretamente.