# Documentação Deeper: Endpoints da API para o Sistema de Votos

Este documento especifica os endpoints RESTful para interagir com o sistema genérico de votos/avaliações \"Deeper\". Os votos são geralmente aplicados a um recurso principal específico (ex: artigo, perfil).

**Convenções Gerais:**
*   Endpoints sob `/api/v1`.
*   Respostas e corpos de requisição em JSON.
*   Autenticação JWT para registrar ou remover votos.
*   Códigos de status HTTP e formatos de erro seguem as [Convenções de Design da API](../../00_core_concepts/api_design_conventions.md).
*   ACL será aplicado para determinar quem pode votar (ex: não pode votar em seu próprio conteúdo, limites de votação por nível).

**Parâmetros de Path Genéricos:**

*   `{resource_type}`: Identifica o tipo de recurso principal (ex: `articles`, `persons`). Este será usado para determinar o `system_name` do sistema de votação.
*   `{resource_id}`: O ID do recurso principal específico que está sendo votado.

---

## 1. Votos em um Recurso (`/{resource_type}/{resource_id}/vote`)

### 1.1. Registrar ou Atualizar Voto em um Recurso

*   **Endpoint:** `POST /{resource_type}/{resource_id}/vote`
*   **Autenticação:** Requerida (JWT).
*   **Descrição:** Permite que um usuário autenticado registre um novo voto ou atualize seu voto existente para um recurso específico.
*   **Corpo da Requisição (JSON):**

```json
    {
      \"value\": 4 // O valor do voto (ex: 1-5 para estrelas)
      // \"ip_address\": \"123.123.123.123\" // Opcional, pode ser capturado pelo servidor
    }
```

```json
    {
      \"data\": {
        \"system_name\": \"deeper_articles_rating\", // Exemplo
        \"object_id\": \"{resource_id}\",
        \"voter_profile_id\": 15, // ID do perfil do votante
        \"value\": 4, // O voto registrado/atualizado
        \"voted_at\": 1678890000,
        \"new_aggregates\": { // Agregados atualizados para o objeto votado
          \"votes_count\": 101,
          \"votes_sum\": 405, // Se aplicável
          \"rate\": 4.01
        }
      }
    }
```

```json
    {
      \"data\": {
        \"message\": \"Voto removido com sucesso.\",
        \"new_aggregates\": { // Agregados atualizados para o objeto
          \"votes_count\": 100,
          \"votes_sum\": 401,
          \"rate\": 4.01
        }
      }
    }
```

```json
    {
      \"data\": {
        \"system_name\": \"deeper_articles_rating\",
        \"object_id\": \"{resource_id}\",
        \"aggregates\": {
          \"votes_count\": 101,
          \"votes_sum\": 405, // Se aplicável e retornado pelo repo
          \"rate\": 4.01
        },
        \"user_vote\": { // Presente e preenchido se o usuário estiver autenticado e já votou
          \"value\": 4,
          \"voted_at\": 1678890000
        } // ou null se não autenticado ou não votou
      }
    }
```

*   **Resposta de Sucesso (200 OK ou 201 Created):**

*   **Respostas de Erro:**
    *   `400 Bad Request`: Valor do voto ausente, inválido (fora da faixa permitida para o `system_name`) ou tipo incorreto.
    *   `401 Unauthorized`: Não autenticado.
    *   `403 Forbidden`: Usuário não tem permissão para votar neste item (ex: votar em seu próprio conteúdo, limite de ACL atingido).
    *   `404 Not Found`: Recurso principal (`{resource_id}`) não encontrado.
    *   `500 Internal Server Error`.
*   **Lógica de Backend (Controller):**
    1.  Extrair `voter_profile_id` do JWT.
    2.  Mapear `{resource_type}` para o `system_name` apropriado (ex: `articles` -> `\"deeper_articles_rating\"`).
    3.  Verificar permissão ACL para votar neste `system_name` / `object_id`.
    4.  Validar o campo `value` (ex: entre 1 e 5, se for um sistema de 5 estrelas). Esta faixa de validação pode ser configurável por `system_name`.
    5.  (Opcional) Obter o IP do cliente.
    6.  Chamar `Deeper.InteractionSystems.VotingRepo.cast_vote/5` com `system_name`, `{resource_id}`, `voter_profile_id`, `value` e `ip_address`.
    7.  Retornar os detalhes do voto e os novos agregados.

### 1.2. Remover Voto de um Recurso

*   **Endpoint:** `DELETE /{resource_type}/{resource_id}/vote`
*   **Autenticação:** Requerida (JWT).
*   **Descrição:** Permite que um usuário autenticado remova seu voto previamente registrado para um recurso específico.
*   **Resposta de Sucesso (200 OK):**

    Ou `204 No Content` se nenhum corpo for retornado.
*   **Respostas de Erro:**
    *   `401 Unauthorized`.
    *   `403 Forbidden`.
    *   `404 Not Found`: Recurso principal ou voto do usuário não encontrado.
*   **Lógica de Backend:**
    1.  Extrair `voter_profile_id` do JWT.
    2.  Mapear `{resource_type}` para o `system_name`.
    3.  Verificar permissão ACL.
    4.  Chamar `Deeper.InteractionSystems.VotingRepo.remove_vote/3`.
    5.  Retornar mensagem de sucesso e os novos agregados.

### 1.3. Obter Informações de Voto para um Recurso

*   **Endpoint:** `GET /{resource_type}/{resource_id}/vote`
*   **Autenticação:** Opcional. Se autenticado, pode incluir o voto do usuário atual.
*   **Descrição:** Retorna os agregados de votos (média, contagem) para um recurso e, se o usuário estiver autenticado, seu voto pessoal.
*   **Resposta de Sucesso (200 OK):**