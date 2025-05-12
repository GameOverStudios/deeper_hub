# Módulo: `DeeperHub.ServerEvents` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.ServerEvents`

O módulo `DeeperHub.ServerEvents` gerencia **eventos agendados e em andamento associados a servidores específicos** na plataforma DeeperHub. Ele permite que proprietários de servidores criem e anunciem eventos para suas comunidades, como torneios, manutenções programadas, eventos de XP em dobro, lançamentos de conteúdo, etc.

Este módulo lida com:
*   A definição, criação e gerenciamento de eventos de servidor.
*   O agendamento (data/hora de início e fim) dos eventos.
*   A listagem de eventos ativos, futuros e passados para um servidor ou globalmente.
*   Notificação aos jogadores interessados sobre eventos futuros ou em andamento.

O objetivo é fornecer uma ferramenta para que os servidores engajem suas comunidades e informem os jogadores sobre atividades importantes. 😊

*(Nota: Na documentação original, este era `DeeperHub.Services.ServerEvents`. Será tratado como `DeeperHub.ServerEvents`.)*

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Gerenciamento CRUD de Eventos (`create_event/1`, `get_event/1`, `update_event/2`, `delete_event/1`):**
    *   Permitir que proprietários de servidores (ou administradores) criem novos eventos associados a seus servidores.
    *   Cada evento inclui: título, descrição, tipo de evento (ex: `:maintenance`, `:tournament`, `:special_offer`, `:content_update`), data/hora de início, data/hora de fim, imagem/banner opcional, URL para mais informações (opcional).
    *   Atualizar ou excluir eventos agendados.
*   **Listagem de Eventos:**
    *   Listar todos os eventos para um servidor específico (`list_events_by_server/2`).
    *   Listar eventos ativos no momento (`list_current_events/2`).
    *   Listar eventos futuros/próximos (`list_upcoming_events/1`).
    *   Listar eventos passados.
    *   Suportar filtros (por tipo, por servidor) e paginação.
*   **Status do Evento:**
    *   Determinar automaticamente o status de um evento (ex: `:scheduled`, `:active`, `:completed`, `:cancelled`) com base nas datas/horas.
