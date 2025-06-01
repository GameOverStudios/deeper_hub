# Documentação Deeper: Endpoints da API para Módulo de Eventos

Este documento especifica os endpoints da API RESTful \"Deeper\" para gerenciar Eventos.

## Endpoints de Categorias de Eventos

### 1. Listar Categorias de Eventos

*   **Endpoint:** `GET /api/v1/events/categories`
*   **Propósito:** Retorna uma lista de todas as categorias de eventos disponíveis.
*   **Autenticação:** Opcional (categorias são geralmente públicas).
*   **Query Parameters:**
    *   `lang` (String, Opcional): Código do idioma para tradução dos títulos das categorias.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"parent_id\": 0,
          \"name\": \"technology\",
          \"title\": \"Technology\" // Título resolvido/traduzido
        },
        {
          \"id\": 2,
          \"parent_id\": 0,
          \"name\": \"music\",
          \"title\": \"Music\"
        }
        // ... mais categorias ...
      ]
    }
```

```json
    {
      \"name\": \"sports_new\",
      \"title_lang_key\": \"_deeper_event_category_sports\", // ou title direto
      \"parent_id\": 0, // Opcional
      \"order\": 10 // Opcional
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 101,
          \"title\": \"Conferência Anual de Elixir\",
          \"start_datetime\": 1678886400,
          \"location_city\": \"São Paulo\",
          \"cover_image_url\": \"/files/event_cover_101.jpg\", // Resolvido
          \"author_fullname\": \"Comunidade Elixir BR\",
          \"category_name\": \"Tecnologia\",
          \"participants_count\": 150
          // ... outros campos resumidos para a lista ...
        }
        // ... mais eventos ...
      ],
      \"pagination\": {
        \"total_items\": 85,
        \"offset\": 0,
        \"limit\": 20,
        \"current_page\": 1,
        \"total_pages\": 5
      }
    }
```

```json
    {
      \"title\": \"Workshop de Phoenix LiveView\",
      \"description\": \"Aprenda a construir aplicações web interativas.\",
      \"category_id\": 1, // ID da categoria \"Tecnologia\"
      \"start_datetime\": 1679000000, // Timestamp Unix UTC
      \"end_datetime\": 1679007200,   // Timestamp Unix UTC
      \"timezone\": \"America/New_York\",
      \"location_type\": \"online\",
      \"location_online_url\": \"https://zoom.us/...\",
      // ... outros campos opcionais de deeper_events_entries ...
      \"visibility_group_id\": \"3\" // Público por padrão
    }
```

```json
    {
      \"id\": 101,
      \"author_profile_id\": 10,
      \"author_fullname\": \"Nome do Autor\",
      \"category_id\": 2,
      \"category_name\": \"Tecnologia\",
      \"title\": \"Grande Evento de Elixir\",
      \"description\": \"Uma descrição detalhada do evento...\",
      // ... todos os campos de deeper_events_entries ...
      \"participants\": [ // Opcional: primeiros X participantes ou link para endpoint de participantes
        {\"profile_id\": 15, \"fullname\": \"Participante A\", \"avatar_url\": \"...\"},
        {\"profile_id\": 22, \"fullname\": \"Participante B\", \"avatar_url\": \"...\"}
      ],
      \"current_user_rsvp_status\": \"attending\" // ou null
    }
```

```json
    {
      \"title\": \"Título Atualizado do Evento\",
      \"description\": \"Descrição atualizada.\",
      \"start_datetime\": 1679000100
      // ... outros campos ...
    }
```

```json
    {
      \"rsvp_status\": \"attending\" // Valores: \"attending\", \"interested\", \"not_attending\"
    }
```

```json
    {
      \"event_id\": 101,
      \"profile_id\": 123, // ID do perfil do usuário logado
      \"rsvp_status\": \"attending\",
      \"message\": \"RSVP updated successfully.\" // Opcional
    }
```

```json
    {
      \"data\": [
        {
          \"profile_id\": 15,
          \"fullname\": \"Participante A\",
          \"avatar_url\": \"/path/to/avatar_a.jpg\",
          \"rsvp_status\": \"attending\",
          \"added_at\": 1678810000
        },
        {
          \"profile_id\": 22,
          \"fullname\": \"Participante B\",
          \"avatar_url\": \"/path/to/avatar_b.jpg\",
          \"rsvp_status\": \"interested\",
          \"added_at\": 1678820000
        }
        // ... mais participantes ...
      ],
      \"pagination\": {
        \"total_items\": 35,
        \"offset\": 0,
        \"limit\": 20
        // ...
      }
    }
