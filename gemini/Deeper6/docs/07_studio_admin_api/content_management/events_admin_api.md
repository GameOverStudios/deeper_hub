# Documentação Deeper: API de Administração - Gerenciamento de Eventos

Este documento descreve os endpoints da API \"Deeper\" para administradores gerenciarem o conteúdo do módulo de Eventos (`deeper_events`).

## Escopo e Funcionalidades:

*   Listar todos os eventos com filtros avançados (status, autor, categoria, data, etc.).
*   Visualizar detalhes completos de um evento (visão de admin).
*   Criar novos eventos (como administrador, potencialmente em nome de outros usuários).
*   Atualizar eventos existentes.
*   Alterar o status de eventos (ativo, cancelado, pendente, passado).
*   Gerenciar categorias de eventos.
*   Gerenciar participantes (RSVP) de eventos.
*   Destacar/Desdestacar eventos.

## Tabelas Relevantes (Já Definidas em `docs/03_content_modules/deeper_events/`):

*   `deeper_events_entries`
*   `deeper_events_categories`
*   `deeper_events_participants`

## Módulo de Acesso a Dados (Já Definido em `docs/03_content_modules/deeper_events/data_access_module.md`):

*   `Deeper.Content.EventsRepo` será utilizado para todas as interações com o banco de dados.

## Endpoints da API de Administração para Eventos

Todos os endpoints estão sob `/api/v1/admin/content/events/...` e requerem autenticação de administrador.

### Gerenciamento de Categorias de Eventos (Admin)

Os endpoints para CRUD de `deeper_events_categories` já foram parcialmente cobertos na API pública de `deeper_events`, mas aqui seriam especificamente para administradores e poderiam ter mais capacidades.

#### 1. Listar Categorias de Eventos
*   **Endpoint:** `GET /api/v1/admin/content/events/categories`
*   **Resposta:** Similar ao endpoint público, lista de `deeper_events_categories`.

#### 2. Criar Categoria de Evento
*   **Endpoint:** `POST /api/v1/admin/content/events/categories`
*   **Corpo (JSON):** `{ \"name\": \"networking_pro\", \"title_lang_key\": \"_cat_event_networking_pro\", \"parent_id\": 0 }`
*   **Resposta (201 Created).**

#### 3. Obter Detalhes de uma Categoria
*   **Endpoint:** `GET /api/v1/admin/content/events/categories/{categoryId}`
*   **Resposta (200 OK).**

#### 4. Atualizar Categoria de Evento
*   **Endpoint:** `PUT /api/v1/admin/content/events/categories/{categoryId}`
*   **Corpo (JSON):** Campos a atualizar.
*   **Resposta (200 OK).**

#### 5. Deletar Categoria de Evento
*   **Endpoint:** `DELETE /api/v1/admin/content/events/categories/{categoryId}`
*   **Lógica:** Pode definir eventos que usam esta categoria para `category_id = NULL` ou impedir a exclusão se estiver em uso.
*   **Resposta (204 No Content).**

### Gerenciamento de Entradas de Eventos (`deeper_events_entries`)

#### 1. Listar Eventos (Visão de Admin)

*   **Endpoint:** `GET /api/v1/admin/content/events/entries`
*   **Propósito:** Retorna uma lista paginada de todos os eventos no sistema.
*   **Autenticação:** Administrador.
*   **Query Parameters:**
    *   `offset`, `limit`
    *   `search_term` (por `title`, `description`, `author_fullname`, `location_venue_name`).
    *   `status` (String, Opcional): `active`, `pending_approval`, `cancelled`, `draft`, `past`.
    *   `author_profile_id` (Integer, Opcional).
    *   `category_id` (Integer, Opcional).
    *   `date_filter_type` (String, Opcional): `start` (default), `end`.
    *   `date_from` (Integer, Opcional): Timestamp Unix UTC.
    *   `date_to` (Integer, Opcional): Timestamp Unix UTC.
    *   `featured` (Integer, Opcional): `0` ou `1`.
    *   `sort_by` (String, Opcional): ex: `created_at_desc`, `start_datetime_asc`, `title_asc`.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"title\": \"Evento Admin de Exemplo\",
          \"author_profile_id\": 10,
          \"author_fullname\": \"Admin User\", // JOIN com sys_profiles e bx_persons_data
          \"category_name\": \"Conferências\", // JOIN com deeper_events_categories
          \"start_datetime\": 1679000000,
          \"end_datetime\": 1679007200,
          \"status\": \"active\",
          \"participants_count\": 25,
          \"featured\": 1,
          \"created_at\": 1678886400
        }
        // ... mais eventos ...
      ],
      \"pagination\": { /* ... */ }
    }
```

```json
    {
      \"id\": 1,
      \"author_profile_id\": 10,
      \"author_account_email\": \"admin@example.com\", // Exemplo de info de admin
      \"category_id\": 3,
      \"title\": \"Título do Evento Detalhado\",
      // ... todos os campos de deeper_events_entries ...
      \"status\": \"active\",
      \"visibility_group_id\": \"3\",
      \"featured\": 1,
      \"created_at\": 1678886400,
      \"updated_at\": 1678887000,
      \"participants_summary\": { // Opcional, resumo rápido
        \"attending\": 25,
        \"interested\": 10
      }
      // Link para endpoint de participantes: \"/api/v1/admin/content/events/entries/{eventId}/participants\"
    }
