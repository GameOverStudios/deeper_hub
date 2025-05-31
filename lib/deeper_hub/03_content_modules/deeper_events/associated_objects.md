# Documentação Deeper: Objetos Associados ao Módulo de Eventos

Este documento descreve como o módulo de Eventos (`deeper_events`) se integra com outros sistemas e objetos genéricos do \"Deeper\", como comentários, votos, favoritos, gerenciamento de arquivos (para banners), e o sistema de RSVPs (que é parte integrante deste módulo, mas também uma forma de interação).

O módulo `deeper_events` foca no conteúdo principal do evento, enquanto as interações e mídias associadas são gerenciadas por sistemas genéricos ou sub-componentes, referenciando o evento através de um `object_name` (ex: \"deeper_events\") e um `object_id` (o `id` do evento).

## 1. Comentários

*   **Sistema de Referência:** `📂 04_interaction_systems/sys_comments_system/`
*   **Tabelas Envolvidas (do sistema de comentários):**
    *   `sys_objects_cmts`: Deverá ter uma entrada para o objeto \"deeper_events\".
        *   `Name`: \"deeper_events_comments\" (ou simplesmente \"deeper_events\")
        *   `Module`: \"deeper_events\"
        *   `Table`: (Nome da tabela onde os comentários específicos para eventos seriam armazenados, ex: `deeper_event_page_comments`)
        *   `TriggerTable`: \"deeper_events\"
        *   `TriggerFieldId`: \"id\"
        *   `TriggerFieldComments`: (Coluna opcional em `deeper_events` para contagem, ou contagem dinâmica)
    *   Tabela de conteúdo de comentários: Armazena os comentários com `cmt_object_id` = `event_id`.
    *   `sys_cmts_ids`: Metadados/sumário para comentários.

*   **Endpoints da API (Exemplos, gerenciados pelo módulo de comentários):**
    *   `GET /api/v1/comments?system_object=deeper_events&object_id={event_id}`: Listar comentários para um evento.
    *   `POST /api/v1/comments`: Postar um novo comentário para um evento.

```json
        {
          \"system_object\": \"deeper_events\",
          \"object_id\": 456, // event_id
          \"text\": \"Este evento parece ótimo!\"
        }
```

```json
        // Parte da resposta do evento
        \"banner_image_details\": {
          \"id\": 789,
          \"file_name\": \"banner_evento.png\",
          \"access_url\": \"/api/v1/files/view/deeper_local_files/banners/banner_evento.png\"
        }
```

*   **Integração na API de Eventos:**
    *   `GET /events/{id_or_slug}?include=comments_summary` poderia adicionar `{\"comments_count\": 25}`.

## 2. Votos / Avaliações (se aplicável a eventos)

*   **Sistema de Referência:** `📂 04_interaction_systems/sys_voting_system/`
*   **Se eventos puderem ser \"avaliados\" (ex: por participantes após o evento):**
    *   **Tabelas Envolvidas:** Similar ao módulo de artigos, com `sys_objects_vote` configurado para \"deeper_events_votes\".
    *   **Endpoints da API:**
        *   `GET /api/v1/votes/summary?object_name=deeper_events_votes&object_id={event_id}`
        *   `POST /api/v1/votes` (com `object_name=\"deeper_events_votes\"`)
    *   **Integração:** `GET /events/{id_or_slug}?include=votes_summary` poderia adicionar `{\"votes_average\": 4.2, \"votes_count\": 50}`.

## 3. Favoritos (se aplicável a eventos, ex: \"Salvar Evento\")

*   **Sistema de Referência:** `📂 04_interaction_systems/sys_favorites_system/`
*   **Tabelas Envolvidas:** `sys_objects_favorite` configurado para \"deeper_events_favorites\".
*   **Endpoints da API:**
    *   `GET /api/v1/favorites/status?object_name=deeper_events_favorites&object_id={event_id}`
    *   `POST /api/v1/favorites` (com `object_name=\"deeper_events_favorites\"`)
*   **Integração:** `GET /events/{id_or_slug}?include=favorites_summary` poderia adicionar `{\"favorites_count\": 75, \"is_favorited_by_current_user\": false}`.

## 4. Banner do Evento

*   **Sistema de Referência:** `📂 06_file_management/`
*   **Tabelas Envolvidas:**
    *   `deeper_events`: Contém a coluna `banner_file_id INTEGER`, FK para `deeper_files.id`.
    *   `deeper_files`: Armazena os metadados da imagem do banner.
*   **Upload/Associação:**
    1.  Cliente faz upload da imagem via `POST /api/v1/files/upload`.
    2.  API de arquivos retorna o `id` do arquivo.
    3.  Ao criar (`POST /events`) ou atualizar (`PUT/PATCH /events/{id}`) um evento, o cliente envia este `banner_file_id`.
*   **Recuperação:**
    *   `GET /events/{id_or_slug}?include=banner_image`: O `EventsRepo.get_event` fará `JOIN` com `deeper_files` para incluir detalhes do banner.

## 5. Categorias de Eventos

*   **Sistema de Referência:** Tabelas `deeper_event_categories` e `deeper_events_to_categories` definidas dentro deste módulo de eventos.
*   **Associação:**
    *   Ao criar/atualizar um evento, uma lista de `category_ids` é fornecida.
    *   `EventsRepo.associate_categories_to_event/2` atualiza a tabela de junção.
*   **Recuperação:**
    *   `GET /events/{id_or_slug}?include=categories`: `EventsRepo.fetch_event_categories/1` busca as categorias.
    *   `GET /events` pode ser filtrado por `category_id` ou `category_slug`.

## 6. Participantes (RSVPs)

*   **Sistema de Referência:** Tabela `deeper_event_rsvps` definida e gerenciada dentro deste módulo de eventos (pelo `EventsRepo`).
*   **Registro/Atualização de RSVP:**
    *   `POST /events/{event_id}/rsvps`
    *   O `EventsRepo.rsvp_to_event/5` lida com a inserção/atualização na tabela `deeper_event_rsvps` e atualização dos contadores na tabela `deeper_events`.
*   **Listagem de Participantes:**
    *   `GET /events/{event_id}/rsvps`
    *   `EventsRepo.list_rsvps_for_event/3` busca os dados, podendo fazer `JOIN` com `sys_profiles` para detalhes dos participantes.
*   **Recuperação de Contagem/Sumário:**
    *   As colunas `rsvps_yes_count`, `rsvps_maybe_count`, `rsvps_no_count` na tabela `deeper_events` fornecem um sumário rápido.
    *   `GET /events/{id_or_slug}` retorna essas contagens por padrão.

## 7. Visualizações (Views)

*   **Sistema de Referência:** Pode ser um sistema de visualizações genérico ou lógica no `EventsRepo`.
*   **Tabelas Envolvidas (se sistema genérico `sys_objects_view`):**
    *   `sys_objects_view`: Entrada para \"deeper_events_views\".
    *   Tabela de rastreamento de visualizações com `object_id` = `event_id`.
*   **Registro de Visualização:**
    *   `POST /api/v1/events/{id_or_slug}/view` chama `EventsRepo.increment_event_view_count(event_id)` (que atualiza `deeper_events.views`) OU interage com um `ViewsRepo` genérico.
*   **Recuperação:**
    *   A coluna `views` na tabela `deeper_events` é retornada por padrão.

## 8. Localização (Mapas)

*   **Campos Envolvidos:** `location_text`, `location_lat`, `location_lng`, `address`, `city`, `state`, `country`, `zip_code` na tabela `deeper_events`.
*   **API:**
    *   A API de eventos (`GET /events`, `GET /events/{id}`) retorna esses campos.
    *   `GET /events?location_near=lat,lng&radius=X` permitiria busca por proximidade. A implementação disso no `EventsRepo` exigiria SQL geoespacial (SQLite tem capacidades limitadas nativamente, pode precisar de extensões como R*Tree ou cálculos de distância Haversine na query ou na aplicação se o dataset não for muito grande).
*   **Responsabilidade do Cliente:** Usar os dados de `location_lat`, `location_lng` para renderizar um mapa e marcadores. Usar `location_text` ou os campos de endereço para exibição textual.

## Considerações Adicionais:

*   **Notificações:** Ações como novo RSVP, cancelamento de evento, lembretes de evento, etc., gerariam notificações. Isso envolveria um sistema de notificações separado (`sys_alerts` ou um novo sistema `deeper_notifications`) que seria acionado por eventos na camada de contexto/serviço do módulo de eventos.
*   **Calendário (iCal/ICS Export):** Um endpoint `GET /events/{id_or_slug}/ical` poderia ser adicionado para exportar os detalhes do evento em formato iCalendar. Isso seria uma funcionalidade do controller, usando os dados do `EventsRepo`.

Esta abordagem de objetos associados permite que o módulo de eventos se concentre em sua lógica principal, enquanto aproveita funcionalidades genéricas e reutilizáveis para interações comuns.