```

### 2. Criar Categoria de Evento (Admin)

*   **Endpoint:** `POST /api/v1/admin/events/categories`
*   **Propósito:** Cria uma nova categoria de evento.
*   **Autenticação:** Obrigatória (requer permissão de administrador).
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (201 Created):** Corpo da categoria criada.

*(Endpoints para `GET /api/v1/admin/events/categories/{id}`, `PUT /api/v1/admin/events/categories/{id}`, `DELETE /api/v1/admin/events/categories/{id}` para gerenciamento de categorias por administradores podem ser adicionados aqui).*

## Endpoints de Eventos (Entradas)

### 1. Listar Eventos

*   **Endpoint:** `GET /api/v1/events`
*   **Propósito:** Retorna uma lista paginada de eventos, com suporte a filtros e ordenação.
*   **Autenticação:** Opcional (eventos públicos podem ser listados; filtros de visibilidade são aplicados).
*   **Query Parameters:**
    *   `offset` (Integer, Opcional, Default: 0)
    *   `limit` (Integer, Opcional, Default: 20)
    *   `lang` (String, Opcional): Para tradução de títulos, categorias, etc.
    *   `category_id` (Integer, Opcional): Filtrar por ID da categoria.
    *   `author_profile_id` (Integer, Opcional): Filtrar por ID do perfil do autor.
    *   `status` (String, Opcional): Filtrar por status do evento (ex: `active`, `past`, `cancelled`).
    *   `date_from` (Integer, Opcional): Timestamp Unix UTC, listar eventos começando a partir desta data/hora.
    *   `date_to` (Integer, Opcional): Timestamp Unix UTC, listar eventos começando até esta data/hora.
    *   `search_term` (String, Opcional): Termo para buscar no título e descrição.
    *   `location_city` (String, Opcional): Filtrar por cidade.
    *   `sort_by` (String, Opcional): Campo para ordenação (ex: `start_datetime_asc`, `title_desc`, `participants_count_desc`). Campos permitidos: `start_datetime`, `title`, `created_at`, `participants_count`.
    *   `visibility` (String, Opcional): Para filtrar por visibilidade se o usuário não estiver logado ou para admins (ex: `public_only`, `all`).
*   **Resposta de Sucesso (200 OK):**

### 2. Criar Novo Evento

*   **Endpoint:** `POST /api/v1/events`
*   **Propósito:** Cria um novo evento.
*   **Autenticação:** Obrigatória (usuário precisa ter permissão para criar eventos - ACL).
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (201 Created):** Corpo do evento criado (detalhes completos).
    *   Cabeçalho `Location`: `/api/v1/events/{newEventId}`

### 3. Obter Detalhes de um Evento

*   **Endpoint:** `GET /api/v1/events/{eventId}`
*   **Propósito:** Retorna os detalhes completos de um evento específico.
*   **Autenticação:** Opcional (visibilidade do evento é verificada). Se autenticado, pode incluir informações de RSVP do usuário.
*   **Parâmetros de URL:**
    *   `{eventId}` (Integer, Obrigatório).
*   **Query Parameters:**
    *   `lang` (String, Opcional).
*   **Resposta de Sucesso (200 OK):**

### 4. Atualizar um Evento

*   **Endpoint:** `PUT /api/v1/events/{eventId}`
*   **Propósito:** Atualiza os detalhes de um evento existente.
*   **Autenticação:** Obrigatória (usuário deve ser o autor do evento ou ter permissão de administrador - ACL).
*   **Parâmetros de URL:**
    *   `{eventId}` (Integer, Obrigatório).
*   **Corpo da Requisição (JSON):** Contém os campos a serem atualizados.

*   **Resposta de Sucesso (200 OK):** Corpo do evento atualizado.

### 5. Deletar um Evento

*   **Endpoint:** `DELETE /api/v1/events/{eventId}`
*   **Propósito:** Remove um evento.
*   **Autenticação:** Obrigatória (usuário deve ser o autor ou admin - ACL).
*   **Parâmetros de URL:**
    *   `{eventId}` (Integer, Obrigatório).
*   **Resposta de Sucesso (204 No Content ou 200 OK com mensagem).**

## Endpoints de Participação em Eventos (RSVP)

### 1. Registrar/Atualizar RSVP para um Evento

*   **Endpoint:** `POST /api/v1/events/{eventId}/rsvp`
*   **Propósito:** Permite que o usuário autenticado registre ou atualize seu status de participação (RSVP) para um evento.
*   **Autenticação:** Obrigatória.
*   **Parâmetros de URL:**
    *   `{eventId}` (Integer, Obrigatório).
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK ou 201 Created):**

*   **Respostas de Erro:**
    *   `400 Bad Request`: Se `rsvp_status` for inválido, ou se o evento não permitir RSVP, ou prazo excedido, ou evento lotado.
    *   `403 Forbidden`: Se o usuário não puder fazer RSVP por alguma regra de negócio.
    *   `404 Not Found`: Se o evento não existir.

### 2. Listar Participantes de um Evento

*   **Endpoint:** `GET /api/v1/events/{eventId}/participants`
*   **Propósito:** Retorna uma lista paginada de perfis que fizeram RSVP para um evento.
*   **Autenticação:** Opcional (visibilidade da lista de participantes pode ser restrita).
*   **Parâmetros de URL:**
    *   `{eventId}` (Integer, Obrigatório).
*   **Query Parameters:**
    *   `offset` (Integer, Opcional, Default: 0)
    *   `limit` (Integer, Opcional, Default: 20)
    *   `rsvp_status` (String, Opcional): Filtrar por status de RSVP (ex: `attending`).
*   **Resposta de Sucesso (200 OK):**

## Endpoints para Interações Adicionais (Exemplos)

Estes endpoints seriam implementados pelos respectivos módulos de interação (Comentários, Votos, etc.), mas seriam contextualizados para eventos.

*   `GET /api/v1/events/{eventId}/comments` (Do módulo de Comentários)
*   `POST /api/v1/events/{eventId}/comments` (Do módulo de Comentários)
*   `POST /api/v1/events/{eventId}/vote` (Do módulo de Votos)
*   `POST /api/v1/events/{eventId}/favorite` (Do módulo de Favoritos)

Estes endpoints demonstram como as funcionalidades de eventos seriam expostas. A implementação no controller da API envolveria chamar as funções apropriadas do `EventsRepo` e de outros repositórios (como `LocalizationRepo`, `ACLService`).