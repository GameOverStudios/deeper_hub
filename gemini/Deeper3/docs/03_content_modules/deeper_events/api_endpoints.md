# Documentação Deeper: Endpoints da API para Módulo de Eventos

Este documento especifica os endpoints RESTful para o módulo de Eventos (`deeper_events`) do \"Deeper\".

Lembre-se das [Convenções de Design da API](../../00_core_concepts/api_design_conventions.md). Todos os endpoints abaixo estão sob o prefixo `/api/v1`.

## Eventos (`/events`)

### 1. Criar um Novo Evento

*   **`POST /events`**
*   **Autenticação:** Requerida. O `profile_id` do organizador será extraído do token JWT.
*   **Corpo da Requisição (JSON):**

```json
    {
      \"title\": \"Meetup Elixir & Phoenix de Novembro\",
      \"slug\": \"meetup-elixir-phoenix-novembro\", // Opcional, pode ser gerado
      \"description\": \"Discussão sobre as últimas novidades e networking.\",
      \"start_datetime\": 1699988400, // Unix Timestamp UTC (ex: 14 Nov 2023 19:00:00 UTC)
      \"end_datetime\": 1699999200,   // Unix Timestamp UTC (ex: 14 Nov 2023 22:00:00 UTC)
      \"timezone\": \"America/Sao_Paulo\", // Opcional
      \"location_text\": \"Escritório Central da Deeper\",
      \"location_lat\": -23.550520, // Opcional
      \"location_lng\": -46.633308, // Opcional
      \"address\": \"Rua Exemplo, 123\", // Opcional
      \"city\": \"São Paulo\", // Opcional
      \"state\": \"SP\", // Opcional
      \"country\": \"BR\", // Opcional
      \"zip_code\": \"01000-000\", // Opcional
      \"banner_file_id\": 456, // Opcional, ID de `deeper_files`
      \"visibility\": \"public\", // Opcional, default: \"public\"
      \"allow_rsvps\": true, // Opcional, default: true
      \"max_attendees\": 100, // Opcional, default: 0 (ilimitado)
      \"status\": \"active\", // Opcional, default: \"draft\" ou \"active\"
      \"category_ids\": [2, 7] // Opcional, lista de IDs de `deeper_event_categories`
    }
```

```json
    {
      \"data\": {
        \"id\": 1,
        \"profile_id\": 77,
        \"title\": \"Meetup Elixir & Phoenix de Novembro\",
        \"slug\": \"meetup-elixir-phoenix-novembro\",
        \"description\": \"Discussão sobre as últimas novidades e networking.\",
        \"start_datetime\": 1699988400,
        \"end_datetime\": 1699999200,
        \"timezone\": \"America/Sao_Paulo\",
        \"location_text\": \"Escritório Central da Deeper\",
        \"location_lat\": -23.550520,
        \"location_lng\": -46.633308,
        \"address\": \"Rua Exemplo, 123\",
        \"city\": \"São Paulo\",
        \"state\": \"SP\",
        \"country\": \"BR\",
        \"zip_code\": \"01000-000\",
        \"banner_file_id\": 456,
        \"banner_image_details\": { /* ... detalhes do arquivo ... */ }, // Se `include` implícito ou solicitado
        \"visibility\": \"public\",
        \"allow_rsvps\": 1,
        \"max_attendees\": 100,
        \"status\": \"active\",
        \"rsvps_yes_count\": 0,
        \"rsvps_maybe_count\": 0,
        \"rsvps_no_count\": 0,
        \"views\": 0,
        \"created_at\": 1699900000,
        \"updated_at\": 1699900000,
        \"organizer\": { /* ... detalhes do organizador ... */ }, // Se `include`
        \"categories\": [ /* ... lista de categorias ... */ ] // Se `include`
      }
    }
```

```json
    {
      \"data\": [
        // ... array de objetos de evento ...
      ],
      \"pagination\": { /* ... */ }
    }
```

```json
    {
      \"rsvp_status\": \"yes\", // \"yes\", \"no\", \"maybe\"
      \"comment\": \"Ansioso por este evento!\", // Opcional
      \"guests_count\": 1 // Opcional, default 0
    }
```

```json
    {
      \"data\": {
        \"event_id\": 123,
        \"profile_id\": 77,
        \"rsvp_status\": \"yes\",
        \"comment\": \"Ansioso por este evento!\",
        \"guests_count\": 1,
        \"rsvped_at\": 1699910000,
        \"updated_at\": 1699910000,
        // Pode incluir o resumo atualizado de RSVPs do evento
        \"event_rsvps_summary\": {
            \"yes_count\": 15,
            \"maybe_count\": 3,
            \"no_count\": 2
        }
      }
    }
```

```json
    {
      \"data\": [
        {
          \"profile_id\": 77,
          \"profile_details\": { \"name\": \"Participante Um\", \"avatar_url\": \"...\" }, // Se include=profile_details
          \"rsvp_status\": \"yes\",
          \"comment\": \"Presente!\",
          \"guests_count\": 0,
          \"rsvped_at\": 1699910000
        }
        // ...
      ],
      \"pagination\": { /* ... */ }
    }
```