*   **Notificações (Integração com `DeeperHub.Notifications` e `DeeperHub.UserInteractions` se houver \"seguir servidor\"):**
    *   Notificar usuários que seguem um servidor (ou que optaram por receber notificações de eventos) sobre:
        *   Novos eventos agendados.
        *   Eventos que estão prestes a começar.
        *   Início de eventos.
        *   Alterações ou cancelamentos de eventos.
*   **Calendário de Eventos (Visualização):**
    *   Fornecer dados para a construção de uma visualização de calendário de eventos (global ou por servidor).
*   **Observabilidade e Auditoria:**
    *   Logar e metrificar a criação e o ciclo de vida dos eventos.
    *   Publicar eventos de domínio (ex: `server_event.created`, `server_event.started`) no `Core.EventBus`.
    *   Auditar a criação/modificação de eventos.
*   **Caching:**
    *   Cachear listas de eventos ativos ou futuros para performance.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.ServerEvents` (Fachada Pública):**
    *   Ponto de entrada para operações de eventos de servidor.
    *   Delega para o `ServerEventsService`.
2.  **`DeeperHub.ServerEvents.Services.ServerEventsService` (ou `DefaultServerEventsService`):**
    *   **Responsabilidade:** Orquestra a lógica de negócio para eventos de servidor.
    *   **Interações:**
        *   `DeeperHub.Core.Repo`: Para CRUD com `EventSchema`.
        *   `DeeperHub.Servers`: Para validar `server_id` e associar eventos.
        *   `DeeperHub.Accounts`: Para `user_id` do criador do evento (proprietário do servidor).
        *   `DeeperHub.Auth`/`RBAC`: Para permissões de gerenciamento de eventos.
        *   `DeeperHub.Core.EventBus`: Para publicar eventos de ciclo de vida de `ServerEvent`.
        *   `DeeperHub.Core.Cache`: Para cachear listas de eventos.
        *   `DeeperHub.Notifications`: Para enviar notificações sobre eventos.
        *   `DeeperHub.Core.ConfigManager`.
3.  **`DeeperHub.ServerEvents.Schemas.EventSchema` (ex-`Event`):**
    *   Campos: `id`, `server_id`, `created_by_user_id`, `title`, `description`, `event_type` (atom), `start_time` (NaiveDateTime ou DateTime UTC), `end_time` (NaiveDateTime ou DateTime UTC), `image_url` (opcional), `details_url` (opcional), `status` (calculado ou armazenado, ex: `:scheduled`, `:active`, `:completed`), `is_public`, `inserted_at`, `updated_at`.
4.  **`DeeperHub.ServerEvents.Storage` (ou lógica no `ServerEventsService`):**
    *   Encapsula as queries Ecto.
5.  **Workers (Opcional):**
    *   `EventStatusUpdateWorker`: Para atualizar periodicamente o status de eventos (ex: de `:scheduled` para `:active`, de `:active` para `:completed`).
    *   `EventNotificationWorker`: Para enviar notificações agendadas sobre eventos (ex: lembretes).

### 3.2. Estrutura de Diretórios (Proposta)

```
lib/deeper_hub/server_events/
├── server_events.ex                  # Fachada Pública
│
├── services/
│   └── server_events_service.ex      # Serviço principal
│
├── schemas/
│   └── event_schema.ex
│
├── storage.ex                        # (Opcional)
│
├── workers/                          # Opcional
│   ├── event_status_update_worker.ex
│   └── event_notification_worker.ex
│
├── cached_adapter.ex                 # (Opcional, da documentação original)
├── supervisor.ex
└── telemetry.ex
```

### 3.3. Decisões de Design Importantes

*   **Datas e Fusos Horários:** Usar `DateTime` com UTC para `start_time` e `end_time` é crucial se os eventos são globais ou se os usuários estão em diferentes fusos horários. Se os eventos são sempre no \"horário do servidor\" e o fuso do servidor é conhecido, `NaiveDateTime` pode ser usado, mas a conversão para exibição ao usuário ainda é necessária.
*   **Status do Evento:** Pode ser um campo persistido atualizado por um worker ou calculado dinamicamente nas queries e na lógica de serviço com base nas datas/horas atuais. Cálculo dinâmico é mais simples, mas menos eficiente para queries de status.
*   **Notificações:** A lógica de quem é notificado (ex: seguidores do servidor, todos os jogadores, etc.) e quando (X horas antes, no início) precisa ser bem definida.

## 🛠️ 4. Casos de Uso Principais

*   **Proprietário de Servidor Agenda uma Manutenção:**
    *   Na UI, define título \"Manutenção Semanal\", descrição, tipo `:maintenance`, `start_time` e `end_time`.
    *   API chama `ServerEvents.create_event(user_id, server_id, event_attrs)`.
    *   O evento é salvo com status `:scheduled`.
    *   Usuários que seguem o servidor são notificados (ex: \"Manutenção agendada para [data]\").
*   **Jogador Verifica Eventos Ativos em um Servidor:**
    *   Na página do servidor, UI chama API que leva a `ServerEvents.list_current_events(server_id)`.
*   **Sistema Inicia um Evento Agendado:**
    *   `EventStatusUpdateWorker` roda.
    *   Encontra eventos cujo `start_time` passou e o status ainda é `:scheduled`.
    *   Atualiza o status para `:active`.
    *   Publica evento `server_event.started` no `Core.EventBus`.
    *   (Opcional) Envia notificações \"Evento X começou!\".

## 🌊 5. Fluxos Importantes

### Fluxo de Criação e Notificação de Novo Evento

1.  **Proprietário (UI):** Submete formulário de novo evento.
2.  **Controller API:** Valida autenticação e autorização (se o usuário é proprietário do servidor). Chama `DeeperHub.ServerEvents.create_event(current_user.id, server_id, params[\"event\"])`.
3.  **`ServerEventsService.create_event/3`:**
    *   Valida os `attrs` (datas, tipo, etc.).
    *   Cria um `EventSchema` changeset.
    *   Se válido, `Core.Repo.insert(changeset)`.
    *   Se sucesso:
        *   Publica evento `server_event.created` no `Core.EventBus` (`%{event_id: new_event.id, server_id: ..., details: ...}`).
        *   (Assíncrono) Enfileira uma tarefa para `EventNotificationWorker` ou chama diretamente `DeeperHub.Notifications` para notificar usuários relevantes (ex: seguidores do `server_id`) sobre o novo evento agendado.
        *   Retorna `{:ok, event_struct}`.
    *   Se falha, retorna erro.

## 📡 6. API (Funções Públicas da Fachada `DeeperHub.ServerEvents`)

### 6.1. Gerenciamento de Eventos (Proprietário/Admin)

*   **`DeeperHub.ServerEvents.create_event(creator_user_id :: String.t(), server_id :: String.t(), attrs :: map()) :: {:ok, Event.t()} | {:error, Ecto.Changeset.t()}`**
    *   `attrs`: `%{title: String.t(), description: String.t(), event_type: atom(), start_time: DateTime.t(), end_time: DateTime.t(), image_url: String.t() | nil}`.
*   **`DeeperHub.ServerEvents.update_event(event_id :: String.t(), attrs :: map(), current_user_id :: String.t()) :: {:ok, Event.t()} | {:error, Ecto.Changeset.t() | :unauthorized}`**
*   **`DeeperHub.ServerEvents.delete_event(event_id :: String.t(), current_user_id :: String.t()) :: :ok | {:error, :unauthorized | :not_found}`**
*   **`DeeperHub.ServerEvents.cancel_event(event_id :: String.t(), reason :: String.t() | nil, current_user_id :: String.t()) :: {:ok, Event.t()} | {:error, term()}` (Nova Sugestão)**
    *   Muda o status para `:cancelled` e notifica.

### 6.2. Consulta de Eventos

*   **`DeeperHub.ServerEvents.get_event(event_id :: String.t()) :: {:ok, Event.t() | nil}`**
*   **`DeeperHub.ServerEvents.list_events_by_server(server_id :: String.t(), opts :: keyword()) :: {:ok, list(Event.t()), Pagination.t()}`**
    *   `opts`: `:status` (`:scheduled`, `:active`, `:completed`, `:cancelled`), `:type`, `:date_range` (`%{start_after: DateTime.t(), end_before: DateTime.t()}`), `:page`, `:per_page`, `:sort_by`.
*   **`DeeperHub.ServerEvents.list_active_events(filters :: map() | nil, opts :: keyword()) :: {:ok, list(Event.t()), Pagination.t()}`**
    *   `filters`: `:server_id`, `:type`. Lista eventos que estão atualmente acontecendo.
*   **`DeeperHub.ServerEvents.list_upcoming_events(filters :: map() | nil, opts :: keyword()) :: {:ok, list(Event.t()), Pagination.t()}`**
    *   `filters`: `:server_id`, `:type`. Lista eventos agendados para o futuro.
*   **`DeeperHub.ServerEvents.get_global_event_calendar(date_range :: map(), filters :: map() | nil) :: {:ok, list(CalendarEvent.t())}` (Nova Sugestão)**
    *   `CalendarEvent.t()`: `%{id: ..., title: ..., start: DateTime.t(), end: DateTime.t(), server_name: ..., color_by_type: ...}`. Para alimentar uma UI de calendário.

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager`:

*   **`[:server_events, :enabled]`** (Boolean).
*   **`[:server_events, :max_event_duration_hours]`** (Integer). (Padrão: `7 * 24` - 1 semana)
*   **`[:server_events, :default_event_types]`** (List de Atoms ou Maps com descrições): Tipos de evento pré-definidos.
*   **`[:server_events, :notification, :notify_before_start_minutes]`** (List de Integers): Quando enviar lembretes (ex: `[60, 15]` - 1 hora e 15 mins antes).
*   **`[:server_events, :cache, :active_events_ttl_seconds]`** (Integer).
*   **`[:server_events, :worker, :status_update_interval_minutes]`** (Integer).

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.*`.
*   `DeeperHub.Servers`: Para `server_id`.
*   `DeeperHub.Accounts`: Para `user_id`.
*   `DeeperHub.Auth`/`RBAC`: Para permissões.
*   `DeeperHub.Notifications`: Para enviar notificações/lembretes.
*   `DeeperHub.UserInteractions` (opcional): Se houver um sistema de \"seguir servidor\" para determinar quem notificar.

### 8.2. Bibliotecas Externas

*   `Ecto`.
*   Biblioteca CRON para workers (ex: `Quantum`).

## 🤝 9. Como Usar / Integração

*   **UI do Proprietário do Servidor:** Formulários para criar/editar eventos.
*   **UI do Jogador (Página do Servidor/Calendário Global):** Exibir listas de eventos (`list_events_by_server`, `list_active_events`, `list_upcoming_events`, `get_global_event_calendar`).
*   **`EventStatusUpdateWorker` e `EventNotificationWorker`:** Operam em background para gerenciar o ciclo de vida e notificações.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar CRUD de `EventSchema`.
*   Testar a lógica de determinação de status do evento (scheduled, active, completed) com base nas datas.
*   Testar as funções de listagem com diferentes filtros e ordenações.
*   Testar a lógica de notificação (com mocks para `DeeperHub.Notifications`).
*   Testar os workers.
*   Localização: `test/deeper_hub/server_events/`.

### 10.2. Métricas

*   `deeper_hub.server_events.created.count` (tags: `server_id`, `event_type`)
*   `deeper_hub.server_events.status_changed.count` (tags: `event_id`, `new_status`)
*   `deeper_hub.server_events.active_now.gauge` (Gauge, tags: `server_id` (opcional), `event_type`)
*   `deeper_hub.server_events.notifications_sent.count` (tags: `event_id`, `notification_trigger` (`new`, `reminder`, `started`))

### 10.3. Logs

*   **Nível INFO:** Evento criado, iniciado, concluído, cancelado. Notificação de evento enviada.
*   **Nível WARNING:** Tentativa não autorizada de gerenciar um evento.
*   **Nível ERROR:** Falha ao persistir evento. Erro no worker de atualização de status.

### 10.4. Telemetria

*   `[:deeper_hub, :server_events, :event, :created | :updated | :deleted | :cancelled]`
    *   Metadados: `%{event_id: id, server_id: id, user_id: id, type: type}`
*   `[:deeper_hub, :server_events, :event, :status_transition]`
    *   Metadados: `%{event_id: id, old_status: atom, new_status: atom}`
*   `[:deeper_hub, :server_events, :notification, :dispatch_attempt]`
    *   Metadados: `%{event_id: id, notification_type: type, recipient_count: count}`

## ❌ 11. Tratamento de Erros

*   Falhas na criação/atualização de eventos devido a dados inválidos retornam `{:error, changeset}`.
*   Operações não autorizadas retornam `{:error, :unauthorized}`.
*   Se um worker de notificação falhar, a notificação pode ser perdida ou reenfileirada, mas o evento em si deve permanecer consistente.

## 🛡️ 12. Considerações de Segurança

*   **Autorização:** Apenas proprietários de servidores ou administradores com permissão devem poder criar/gerenciar eventos para um servidor.
*   **Validação de Conteúdo:** Títulos e descrições de eventos devem ser validados/sanitizados para prevenir XSS se forem exibidos diretamente.
*   **Abuso:** Limitar a frequência com que um proprietário pode criar eventos ou o número de eventos ativos por servidor para evitar spam.

## 🧑‍💻 13. Contribuição

*   Ao adicionar novos tipos de eventos, certifique-se de que a lógica de notificação e, possivelmente, os templates sejam atualizados.
*   Considere a performance das queries de listagem de eventos, especialmente para calendários globais.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Permitir que usuários se inscrevam (\"RSVP\") para eventos específicos e recebam lembretes mais personalizados.
*   [ ] Integração com calendários externos (Google Calendar, iCal).
*   [ ] Suporte para eventos recorrentes (ex: \"Toda sexta-feira às 20h\").
*   [ ] Permitir que proprietários de servidores \"destaquem\" certos eventos.
*   [ ] Adicionar um feed de \"Próximos Eventos\" na dashboard do usuário para os servidores que ele segue/favorita.
*   [ ] Lógica para sugerir horários para eventos baseados na atividade dos jogadores do servidor.

---

*Última atualização: 2025-05-12*

---

Eventos de servidor são uma ótima forma de manter a comunidade engajada!

Próximo? Que tal `DeeperHub.ServerUpdateMessages` para mensagens de patch notes e atualizações, ou `DeeperHub.ServerPackages` para itens/VIPs? Ou algo do Core que ainda não detalhamos, como `DeeperHub.Core.EncryptionService` de forma mais aprofundada?"""),
            ],
        ),
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(text="""continue"""),
            ],
        ),
        types.Content(
            role="model",
            parts=[
                types.Part.from_text(text="""Ok, vamos continuar com os módulos relacionados a `Servers` e detalhar o `DeeperHub.ServerUpdateMessages`. Este módulo permite que proprietários de servidores comuniquem atualizações e novidades para sua comunidade.

---

