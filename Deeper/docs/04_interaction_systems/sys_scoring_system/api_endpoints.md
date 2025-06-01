# Documentação Deeper: Endpoints da API para o Sistema de Pontuações

Este documento especifica os endpoints RESTful para interagir com o sistema genérico de \"Pontuações\" (upvote/downvote) no \"Deeper\".

**Convenções Gerais:**
*   Endpoints sob `/api/v1`.
*   Respostas e corpos de requisição em JSON.
*   Autenticação JWT obrigatória para registrar votos de score.
*   Códigos de status HTTP e formatos de erro seguem as [Convenções de Design da API](../../00_core_concepts/api_design_conventions.md).
*   ACL será aplicado (ex: quem pode votar, não votar no próprio conteúdo).

**Parâmetros de Path Genéricos:**

*   `{resource_type}`: Identifica o tipo de recurso principal (ex: `articles`, `comments`). Usado para determinar o `system_name`.
*   `{resource_id}`: O ID do recurso principal específico que está sendo pontuado.

---

## 1. Pontuar um Recurso (`/{resource_type}/{resource_id}/score`)

Este endpoint permite dar um upvote, downvote ou remover um voto de score.

### 1.1. Registrar/Alterar/Remover Voto de Score em um Recurso

*   **Endpoint:** `POST /{resource_type}/{resource_id}/score`
*   **Autenticação:** Requerida (JWT).
*   **Descrição:**
    *   Se o usuário não votou, registra o voto (`up` ou `down`).
    *   Se o usuário já votou e clica no mesmo tipo de voto, remove o voto (undo).
    *   Se o usuário já votou e clica no tipo oposto, altera o voto.
*   **Corpo da Requisição (JSON):**

```json
    {
      \"type\": \"up\" // ou \"down\"
    }
```

```json
    {
      \"data\": {
        \"system_name\": \"deeper_articles_score\", // Exemplo
        \"object_id\": \"{resource_id}\",
        \"voter_profile_id\": 15,
        \"current_vote_type\": \"up\", // ou \"down\", ou null se o voto foi removido
        \"voted_at\": 1678893000, // Se um voto foi registrado/alterado
        \"new_aggregates\": { // Agregados atualizados para o objeto pontuado
          \"score_up_count\": 55,
          \"score_down_count\": 10,
          \"score_net\": 45
        }
      }
    }
```

```json
    {
      \"data\": {
        \"system_name\": \"deeper_articles_score\",
        \"object_id\": \"{resource_id}\",
        \"aggregates\": {
          \"score_up_count\": 55,
          \"score_down_count\": 10,
          \"score_net\": 45
        },
        \"user_vote\": { // Presente e preenchido se o usuário estiver autenticado e já votou
          \"type\": \"up\", // \"up\" ou \"down\"
          \"voted_at\": 1678893000
        } // ou null se não autenticado ou não votou
      }
    }
```

*   **Resposta de Sucesso (200 OK ou 201 Created):**

*   **Respostas de Erro:**
    *   `400 Bad Request`: `type` ausente ou inválido.
    *   `401 Unauthorized`: Não autenticado.
    *   `403 Forbidden`: Usuário não tem permissão para votar neste item.
    *   `404 Not Found`: Recurso principal (`{resource_id}`) não encontrado.
    *   `500 Internal Server Error`.
*   **Lógica de Backend (Controller):**
    1.  Extrair `voter_profile_id` do JWT.
    2.  Mapear `{resource_type}` para o `system_name` apropriado.
    3.  Verificar permissão ACL para votar.
    4.  Validar o campo `type` (\"up\" ou \"down\").
    5.  Chamar `Deeper.InteractionSystems.ScoringRepo.cast_score_vote/5` com `system_name`, `{resource_id}`, `voter_profile_id`, `type` (convertido para atom `:up` ou `:down`), e opcionalmente IP.
    6.  A resposta do `ScoringRepo` (`new_aggregates`) é usada para construir a resposta da API.
    7.  Precisamos também buscar o estado atual do voto do usuário (`get_user_score_vote`) para preencher `current_vote_type` na resposta.

### 1.2. Obter Informações de Score para um Recurso

*   **Endpoint:** `GET /{resource_type}/{resource_id}/score`
*   **Autenticação:** Opcional. Se autenticado, inclui o voto de score do usuário atual.
*   **Descrição:** Retorna os agregados de score para um recurso e, se o usuário estiver autenticado, seu voto pessoal.
*   **Resposta de Sucesso (200 OK):**