*   **Resposta de Sucesso (201 Created):**

*   **Respostas de Erro:** `400` (validação), `401`, `403`.

### 2. Listar Eventos

*   **`GET /events`**
*   **Autenticação:** Opcional.
*   **Query Parameters:**
    *   `profile_id` (integer): Filtrar por organizador.
    *   `status` (string): Filtrar por status (ex: `active`, `past`, `cancelled`).
    *   `category_id` (integer) / `category_slug` (string).
    *   `visibility` (string).
    *   `upcoming` (boolean): Se `true`, retorna eventos com `start_datetime >= now`.
    *   `past` (boolean): Se `true`, retorna eventos com `end_datetime < now`.
    *   `date_from` (integer, Unix timestamp): Eventos que iniciam a partir desta data.
    *   `date_to` (integer, Unix timestamp): Eventos que iniciam até esta data.
    *   `location_near` (string, ex: \"lat,lng\"): Para busca por proximidade (requer implementação geoespacial).
    *   `radius` (integer, metros/km): Raio para busca `location_near`.
    *   `q` (string): Termo de busca (título, descrição, localização).
    *   `page`, `per_page`.
    *   `sort_by` (ex: `start_datetime_asc`, `created_at_desc`, `views_desc`).
    *   `include` (string CSV, ex: `organizer,categories,banner_image`).
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:** `400`.

### 3. Obter um Evento Específico

*   **`GET /events/{id_or_slug}`**
*   **Autenticação:** Opcional.
*   **Query Parameters:**
    *   `include` (string CSV, ex: `organizer,categories,banner_image,rsvps_list,rsvps_summary`).
*   **Resposta de Sucesso (200 OK):** Formato similar à resposta do `POST /events`. Se `include=rsvps_list`, pode incluir uma sub-lista de participantes.
*   **Respostas de Erro:** `401`, `403`, `404`.

### 4. Atualizar um Evento

*   **`PUT /events/{id}`** ou **`PATCH /events/{id}`**
*   **Autenticação:** Requerida (organizador ou admin).
*   **Corpo da Requisição (JSON):** Campos a serem atualizados.
*   **Resposta de Sucesso (200 OK):** Retorna o objeto de evento atualizado.
*   **Respostas de Erro:** `400`, `401`, `403`, `404`.

### 5. Excluir um Evento

*   **`DELETE /events/{id}`**
*   **Autenticação:** Requerida (organizador ou admin).
*   **Resposta de Sucesso (200 OK ou 204 No Content):**
*   **Respostas de Erro:** `401`, `403`, `404`.

## RSVPs de Eventos (`/events/{event_id}/rsvps`)

### 1. Registrar ou Atualizar RSVP para um Evento

*   **`POST /events/{event_id}/rsvps`** (Poderia ser `PUT` se considerarmos que um usuário só tem um RSVP, e esta ação o cria ou atualiza).
*   **Autenticação:** Requerida. O `profile_id` do participante virá do JWT.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK ou 201 Created):**

*   **Respostas de Erro:** `400` (status inválido, evento não permite RSVPs), `401`, `403` (ex: evento privado sem convite), `404` (evento não encontrado), `409` (ex: evento lotado, se `max_attendees` for atingido).

### 2. Listar RSVPs de um Evento

*   **`GET /events/{event_id}/rsvps`**
*   **Autenticação:** Requerida (geralmente organizador ou participantes, dependendo da visibilidade da lista de convidados).
*   **Query Parameters:**
    *   `rsvp_status` (string): Filtrar por status (`yes`, `no`, `maybe`).
    *   `page`, `per_page`.
    *   `sort_by` (ex: `rsvped_at_desc`).
    *   `include` (string CSV, ex: `profile_details`).
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:** `401`, `403`, `404`.

### 3. Obter o RSVP de um Usuário Específico para um Evento

*   **`GET /events/{event_id}/rsvps/{profile_id}`** (ou `GET /events/{event_id}/rsvps/me` para o usuário logado)
*   **Autenticação:** Requerida.
*   **Resposta de Sucesso (200 OK):** Detalhes do RSVP (formato do item na lista acima).
*   **Respostas de Erro:** `401`, `403`, `404` (se o usuário não tiver RSVP ou evento/perfil não encontrado).

## Categorias de Eventos (`/event-categories`)

Endpoints para CRUD de categorias de eventos seriam muito similares aos de `article-categories`:

*   **`POST /event-categories`**
*   **`GET /event-categories`**
*   **`GET /event-categories/{id_or_slug}`**
*   **`PUT /event-categories/{id}`** (ou `PATCH`)
*   **`DELETE /event-categories/{id}`**

As respostas e corpos de requisição seriam análogos, usando os campos de `deeper_event_categories`.

## Integrações com Outros Sistemas (Exemplos):

*   **Comentários para um Evento:** `GET /events/{event_id}/comments`
*   **Votar em um Evento:** `POST /events/{event_id}/votes`
*   **Favoritar um Evento:** `POST /events/{event_id}/favorites`

Estes endpoints delegariam para os respectivos sistemas de comentários, votos e favoritos, usando \"deeper_events\" como o `system_object` ou `object_name`.