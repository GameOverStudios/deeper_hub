# Documentação Deeper: Endpoints da API para o Sistema de Reações

Este documento especifica os endpoints RESTful para interagir com o sistema genérico de \"Reações\" (ex: Like, Love, Haha) no \"Deeper\".

**Convenções Gerais:**
*   Endpoints sob `/api/v1`.
*   Respostas e corpos de requisição em JSON.
*   Autenticação JWT obrigatória para registrar/remover reações.
*   Códigos de status HTTP e formatos de erro seguem as [Convenções de Design da API](../../00_core_concepts/api_design_conventions.md).
*   ACL será aplicado (ex: quem pode reagir).

**Parâmetros de Path Genéricos:**

*   `{resource_type}`: Identifica o tipo de recurso principal (ex: `articles`, `comments`, `persons`). Usado para determinar o `system_name`.
*   `{resource_id}`: O ID do recurso principal específico que está recebendo a reação.

---

## 1. Reagir a um Recurso (`/{resource_type}/{resource_id}/reaction`)

Este endpoint permite adicionar, alterar ou remover uma reação a um recurso.

### 1.1. Adicionar/Alterar/Remover Reação a um Recurso

*   **Endpoint:** `POST /{resource_type}/{resource_id}/reaction`
*   **Autenticação:** Requerida (JWT).
*   **Descrição:**
    *   Se o usuário não reagiu, registra a nova reação.
    *   Se o usuário já reagiu com o mesmo `reaction_type_key`, remove a reação (undo).
    *   Se o usuário já reagiu com um `reaction_type_key` diferente, altera para a nova reação.
*   **Corpo da Requisição (JSON):**

```json
    {
      \"reaction_type_key\": \"like\" // Ex: \"like\", \"love\", \"haha\", \"wow\", \"sad\", \"angry\"
    }
```

```json
    {
      \"data\": {
        \"system_name\": \"deeper_articles_reactions\", // Exemplo
        \"object_id\": \"{resource_id}\",
        \"reactor_profile_id\": 15,
        \"current_reaction\": \"like\", // ou null se a reação foi removida
        \"reacted_at\": 1678894000, // Se uma reação foi registrada/alterada
        \"new_aggregates\": { // Agregados atualizados para o objeto
          \"like\": 55, // Contagem para cada tipo de reação
          \"love\": 12,
          \"haha\": 3,
          \"total_reactions\": 70 // Contagem total de todas as reações
        }
      }
    }
```

```json
    {
      \"data\": {
        \"status\": \"reaction_removed\",
        \"new_aggregates\": {
          \"like\": 54,
          \"love\": 12,
          \"haha\": 3,
          \"total_reactions\": 69
        }
      }
    }
```

```json
    {
      \"data\": {
        \"system_name\": \"deeper_articles_reactions\",
        \"object_id\": \"{resource_id}\",
        \"aggregates\": { // Contagem para cada tipo de reação
          \"like\": 55,
          \"love\": 12,
          \"haha\": 3,
          \"wow\": 1,
          \"sad\": 0,
          \"angry\": 1,
          \"total_reactions\": 72
        },
        \"user_reaction\": { // Presente e preenchido se o usuário estiver autenticado e já reagiu
          \"reaction_type_key\": \"like\",
          \"reacted_at\": 1678894000
        } // ou null se não autenticado ou não reagiu
      }
    }
```

```json
    {
      \"data\": [
        {
          \"reaction_key\": \"like\",
          \"title\": \"Curtir\", // Traduzido ou valor de title_lkey
          \"icon_class\": \"bxi-thumb-up\",
          \"color_hex\": \"#2078F4\" // Opcional
        },
        {
          \"reaction_key\": \"love\",
          \"title\": \"Amei\",
          \"icon_class\": \"bxi-heart\",
          \"color_hex\": \"#F44336\"
        }
        // ... mais tipos de reação ...
      ]
    }
```

*   **Resposta de Sucesso (200 OK ou 201 Created):**

*   **Respostas de Erro:**
    *   `400 Bad Request`: `reaction_type_key` ausente ou inválido.
    *   `401 Unauthorized`: Não autenticado.
    *   `403 Forbidden`: Usuário não tem permissão para reagir.
    *   `404 Not Found`: Recurso principal (`{resource_id}`) não encontrado.
    *   `500 Internal Server Error`.
*   **Lógica de Backend (Controller):**
    1.  Extrair `reactor_profile_id` do JWT.
    2.  Mapear `{resource_type}` para o `system_name` apropriado.
    3.  Verificar permissão ACL.
    4.  Validar o `reaction_type_key` contra os tipos permitidos (pode vir de `ReactionsRepo.list_reaction_types/0`).
    5.  Chamar `Deeper.InteractionSystems.ReactionsRepo.cast_reaction/5`.
    6.  A resposta do `ReactionsRepo` (`new_aggregates`) é usada.
    7.  Buscar a reação atual do usuário (`get_user_reaction`) para preencher `current_reaction`.

### 1.2. Remover Reação de um Recurso (Alternativa Explícita)

Embora `POST` com o mesmo tipo de reação já remova, um endpoint `DELETE` pode ser mais semanticamente claro para remoção.

*   **Endpoint:** `DELETE /{resource_type}/{resource_id}/reaction`
*   **Autenticação:** Requerida (JWT).
*   **Descrição:** Remove a reação do usuário autenticado para um recurso específico, se houver.
*   **Resposta de Sucesso (200 OK ou 204 No Content):**

*   **Lógica de Backend:**
    1.  Extrair `reactor_profile_id` do JWT.
    2.  Mapear `{resource_type}` para o `system_name`.
    3.  Chamar `Deeper.InteractionSystems.ReactionsRepo.remove_reaction/3`.
    4.  Retornar o status e os novos agregados.

### 1.3. Obter Informações de Reações para um Recurso

*   **Endpoint:** `GET /{resource_type}/{resource_id}/reactions` (Nota: plural \"reactions\" aqui para distinguir de uma ação singular de \"reaction\")
*   **Autenticação:** Opcional. Se autenticado, inclui a reação do usuário atual.
*   **Descrição:** Retorna os agregados de reações (contagem por tipo) para um recurso e, se o usuário estiver autenticado, sua reação pessoal.
*   **Resposta de Sucesso (200 OK):**

*   **Lógica de Backend (Controller):**
    1.  Mapear `{resource_type}` para o `system_name`.
    2.  Chamar `Deeper.InteractionSystems.ReactionsRepo.get_reaction_aggregates_for_object/2`.
    3.  Se o usuário estiver autenticado:
        *   Extrair `reactor_profile_id` do JWT.
        *   Chamar `Deeper.InteractionSystems.ReactionsRepo.get_user_reaction/3`.
        *   Incluir o resultado em `user_reaction`.
    4.  Construir e retornar a resposta.

---

## 2. Tipos de Reação Disponíveis (`/reaction-types`)

### 2.1. Listar Tipos de Reação

*   **Endpoint:** `GET /reaction-types`
*   **Autenticação:** Nenhuma (público).
*   **Descrição:** Retorna uma lista dos tipos de reação disponíveis que os usuários podem selecionar.
*   **Query Parameters:**
    *   `lang={lang_code}` (opcional, para obter `title` traduzido se `title_lkey` for usado).
*   **Resposta de Sucesso (200 OK):**