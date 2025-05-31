# Documentação Deeper: Endpoints da API para Sistema de Votos/Avaliações

Este documento especifica os endpoints RESTful da API \"Deeper\" para interagir com o sistema de votos/avaliações genérico. Estes endpoints permitem obter a avaliação de um item e permitir que usuários votem.

## Convenções Gerais:

*   **Base URL:** `/api/v1/ratings` (Usando \"ratings\" como um termo comum para votos/avaliações)
*   **Identificadores:**
    *   `{object_vote_name}`: O nome do \"objeto de voto\" (de `sys_objects_vote.Name`, ex: `bx_persons_ratings`, `bx_gallery_photo_ratings`). Identifica qual sistema de votação está sendo usado.
    *   `{item_id}`: O ID do item de conteúdo principal que está sendo votado/avaliado.
*   **Autenticação:** A submissão de votos (POST) é protegida. A leitura de avaliações é pública.
*   **Formato de Resposta:** JSON.
*   **Códigos de Status e Erros:** Conforme `docs/00_core_concepts/api_design_conventions.md`.

## Endpoints

### 1. Obter Avaliação de um Item

*   **Endpoint:** `GET /ratings/object/{object_vote_name}/item/{item_id}`
*   **Status:** Público
*   **Descrição:** Retorna a avaliação agregada (média, contagem de votos) para um item de conteúdo específico e o voto do usuário logado (se houver e se autenticado).
*   **Parâmetros de URL:**
    *   `{object_vote_name}`: Nome do objeto de voto.
    *   `{item_id}`: ID do item de conteúdo.
*   **Cabeçalhos da Requisição (Opcional):**
    *   `Authorization: Bearer <jwt_token>`: Se fornecido, o backend tentará buscar o voto específico do usuário logado.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": {
        \"item_id\": \"{item_id}\",
        \"object_vote_name\": \"{object_vote_name}\",
        \"average_rating\": 4.25, // pode ser null se não houver votos
        \"total_votes\": 100,
        \"config\": { // Informações da configuração do objeto de voto
            \"min_value\": 1,
            \"max_value\": 5,
            \"is_undo_allowed\": true // se config.IsUndo == 1
        },
        \"user_vote\": { // Presente apenas se o usuário estiver autenticado e tiver votado
          \"value\": 5,
          \"voted_at_timestamp\": 1679998888
        } // ou null
      }
    }
```

```json
    {
      \"value\": 4 // O valor do voto, deve estar entre MinValue e MaxValue da configuração
    }
```

```json
    {
      \"data\": {
        \"item_id\": \"{item_id}\",
        \"object_vote_name\": \"{object_vote_name}\",
        \"average_rating\": 4.28,
        \"total_votes\": 101,
        \"config\": { ... },
        \"user_vote\": {
          \"value\": 4,
          \"voted_at_timestamp\": 1680000000
        },
        \"message\": \"Voto registrado com sucesso.\" // Opcional
      }
    }
```

```json
    {
      \"data\": {
        \"item_id\": \"{item_id}\",
        \"object_vote_name\": \"{object_vote_name}\",
        \"average_rating\": 4.20,
        \"total_votes\": 99,
        \"config\": { ... },
        \"user_vote\": null,
        \"message\": \"Voto removido com sucesso.\" // Opcional
      }
    }
```

*   **Erros Comuns:**
    *   `404 Not Found`: Se o `{object_vote_name}` não existir ou o `{item_id}` não tiver um registro de votação (embora possa retornar dados com contagem zero).
*   **Lógica do Backend (Controller):**
    1.  Extrair `user_profile_id` do JWT, se presente.
    2.  Chamar `VotingRepo.get_item_rating/3` com `object_vote_name`, `item_id`, e `user_profile_id`.
    3.  Formatar a resposta.

### 2. Submeter/Atualizar um Voto para um Item

*   **Endpoint:** `POST /ratings/object/{object_vote_name}/item/{item_id}`
*   **Status:** Protegido
*   **Descrição:** Permite que um usuário autenticado submeta ou atualize seu voto para um item de conteúdo.
*   **Parâmetros de URL:**
    *   `{object_vote_name}`: Nome do objeto de voto.
    *   `{item_id}`: ID do item de conteúdo.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK ou 201 Created):** Retorna o novo estado da avaliação do item (similar à resposta do `GET`).

*   **Erros Comuns:**
    *   `400 Bad Request`: Valor do voto faltando ou inválido (fora do range Min/Max).
    *   `401 Unauthorized`: Usuário não autenticado.
    *   `403 Forbidden`: Usuário não tem permissão para votar neste objeto (se houver ACL específico para votar), ou tentou alterar voto quando `IsUndo = 0`, ou timeout não expirou.
    *   `404 Not Found`: Objeto de voto ou item não encontrado.
    *   `409 Conflict`: (Opcional) Se o usuário tenta votar exatamente com o mesmo valor que já votou e nada muda.
*   **Lógica do Backend (Controller):**
    1.  Extrair `author_profile_id` e `author_nip_integer` (IP convertido) do JWT e da requisição.
    2.  Validar `vote_value` no corpo da requisição.
    3.  Chamar `VotingRepo.cast_vote/5` com `object_vote_name`, `item_id`, `author_profile_id`, `author_nip_integer`, e `vote_value`.
    4.  Formatar e retornar a resposta com o novo estado da avaliação.

### 3. (Opcional) Remover Voto de um Item

*   **Endpoint:** `DELETE /ratings/object/{object_vote_name}/item/{item_id}/my-vote`
*   **Status:** Protegido
*   **Descrição:** Permite que um usuário autenticado remova seu voto de um item, se a configuração do objeto de voto (`IsUndo = 1`) permitir.
*   **Resposta de Sucesso (200 OK):** Retorna o estado atualizado da avaliação do item (com `user_vote: null`).

*   **Erros Comuns:**
    *   `403 Forbidden`: Se `IsUndo = 0` ou o usuário não tinha um voto para remover.
    *   `404 Not Found`: Objeto de voto ou item não encontrado.
*   **Lógica do Backend (Controller):**
    1.  Extrair `author_profile_id` do JWT.
    2.  Chamar `VotingRepo.remove_vote/3` com `object_vote_name`, `item_id`, e `author_profile_id`.
    3.  Formatar e retornar a resposta.

### Considerações:

*   **Nomes de Tabela Dinâmicos:** O `{object_vote_name}` é usado pelo `VotingRepo` para encontrar a configuração em `sys_objects_vote` e, a partir daí, os nomes das tabelas `TableMain` e `TableTrack`.
*   **Atualização de Contadores:** O `VotingRepo` é responsável por atualizar os contadores na `TableMain` e na `TriggerTable` (ex: `bx_persons_data.rate`, `bx_persons_data.votes`) após cada voto válido.
*   **Feedback ao Usuário:** A resposta da API após um `POST` ou `DELETE` deve incluir o estado atualizado da avaliação para que o cliente possa atualizar a UI sem precisar fazer uma nova chamada `GET`.