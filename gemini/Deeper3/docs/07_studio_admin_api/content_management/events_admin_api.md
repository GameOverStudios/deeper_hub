# API de Administração: Gerenciamento de Eventos (`deeper_events`)

Endpoints da API para administradores e moderadores gerenciarem o conteúdo do módulo `deeper_events`.

**Permissões:** Todos os endpoints aqui requerem um papel de administrador ou moderador com permissões específicas para gerenciar eventos.

## Endpoints

### 1. Listar Todos os Eventos (Visão Administrativa)

*   **`GET /admin/events`**
*   **Autenticação:** Admin/Moderador Requerida.
*   **Diferenças da API Pública (`GET /events`):**
    *   Retorna eventos de **todos** os organizadores.
    *   Pode listar eventos com **qualquer status** (`draft`, `active`, `past`, `cancelled`) por padrão ou via filtro.
    *   Pode listar eventos com **qualquer visibilidade** (`public`, `private`, `unlisted`).
*   **Query Parameters:**
    *   `profile_id` (integer): Filtrar por organizador.
    *   `status` (string): Filtrar por status.
    *   `visibility` (string).
    *   `q` (string): Termo de busca (título, descrição, localização).
    *   `date_from`, `date_to` (Unix timestamps): Filtrar por `start_datetime`.
    *   `page`, `per_page`.
    *   `sort_by` (ex: `created_at_desc`, `start_datetime_asc`, `updated_at_desc`).
    *   `include` (ex: `organizer_profile,categories,banner_image,rsvps_summary`).
*   **Resposta de Sucesso (200 OK):** Lista paginada de todos os eventos com metadados administrativos.

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"title\": \"Evento Cancelado pela Administração\",
          \"status\": \"cancelled\",
          \"organizer_profile\": { \"id\": 45, \"name\": \"Usuário Y\" },
          \"start_datetime\": 1700000000,
          // ... outros campos do evento ...
          \"admin_notes\": \"Cancelado devido a conflito de datas.\" // Exemplo
        }
      ],
      \"pagination\": { /* ... */ }
    }
```

```json
    {
      \"title\": \"Nome do Evento Corrigido (Admin)\",
      \"status\": \"active\", // Ex: Admin reativa um evento
      \"visibility\": \"public\",
      // \"organizer_profile_id\": 60, // Reatribuir organizador
      \"admin_notes\": \"Status do evento ajustado.\"
    }
```

```json
    {
      \"rsvp_status\": \"no\", // \"yes\", \"no\", \"maybe\"
      \"admin_comment\": \"RSVP alterado por admin devido a X.\" // Opcional
    }
```

*   **Respostas de Erro:** `401`, `403`.

### 2. Obter Detalhes de Qualquer Evento (Visão Administrativa)

*   **`GET /admin/events/{id_or_slug}`**
*   **Autenticação:** Admin/Moderador Requerida.
*   **Query Parameters:** `include` (ex: `organizer_profile,categories,banner_image,rsvps_list_all_statuses,moderation_logs`).
    *   `rsvps_list_all_statuses` poderia retornar todos os RSVPs, não apenas os 'yes'.
*   **Resposta de Sucesso (200 OK):** Objeto completo do evento.
*   **Respostas de Erro:** `401`, `403`, `404`.

### 3. Atualizar Qualquer Evento (Ação Administrativa)

*   **`PUT /admin/events/{id}`** (ou `PATCH`)
*   **Autenticação:** Admin/Moderador Requerida.
*   **Diferenças da API Pública:** Permite editar eventos de qualquer organizador. Pode permitir a alteração de campos como `organizer_profile_id` (reatribuir organização), ou forçar um status.
*   **Corpo da Requisição (JSON):** Campos a serem atualizados.

*   **Resposta de Sucesso (200 OK):** Objeto do evento atualizado.
*   **Respostas de Erro:** `400`, `401`, `403`, `404`.

### 4. Excluir Qualquer Evento (Ação Administrativa)

*   **`DELETE /admin/events/{id}`**
*   **Autenticação:** Admin/Moderador Requerida.
*   **Opções (Query Param ou Corpo):**
    *   `reason` (string): Motivo da exclusão.
    *   `notify_organizer` (boolean, default: true): Se o organizador deve ser notificado.
*   **Resposta de Sucesso (200 OK ou 204 No Content):**
*   **Respostas de Erro:** `401`, `403`, `404`.

### 5. Gerenciar RSVPs de um Evento (Visão Administrativa)

*   **`GET /admin/events/{event_id}/rsvps`**
*   **Autenticação:** Admin/Moderador Requerida.
*   **Diferenças da API Pública:** Lista todos os RSVPs, independentemente de permissões normais.
*   **Query Parameters:** `rsvp_status`, `q` (buscar por nome do participante), `page`, `per_page`, `include=profile_details`.
*   **Resposta de Sucesso (200 OK):** Lista paginada de RSVPs.

*   **`PUT /admin/events/{event_id}/rsvps/{profile_id}`**
*   **Autenticação:** Admin/Moderador Requerida.
*   **Descrição:** Permite que um administrador altere o status do RSVP de um usuário (ex: de 'maybe' para 'yes', ou remover um RSVP problemático).
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):** Detalhes do RSVP atualizado.
*   **Ação do Backend:** Atualiza o RSVP e recalcula os contadores `rsvps_*_count` na tabela `deeper_events`.

*   **`DELETE /admin/events/{event_id}/rsvps/{profile_id}`** (ou usar o PUT acima com um status especial como 'removed_by_admin')
*   **Autenticação:** Admin/Moderador Requerida.
*   **Descrição:** Remove o RSVP de um usuário.
*   **Resposta de Sucesso (200 OK ou 204 No Content):**
*   **Ação do Backend:** Remove o RSVP e recalcula contadores.

## Considerações para Repositórios e Contextos:

*   **`Deeper.Content.EventsRepo`:**
    *   Funções como `list_events/2`, `get_event/2` precisarão de variantes ou parâmetros (ex: `as_admin: true`) para bypassar filtros de privacidade/status que se aplicam a usuários comuns.
    *   Novas funções podem ser necessárias para suportar filtros administrativos específicos ou buscas mais amplas.
    *   Funções de atualização/exclusão precisarão de lógica para não impor verificações de propriedade quando chamadas por um admin.
    *   Funções de gerenciamento de RSVP (`rsvp_to_event/5` ou novas funções admin) precisarão lidar com a modificação de RSVPs de outros usuários.
*   **`Deeper.Content.Events` (Contexto/Serviço):**
    *   Verificará se o `current_user_profile` tem permissões de administrador/moderador antes de chamar as funções de repo que modificam dados de outros usuários ou bypassam restrições.
    *   Pode incluir lógica para enviar notificações (ex: para o organizador quando um admin modifica seu evento).
*   **Log de Auditoria:** Ações como `update_event` (por admin), `delete_event` (por admin), e modificação de RSVPs por admin devem ser logadas.

Estes endpoints fornecem a base para a administração e moderação de eventos na plataforma \"Deeper\".