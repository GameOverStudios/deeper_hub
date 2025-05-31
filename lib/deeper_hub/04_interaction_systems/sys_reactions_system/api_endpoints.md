# Documentação Deeper: Endpoints da API para Sistema de Reações Genérico

Este documento especifica os endpoints RESTful da API \"Deeper\" para interagir com o sistema de reações genérico. Estes endpoints permitem obter o sumário de reações de um item e permitir que usuários adicionem/alterem/removam suas reações.

## Convenções Gerais:

*   **Base URL:** `/api/v1/reactions`
*   **Identificadores:**
    *   `{object_reaction_name}`: O nome do \"objeto de reação\" (de `sys_objects_reaction.name`, ex: `bx_posts_reactions`). Identifica qual sistema de reações está sendo usado.
    *   `{item_id}`: O ID do item de conteúdo principal que está recebendo as reações.
*   **Autenticação:** A submissão de reações (POST/PUT/DELETE) é protegida. A leitura do sumário de reações é pública.
*   **Formato de Resposta:** JSON.
*   **Códigos de Status e Erros:** Conforme `docs/00_core_concepts/api_design_conventions.md`.

## Endpoints

### 1. Obter Sumário de Reações de um Item

*   **Endpoint:** `GET /reactions/object/{object_reaction_name}/item/{item_id}`
*   **Status:** Público
*   **Descrição:** Retorna o sumário das reações para um item de conteúdo específico (contagem de cada tipo de reação) e a reação do usuário logado (se houver e se autenticado).
*   **Parâmetros de URL:**
    *   `{object_reaction_name}`: Nome do objeto de reação.
    *   `{item_id}`: ID do item de conteúdo.
*   **Cabeçalhos da Requisição (Opcional):**
    *   `Authorization: Bearer <jwt_token>`: Se fornecido, o backend tentará buscar a reação específica do usuário logado.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": {
        \"item_id\": \"{item_id}\",
        \"object_reaction_name\": \"{object_reaction_name}\",
        \"reactions_summary\": { // Contagem de cada tipo de reação
          \"like\": 50,
          \"love\": 25,
          \"haha\": 10,
          \"wow\": 5,
          \"sad\": 2,
          \"angry\": 1
        },
        \"total_reactions\": 93, // Soma de todas as contagens
        \"available_reactions\": [\"like\", \"love\", \"haha\", \"wow\", \"sad\", \"angry\"], // Da config do objeto
        \"config\": {
            \"is_undo_allowed\": true
        },
        \"user_reaction\": { // Presente apenas se o usuário estiver autenticado e tiver reagido
          \"type\": \"love\",
          \"reacted_at_timestamp\": 1679998888
        } // ou null
      }
    }
```

```json
    {
      \"reaction_type\": \"love\" // O tipo da reação (ex: \"like\", \"love\", \"haha\")
    }
```

```json
    {
      \"data\": {
        \"item_id\": \"{item_id}\",
        \"object_reaction_name\": \"{object_reaction_name}\",
        \"reactions_summary\": {
          \"like\": 49, // Exemplo, se o usuário mudou de like para love
          \"love\": 26,
          \"haha\": 10
          // ...
        },
        \"total_reactions\": 93, // Pode não mudar se for uma alteração de tipo
        \"available_reactions\": [...],
        \"config\": { ... },
        \"user_reaction\": {
          \"type\": \"love\",
          \"reacted_at_timestamp\": 1680000000
        }, // pode ser null se a reação foi removida (toggle off)
        \"message\": \"Reação registrada com sucesso.\" // Opcional
      }
    }
```

```json
    {
      \"data\": [
        {
          \"profile_id\": 789,
          \"fullname\": \"Jane Reactor\",
          \"avatar_url\": \"/path/to/jane_avatar.jpg\",
          \"reacted_at_timestamp\": 1680001111
        }
        // ... outros usuários que deram esta reação
      ],
      \"pagination\": { ... }
    }
