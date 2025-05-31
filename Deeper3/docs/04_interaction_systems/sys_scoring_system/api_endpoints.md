# Documentação Deeper: Endpoints da API para Sistema de Scores Genérico

Este documento especifica os endpoints RESTful da API \"Deeper\" para interagir com o sistema de scores (upvote/downvote) genérico. Estes endpoints permitem obter a pontuação de um item e permitir que usuários submetam scores.

## Convenções Gerais:

*   **Base URL:** `/api/v1/scores`
*   **Identificadores:**
    *   `{object_score_name}`: O nome do \"objeto de score\" (de `sys_objects_score.Name`, ex: `bx_persons_scores`, `bx_posts_scores`). Identifica qual sistema de score está sendo usado.
    *   `{item_id}`: O ID do item de conteúdo principal que está sendo pontuado.
*   **Autenticação:** A submissão de scores (POST) é protegida. A leitura de scores é pública.
*   **Formato de Resposta:** JSON.
*   **Códigos de Status e Erros:** Conforme `docs/00_core_concepts/api_design_conventions.md`.

## Endpoints

### 1. Obter Pontuação de um Item

*   **Endpoint:** `GET /scores/object/{object_score_name}/item/{item_id}`
*   **Status:** Público
*   **Descrição:** Retorna a pontuação agregada (upvotes, downvotes, score total) para um item de conteúdo específico e o score do usuário logado (se houver e se autenticado).
*   **Parâmetros de URL:**
    *   `{object_score_name}`: Nome do objeto de score.
    *   `{item_id}`: ID do item de conteúdo.
*   **Cabeçalhos da Requisição (Opcional):**
    *   `Authorization: Bearer <jwt_token>`: Se fornecido, o backend tentará buscar o score específico do usuário logado.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": {
        \"item_id\": \"{item_id}\",
        \"object_score_name\": \"{object_score_name}\",
        \"up_votes\": 80,
        \"down_votes\": 15,
        \"total_score\": 65, // (up_votes - down_votes)
        \"config\": { // Informações da configuração do objeto de score
            \"is_undo_allowed\": true // se config.IsUndo == 1
        },
        \"user_score\": { // Presente apenas se o usuário estiver autenticado e tiver pontuado
          \"type\": \"up\", // \"up\" ou \"down\"
          \"scored_at_timestamp\": 1679998888
        } // ou null
      }
    }
```

```json
    {
      \"type\": \"up\" // ou \"down\"
    }
```

```json
    {
      \"data\": {
        \"item_id\": \"{item_id}\",
        \"object_score_name\": \"{object_score_name}\",
        \"up_votes\": 81,
        \"down_votes\": 15,
        \"total_score\": 66,
        \"config\": { ... },
        \"user_score\": {
          \"type\": \"up\",
          \"scored_at_timestamp\": 1680000000
        }, // pode ser null se o score foi removido (toggle off)
        \"message\": \"Score registrado com sucesso.\" // Opcional
      }
    }
```

```json
    {
      \"data\": {
        \"item_id\": \"{item_id}\",
        \"object_score_name\": \"{object_score_name}\",
        \"up_votes\": 80,
        \"down_votes\": 15,
        \"total_score\": 65,
        \"config\": { ... },
        \"user_score\": null,
        \"message\": \"Score removido com sucesso.\" // Opcional
      }
    }
```

*   **Erros Comuns:**
    *   `404 Not Found`: Se o `{object_score_name}` não existir.
*   **Lógica do Backend (Controller):**
    1.  Extrair `user_profile_id` do JWT, se presente.
    2.  Chamar `ScoringRepo.get_item_score/3` com `object_score_name`, `item_id`, e `user_profile_id`.
    3.  Formatar a resposta.

### 2. Submeter/Alterar um Score para um Item

*   **Endpoint:** `POST /scores/object/{object_score_name}/item/{item_id}`
*   **Status:** Protegido
*   **Descrição:** Permite que um usuário autenticado submeta, altere ou remova (se `is_undo` for true e o mesmo score for enviado novamente) seu score para um item de conteúdo.
*   **Parâmetros de URL:**
    *   `{object_score_name}`: Nome do objeto de score.
    *   `{item_id}`: ID do item de conteúdo.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK ou 201 Created):** Retorna o novo estado da pontuação do item (similar à resposta do `GET`).

*   **Erros Comuns:**
    *   `400 Bad Request`: `type` do score faltando ou inválido.
    *   `401 Unauthorized`: Usuário não autenticado.
    *   `403 Forbidden`: Usuário não tem permissão para pontuar, ou `is_undo = false` e tenta alterar, ou timeout não expirou.
    *   `404 Not Found`: Objeto de score ou item não encontrado.
*   **Lógica do Backend (Controller):**
    1.  Extrair `author_profile_id` e `author_nip_integer` do JWT e da requisição.
    2.  Validar `score_type` no corpo da requisição.
    3.  Chamar `ScoringRepo.cast_score/5` com `object_score_name`, `item_id`, `author_profile_id`, `author_nip_integer`, e `score_type`.
    4.  Formatar e retornar a resposta com o novo estado da pontuação.

### 3. (Opcional explícito) Remover Score de um Item

*Este endpoint é opcional se a lógica de \"toggle off\" estiver bem implementada no endpoint `POST` quando `is_undo = 1`.*

*   **Endpoint:** `DELETE /scores/object/{object_score_name}/item/{item_id}/my-score`
*   **Status:** Protegido
*   **Descrição:** Permite que um usuário autenticado remova explicitamente seu score de um item, se a configuração do objeto de score (`is_undo = 1`) permitir.
*   **Resposta de Sucesso (200 OK):** Retorna o estado atualizado da pontuação do item (com `user_score: null`).

*   **Erros Comuns:**
    *   `403 Forbidden`: Se `is_undo = 0` ou o usuário não tinha um score para remover.
    *   `404 Not Found`: Objeto de score ou item não encontrado.
*   **Lógica do Backend (Controller):**
    1.  Extrair `author_profile_id` do JWT.
    2.  Chamar `ScoringRepo.remove_score/3` com `object_score_name`, `item_id`, e `author_profile_id`.
    3.  Formatar e retornar a resposta.

### Considerações:

*   **Lógica de Toggle:** A implementação do `ScoringRepo.cast_score/5` deve lidar inteligentemente com o toggle:
    *   Se o usuário clica em \"up\" e não havia score: adiciona \"up\".
    *   Se o usuário clica em \"up\" e já era \"up\" (e `is_undo` é true): remove o score.
    *   Se o usuário clica em \"up\" e era \"down\" (e `is_undo` é true ou timeout permite): muda para \"up\".
*   **Atualização de Contadores:** O `ScoringRepo` é responsável por atualizar os contadores na `table_main` e na `TriggerTable` (ex: `bx_persons_data.score`, `sc_up`, `sc_down`) após cada score válido.