```

```json
    {
      \"author_profile_id\": 15, // Pode ser diferente do admin logado
      \"category_id\": 3,
      \"title\": \"Evento Criado por Admin\",
      \"description\": \"Descrição do evento...\",
      \"start_datetime\": 1680000000,
      \"end_datetime\": 1680007200,
      \"timezone\": \"Europe/London\",
      \"location_type\": \"physical\",
      \"location_venue_name\": \"Local do Evento\",
      \"status\": \"active\", // Admin pode publicar diretamente
      \"featured\": 0
      // ...
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 1, // deeper_events_participants.id
          \"event_id\": 101,
          \"profile_id\": 25,
          \"profile_fullname\": \"Alice P.\", // JOIN com sys_profiles e bx_persons_data
          \"profile_email\": \"alice.p@example.com\", // JOIN
          \"rsvp_status\": \"attending\",
          \"added_at\": 1678900000
        }
      ],
      \"pagination\": { /* ... */ }
    }
```

```json
    {
      \"profile_id\": 30,
      \"rsvp_status\": \"attending\"
    }
```

```json
    {
      \"rsvp_status\": \"not_attending\"
    }
```

#### 2. Obter Detalhes de um Evento (Visão de Admin)

*   **Endpoint:** `GET /api/v1/admin/content/events/entries/{eventId}`
*   **Propósito:** Retorna os detalhes completos de um evento.
*   **Autenticação:** Administrador.
*   **Parâmetros de URL:** `{eventId}` (Integer).
*   **Resposta de Sucesso (200 OK):**
    Semelhante ao endpoint público `GET /api/v1/events/{eventId}`, mas pode incluir mais informações de auditoria ou internas.

#### 3. Criar Novo Evento (como Admin)

*   **Endpoint:** `POST /api/v1/admin/content/events/entries`
*   **Autenticação:** Administrador.
*   **Corpo da Requisição (JSON):** Campos de `deeper_events_entries`.

*   **Resposta (201 Created):** Corpo do evento criado.

#### 4. Atualizar Evento (como Admin)

*   **Endpoint:** `PUT /api/v1/admin/content/events/entries/{eventId}`
*   **Autenticação:** Administrador.
*   **Parâmetros de URL:** `{eventId}` (Integer).
*   **Corpo da Requisição (JSON):** Campos de `deeper_events_entries` a serem atualizados.
*   **Resposta (200 OK):** Corpo do evento atualizado.

#### 5. Deletar Evento (Soft ou Hard Delete - como Admin)

*   **Endpoint:** `DELETE /api/v1/admin/content/events/entries/{eventId}`
*   **Autenticação:** Administrador.
*   **Parâmetros de URL:** `{eventId}` (Integer).
*   **Query Parameters:**
    *   `permanent` (Boolean, Opcional, Default: `false`): Se `true`, realiza um hard delete.
*   **Lógica:** Soft delete pode mudar `status` para `deleted` ou `archived`. Hard delete remove o registro. `ON DELETE CASCADE` em `deeper_events_participants` removerá RSVPs.
*   **Resposta (204 No Content ou 200 OK com mensagem).**

### Gerenciamento de Participantes de Eventos (`deeper_events_participants`) - Admin

#### 1. Listar Participantes de um Evento (Admin)
*   **Endpoint:** `GET /api/v1/admin/content/events/entries/{eventId}/participants`
*   **Autenticação:** Administrador.
*   **Parâmetros de URL:** `{eventId}` (Integer).
*   **Query Parameters:**
    *   `offset`, `limit`
    *   `rsvp_status` (String, Opcional): `attending`, `interested`, `not_attending`.
    *   `search_term` (String, Opcional): Buscar no nome do participante.
*   **Resposta (200 OK):**

#### 2. Adicionar Participante a um Evento (Admin)
*   **Endpoint:** `POST /api/v1/admin/content/events/entries/{eventId}/participants`
*   **Autenticação:** Administrador.
*   **Corpo da Requisição (JSON):**

*   **Lógica:** Chama `EventsRepo.rsvp_event/3` e atualiza contadores.
*   **Resposta (201 Created):** Detalhes da participação.

#### 3. Atualizar Status de RSVP de um Participante (Admin)
*   **Endpoint:** `PUT /api/v1/admin/content/events/participants/{participationId}` (onde `{participationId}` é `deeper_events_participants.id`)
*   **Autenticação:** Administrador.
*   **Corpo da Requisição (JSON):**

*   **Resposta (200 OK):** Detalhes da participação atualizada.

#### 4. Remover Participante de um Evento (Admin)
*   **Endpoint:** `DELETE /api/v1/admin/content/events/participants/{participationId}`
*   **Autenticação:** Administrador.
*   **Lógica:** Remove a entrada de `deeper_events_participants` e recalcula os contadores do evento.
*   **Resposta (204 No Content).**

### Ações em Massa em Eventos (Opcional)

*   **Endpoint:** `POST /api/v1/admin/content/events/entries/bulk-actions`
*   **Corpo (JSON):** `{ \"action\": \"publish\" / \"cancel\" / \"feature\" / \"unfeature\", \"event_ids\": [1, 2, 3] }`
*   **Resposta (200 OK):** Status das ações.

Esta API de administração para eventos permite um controle detalhado sobre o ciclo de vida dos eventos e a participação dos usuários.