```

*   **Erros Comuns:**
    *   `404 Not Found`: Se o `{object_reaction_name}` não existir.
*   **Lógica do Backend (Controller):**
    1.  Extrair `user_profile_id` do JWT, se presente.
    2.  Chamar `ReactionsRepo.get_item_reactions_summary/3` com `object_reaction_name`, `item_id`, e `user_profile_id`.
    3.  Formatar a resposta.

### 2. Adicionar, Alterar ou Remover Reação a um Item (Toggle)

*   **Endpoint:** `POST /reactions/object/{object_reaction_name}/item/{item_id}`
*   **Status:** Protegido
*   **Descrição:** Permite que um usuário autenticado adicione uma reação, mude sua reação existente, ou remova sua reação (se clicar na mesma reação novamente e `is_undo` for true).
*   **Parâmetros de URL:**
    *   `{object_reaction_name}`: Nome do objeto de reação.
    *   `{item_id}`: ID do item de conteúdo.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK ou 201 Created):** Retorna o novo estado do sumário de reações do item e a reação do usuário (similar à resposta do `GET`).

*   **Erros Comuns:**
    *   `400 Bad Request`: `reaction_type` faltando ou inválido (não está na lista de `available_reactions` do objeto).
    *   `401 Unauthorized`: Usuário não autenticado.
    *   `403 Forbidden`: Usuário não tem permissão para reagir, ou `is_undo = false` e tenta alterar/remover.
    *   `404 Not Found`: Objeto de reação ou item não encontrado.
*   **Lógica do Backend (Controller):**
    1.  Extrair `author_profile_id` do JWT.
    2.  Validar `reaction_type` no corpo da requisição.
    3.  Chamar `ReactionsRepo.cast_reaction/4` com `object_reaction_name`, `item_id`, `author_profile_id`, e `reaction_type`.
    4.  Formatar e retornar a resposta com o novo estado das reações.

### 3. (Opcional explícito) Remover Reação de um Item

*Este endpoint é opcional se a lógica de \"toggle off\" no `POST` for suficiente e `is_undo = 1`.*

*   **Endpoint:** `DELETE /reactions/object/{object_reaction_name}/item/{item_id}/my-reaction`
*   **Status:** Protegido
*   **Descrição:** Permite que um usuário autenticado remova explicitamente sua reação de um item, se a configuração (`is_undo = 1`) permitir.
*   **Resposta de Sucesso (200 OK):** Retorna o estado atualizado do sumário de reações do item (com `user_reaction: null`).
*   **Lógica do Backend (Controller):**
    1.  Extrair `author_profile_id` do JWT.
    2.  Chamar uma função no `ReactionsRepo` como `remove_user_reaction(object_reaction_name, item_id, author_profile_id)`. Esta função interna do Repo faria o `DELETE` da `table_track` e ajustaria a `table_summary` e `TriggerTable`.

### 4. Listar Usuários que Deram uma Reação Específica a um Item

*   **Endpoint:** `GET /reactions/object/{object_reaction_name}/item/{item_id}/users-by-type/{reaction_type}`
*   **Status:** Público (ou conforme política de privacidade do módulo/item)
*   **Descrição:** Retorna uma lista paginada de usuários que deram um tipo específico de reação ao item.
*   **Parâmetros de URL:**
    *   `{object_reaction_name}`
    *   `{item_id}`
    *   `{reaction_type}` (ex: `like`, `love`)
*   **Query Parameters:**
    *   `page=1`, `per_page=20`
*   **Resposta de Sucesso (200 OK):**

*   **Lógica do Backend (Controller):**
    1.  Chamar `ReactionsRepo.list_users_who_reacted_to_item/4` com `reaction_type_filter = {reaction_type}`.

### Considerações:

*   **Lista de Reações Disponíveis:** O cliente pode precisar saber quais reações (`available_reactions`) são permitidas para um objeto antes de apresentar as opções ao usuário. Isso é retornado no endpoint `GET /reactions/object/{object_reaction_name}/item/{item_id}`.
*   **Atualização de Contadores:** O `ReactionsRepo` é responsável por atualizar os contadores na `table_summary` e na `TriggerTable`.
*   **UI/UX:** A lógica de \"toggle\" (clicar na mesma reação para remover) é comum. Se o usuário clica em uma reação diferente, a reação anterior é removida e a nova é aplicada. Isso tudo deve ser gerenciado pelo `ReactionsRepo.cast_reaction/4`.