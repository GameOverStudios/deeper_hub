# Documentação Deeper: Mapeamento da Lógica de \"Serviço\" para API (Módulo `deeper_events`)

Similar ao módulo de artigos, o módulo de eventos no UNA PHP teria \"serviços\" para gerar blocos de UI ou fornecer dados agregados. Com a API RESTful \"Deeper\", essa lógica é mapeada para endpoints da API que retornam dados JSON, e o cliente (frontend) lida com a apresentação.

Abaixo estão exemplos de \"serviços\" comuns de um módulo de eventos e como eles seriam mapeados:

## 1. Serviço: \"Listar Próximos N Eventos\" (para um bloco na página inicial ou calendário)

*   **Funcionalidade UNA PHP (Exemplo Hipotético):**
    *   `BxEventsModule->service_upcoming_events(int $count = 5, string $period_days = 30)`
    *   Retornaria HTML formatado com os `N` próximos eventos dentro de um período.

*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `GET /api/v1/events`
    *   **Query Parameters:**
        *   `upcoming=true` (O `EventsRepo.list_events` filtraria por `start_datetime >= now`).
        *   `sort_by=start_datetime_asc`
        *   `status=active` (ou o status apropriado para eventos visíveis)
        *   `per_page={N}` (ex: `per_page=5`)
        *   `page=1`
        *   `date_to={timestamp_limite}` (opcional, para limitar a \"proximidade\", ex: próximos 30 dias. O `EventsRepo` precisaria de um filtro `start_datetime <= ?`).
        *   `fields=id,title,slug,start_datetime,location_text,banner_thumbnail_url` (cliente solicita campos concisos).
    *   **Lógica no `Deeper.Content.EventsRepo`:** A função `list_events/2` lidaria com esses parâmetros.
    *   **Responsabilidade do Cliente:** Buscar os dados e renderizar em seu componente de \"Próximos Eventos\".

## 2. Serviço: \"Listar Eventos por Categoria\"

*   **Funcionalidade UNA PHP:**
    *   `BxEventsModule->service_events_by_category(string $category_slug, int $page = 1, int $per_page = 10)`
    *   Retornaria HTML paginado.

*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `GET /api/v1/events`
    *   **Query Parameters:**
        *   `category_slug={slug_da_categoria}` (OU `category_id={id_da_categoria}`)
        *   `status=active`
        *   `upcoming=true` (opcional, para mostrar apenas futuros da categoria)
        *   `page={page_num}`
        *   `per_page={items_per_page}`
        *   `sort_by=start_datetime_asc`
    *   **Lógica no `Deeper.Content.EventsRepo`:** A função `list_events/2` já foi projetada para aceitar `category_slug` ou `category_id`.
    *   **Responsabilidade do Cliente:** Renderizar a lista e a paginação.

## 3. Serviço: \"Exibir Calendário de Eventos\" (com eventos marcados)

*   **Funcionalidade UNA PHP:**
    *   `BxEventsModule->service_events_calendar(int $year, int $month)`
    *   Retornaria HTML de um calendário com dias marcados que possuem eventos.

*   **Mapeamento para API \"Deeper\":**
    *   **Abordagem 1: Endpoint para dados do mês:**
        *   **Endpoint:** `GET /api/v1/events`
        *   **Query Parameters:**
            *   `month={YYYY-MM}` (ex: `month=2023-11`)
            *   `status=active`
            *   `fields=id,title,start_datetime,slug` (apenas o necessário para marcar o calendário e linkar)
        *   **Lógica no `Deeper.Content.EventsRepo`:** `list_events/2` precisaria de um filtro para `start_datetime` dentro do mês especificado. SQLite: `STRFTIME('%Y-%m', start_datetime, 'unixepoch') = 'YYYY-MM'`.
        *   **Resposta da API:** Uma lista de eventos para o mês.
        *   **Responsabilidade do Cliente:** Buscar os eventos do mês e renderizar seu próprio componente de calendário, marcando os dias que têm eventos. Ao clicar em um dia, poderia fazer outra chamada `GET /api/v1/events?date=YYYY-MM-DD` para listar os eventos daquele dia específico.
    *   **Abordagem 2: Endpoint para resumo do calendário (contagem por dia):**
        *   **Endpoint:** `GET /api/v1/events/calendar-summary?month={YYYY-MM}`
        *   **Lógica no `Deeper.Content.EventsRepo`:** Nova função para agrupar por dia e contar.

```json
            {
              \"data\": [
                {\"day\": \"2023-11-05\", \"event_count\": 2},
                {\"day\": \"2023-11-14\", \"event_count\": 1}
              ]
            }
```

```elixir
            # SQL Exemplo no EventsRepo
            # SELECT STRFTIME('%Y-%m-%d', start_datetime, 'unixepoch') as event_day, COUNT(id) as event_count
            # FROM deeper_events
            # WHERE STRFTIME('%Y-%m', start_datetime, 'unixepoch') = ? AND status = 'active'
            # GROUP BY event_day;
```

```elixir
            # Exemplo no EventsRepo para \"eventos que eu vou\"
            # def list_events_for_profile_rsvp(profile_id, rsvp_status_filter, pagination_opts) do
            #   SELECT e.* FROM deeper_events e
            #   JOIN deeper_event_rsvps rsvp ON e.id = rsvp.event_id
            #   WHERE rsvp.profile_id = ? AND rsvp.rsvp_status = ?
            #   ORDER BY e.start_datetime ASC ...
            # end
```

        *   **Resposta da API:**

        *   **Responsabilidade do Cliente:** Usar esses dados para marcar os dias no calendário.

## 4. Serviço: \"Exibir Detalhes de um Evento\" (para uma página de evento completa)

*   **Funcionalidade UNA PHP:**
    *   `BxEventsModule->service_view_event(int $event_id)`
    *   Retornaria HTML completo da página do evento.

*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `GET /api/v1/events/{id_or_slug}`
    *   **Query Parameters:** `include=organizer,categories,banner_image,rsvps_summary` (e talvez `comments_list` ou `comments_summary` se os comentários forem carregados inicialmente).
    *   **Lógica no `Deeper.Content.EventsRepo`:** A função `get_event/2` ou `get_event_by_slug/2` lida com isso.
    *   **Responsabilidade do Cliente:** Buscar todos os dados necessários e montar a página de visualização do evento.

## 5. Serviço: \"Listar Participantes de um Evento\"

*   **Funcionalidade UNA PHP:**
    *   `BxEventsModule->service_event_attendees_list(int $event_id, string $rsvp_status = \"yes\")`
    *   Retornaria HTML da lista de participantes.

*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `GET /api/v1/events/{event_id}/rsvps`
    *   **Query Parameters:**
        *   `rsvp_status=yes` (ou `maybe`, `no`)
        *   `page`, `per_page`
        *   `include=profile_details`
    *   **Lógica no `Deeper.Content.EventsRepo`:** A função `list_rsvps_for_event/3` lida com isso.
    *   **Responsabilidade do Cliente:** Renderizar a lista de participantes.

## 6. Serviço: \"Bloco de Ação RSVP\"

*   **Funcionalidade UNA PHP:**
    *   `BxEventsModule->service_rsvp_block(int $event_id, int $viewer_profile_id)`
    *   Retornaria HTML com botões para o usuário logado fazer RSVP (Sim, Não, Talvez) ou alterar seu RSVP existente.

*   **Mapeamento para API \"Deeper\":**
    *   **Não um serviço que retorna UI diretamente.**
    *   **Passo 1: Obter status do evento e RSVP do usuário (se houver):**
        *   O cliente primeiro obtém os detalhes do evento: `GET /api/v1/events/{event_id}`. A resposta pode incluir o RSVP do usuário atual se o backend adicionar essa lógica (ex: `?include=my_rsvp_status`).
        *   OU, o cliente faz uma chamada separada: `GET /api/v1/events/{event_id}/rsvps/me`.
    *   **Passo 2: Renderizar UI de RSVP no Cliente:** Com base no status do evento (`allow_rsvps`, `max_attendees` vs `rsvps_yes_count`) e no RSVP atual do usuário, o cliente renderiza os botões apropriados.
    *   **Passo 3: Enviar RSVP:**
        *   **Endpoint:** `POST /api/v1/events/{event_id}/rsvps`
        *   **Corpo:** `{ \"rsvp_status\": \"yes\" }`
    *   **Responsabilidade do Cliente:** Gerenciar o estado da UI do RSVP e fazer a chamada POST.

## 7. Serviço: \"Incrementar Contagem de Visualizações do Evento\"

*   **Funcionalidade UNA PHP:** Lógica chamada quando uma página de evento é visualizada.
*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `POST /api/v1/events/{id_or_slug}/view`
    *   **Lógica no `Deeper.Content.EventsRepo`:** Função `increment_event_view_count(event_id)`.
    *   **Responsabilidade do Cliente:** Chamar este endpoint quando um evento é visualizado.
    *   **Alternativa:** Usar um sistema de visualização genérico (`sys_objects_view`), como no módulo de artigos.

## 8. Serviço: \"Meus Eventos\" (Eventos que o usuário organizou ou participará)

*   **Funcionalidade UNA PHP:**
    *   `BxEventsModule->service_my_events(int $profile_id, string $type = \"organized\")` // type = organized, attending, maybe
    *   Retornaria HTML.

*   **Mapeamento para API \"Deeper\":**
    *   **Para eventos organizados:**
        *   **Endpoint:** `GET /api/v1/events`
        *   **Query Parameters:** `profile_id={my_profile_id}`
    *   **Para eventos que participará (RSVP='yes'):**
        *   **Endpoint:** `GET /api/v1/profiles/{my_profile_id}/event-rsvps` (Novo endpoint ou um filtro no `GET /events`)
        *   **Query Parameters:** `rsvp_status=yes`
        *   **Lógica no Repo:** Uma nova função no `EventsRepo` ou `ProfilesRepo` que busca eventos onde o perfil_id tem um RSVP específico.

    *   **Responsabilidade do Cliente:** Fazer as chamadas apropriadas e exibir as listas.

## Conclusões:

A API \"Deeper\" para eventos se concentrará em fornecer os dados brutos e os endpoints para ações. A lógica de apresentação e a combinação de dados para formar \"blocos de UI\" complexos (como calendários interativos ou listas \"Meus Eventos\" combinadas) recairão sobre o cliente. Isso oferece maior flexibilidade ao cliente, mas também exige que ele tenha mais lógica de UI.