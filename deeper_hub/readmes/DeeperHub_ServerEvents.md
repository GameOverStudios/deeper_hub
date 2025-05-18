# Módulo: `DeeperHub.ServerEvents` 📅

## 📜 1. Visão Geral do Módulo `DeeperHub.ServerEvents`

O módulo `DeeperHub.ServerEvents` é responsável por gerenciar eventos que ocorrem dentro dos servidores listados na plataforma DeeperHub. Ele permite que proprietários de servidores criem, agendem e anunciem eventos para suas comunidades, como torneios, manutenções programadas, eventos temáticos, transmissões ao vivo, etc. Os usuários podem visualizar os eventos futuros e ativos dos servidores que lhes interessam. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Criação e Gerenciamento de Eventos de Servidor:**
    *   CRUD para Eventos (`Event`): título, descrição, tipo de evento, data e hora de início, data e hora de término (ou duração).
    *   Associação do evento a um servidor específico (`server_id`).
    *   Informações adicionais como link para o evento (ex: link do Discord, Twitch), prêmios (se houver), requisitos de participação.
*   **Agendamento de Eventos:**
    *   Permitir que eventos sejam agendados para datas futuras.
    *   Gerenciar o ciclo de vida de um evento (ex: Agendado, Em Andamento, Concluído, Cancelado).
*   **Listagem e Descoberta de Eventos:**
    *   Permitir que usuários vejam eventos futuros e em andamento para servidores específicos.
    *   Fornecer uma listagem global de eventos em destaque ou filtrados por categoria/tipo.
    *   Busca de eventos por nome, servidor, tipo, etc.
*   **Calendário de Eventos (Opcional):**
    *   Fornecer uma visualização de calendário para eventos de servidores que o usuário segue ou favoritou.
*   **RSVP / Manifestação de Interesse (Opcional):**
    *   Permitir que usuários marquem interesse ou confirmem presença em eventos.
*   **Notificações:**
    *   Notificar usuários (que seguem o servidor ou marcaram interesse) sobre o início de eventos, alterações ou cancelamentos (via `DeeperHub.Notifications`).
*   **Recorrência de Eventos (Opcional):**
    *   Suporte para criar eventos que se repetem (diariamente, semanalmente, mensalmente).
*   **Administração e Moderação:**
    *   Interface para proprietários de servidores gerenciarem os eventos de seus servidores.
    *   Interface para administradores da plataforma moderarem eventos, se necessário.

## 🏗️ 3. Arquitetura e Design

`DeeperHub.ServerEvents` atuará como uma fachada para um serviço de lógica de negócio e componentes de persistência.

*   **Interface Pública (`DeeperHub.ServerEvents.ServerEventsFacade` ou `DeeperHub.ServerEvents`):** Funções como `create_event/1`, `list_active_events_for_server/2`, `get_upcoming_events/1`.
*   **Serviço de Eventos de Servidor (`DeeperHub.ServerEvents.Services.EventService`):**
    *   Contém a lógica de negócio principal para gerenciar definições, agendamento, e ciclo de vida dos eventos.
*   **Schemas Ecto:**
    *   `DeeperHub.ServerEvents.Schema.Event`: Define um evento de servidor.
    *   `DeeperHub.ServerEvents.Schema.UserEventInterest` (Opcional): Para rastrear interesse/RSVP dos usuários.
*   **Cache (`DeeperHub.ServerEvents.Cache` ou via `Core.Cache`):**
    *   Cache para eventos ativos ou futuros frequentemente requisitados.
*   **Workers (via `Core.BackgroundTaskManager`):**
    *   Worker para atualizar o status de eventos (ex: de agendado para em andamento, de em andamento para concluído).
    *   Worker para enviar lembretes de eventos.
*   **Integrações:**
    *   `DeeperHub.Core.Repo`: Para persistência.
    *   `DeeperHub.Servers`: Para associar eventos a servidores.
    *   `DeeperHub.Accounts`: Para associar eventos a usuários criadores.
    *   `DeeperHub.Notifications`: Para enviar notificações e lembretes.

**Padrões de Design:**

*   **Fachada (Facade).**
*   **Serviço de Domínio.**

### 3.1. Componentes Principais

*   **`DeeperHub.ServerEvents.ServerEventsFacade`:** Ponto de entrada.
*   **`DeeperHub.ServerEvents.Services.EventService`:** Lógica de negócio.
*   **`DeeperHub.ServerEvents.Schema.Event`:** Schema do evento.
*   **`DeeperHub.ServerEvents.Supervisor`:** Supervisiona processos.
*   **Workers (ex: `EventStatusUpdaterWorker`, `EventReminderWorker`).**

### 3.3. Decisões de Design Importantes

*   **Gerenciamento de Fuso Horário:** Datas e horas de eventos devem ser armazenadas em UTC e convertidas para o fuso horário do usuário ou do servidor para exibição.
*   **Recorrência:** Se a recorrência for implementada, escolher uma biblioteca ou lógica robusta para gerenciar as instâncias de eventos recorrentes.
*   **Escopo de Visibilidade:** Definir quem pode ver quais eventos (públicos, apenas para membros do servidor, etc.).

## 🛠️ 4. Casos de Uso Principais

*   **Proprietário de Servidor Agenda um Torneio:** O dono de um servidor de jogos cria um evento \"Torneio Semanal de PvP\" para o próximo sábado.
*   **Usuário Procura Eventos de Fim de Semana:** Um usuário navega na plataforma buscando por eventos de servidores que acontecerão no próximo fim de semana.
*   **Sistema Envia Lembrete de Evento:** Usuários que marcaram interesse em um evento recebem uma notificação 1 hora antes de seu início.
*   **Evento Começa e Termina:** Um worker atualiza o status do evento de \"Agendado\" para \"Em Andamento\" quando a hora de início chega, e para \"Concluído\" após a hora de término.

## 🌊 5. Fluxos Importantes (Opcional)

**Fluxo de Atualização de Status de Evento por Worker:**

1.  `EventStatusUpdaterWorker` é executado periodicamente (ex: a cada minuto).
2.  O worker consulta o `EventService` (ou `Core.Repo` diretamente) por eventos:
    *   Agendados cuja `start_time` já passou.
    *   Em andamento cuja `end_time` já passou.
3.  Para cada evento agendado que deve iniciar:
    *   `EventService.update_event_status(event_id, :in_progress)` é chamado.
    *   Um evento `ServerEventStartedEvent` é publicado no `Core.EventBus`.
    *   Notificações de \"evento começando agora\" podem ser disparadas.
4.  Para cada evento em andamento que deve terminar:
    *   `EventService.update_event_status(event_id, :completed)` é chamado.
    *   Um evento `ServerEventEndedEvent` é publicado.
5.  O worker registra suas ações e agenda a próxima execução.

## 📡 6. API (Se Aplicável)

### 6.1. `DeeperHub.ServerEvents.create_event/1`

*   **Descrição:** Cria um novo evento para um servidor.
*   **`@spec`:** `create_event(attrs :: map()) :: {:ok, Event.t()} | {:error, Ecto.Changeset.t() | reason}`
*   **Parâmetros:**
    *   `attrs` (map): Atributos do evento.
        *   `:server_id` (String, obrigatório): ID do servidor que hospeda o evento.
        *   `:created_by_user_id` (String, obrigatório): ID do usuário que está criando o evento.
        *   `:title` (String, obrigatório): Título do evento.
        *   `:description` (String, opcional): Descrição detalhada do evento.
        *   `:start_time` (DateTime.t(), obrigatório): Data e hora de início do evento (UTC).
        *   `:end_time` (DateTime.t(), opcional): Data e hora de término. Se não fornecido, pode ser um evento de duração indefinida ou curta.
        *   `:event_type` (String, opcional): Categoria do evento (ex: \"torneio\", \"manutencao\", \"live_stream\").
        *   `:metadata` (map, opcional): Dados adicionais (ex: link, prêmios).
*   **Retorno:** O evento criado ou um changeset com erros.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    event_attrs = %{
      server_id: \"server_123\",
      created_by_user_id: \"user_abc\",
      title: \"Grande Torneio de Verão\",
      start_time: ~U[2025-07-15 18:00:00Z],
      end_time: ~U[2025-07-15 22:00:00Z],
      event_type: \"torneio\"
    }
    case DeeperHub.ServerEvents.create_event(event_attrs) do
      {:ok, event} -> Logger.info(\"Evento #{event.id} criado para o servidor #{event.server_id}\")
      {:error, reason} -> Logger.error(\"Falha ao criar evento: #{inspect(reason)}\")
    end
    ```

### 6.2. `DeeperHub.ServerEvents.list_events_by_server/2`

*   **Descrição:** Lista eventos para um servidor específico, com opções de filtro.
*   **`@spec`:** `list_events_by_server(server_id :: String.t(), opts :: Keyword.t()) :: {:ok, list(Event.t())} | {:error, reason}`
*   **Parâmetros:**
    *   `server_id` (String): O ID do servidor.
    *   `opts` (Keyword.t()): Opções de filtragem.
        *   `:status` (atom): Filtrar por status (ex: `:scheduled`, `:in_progress`, `:completed`).
        *   `:upcoming_only` (boolean): Retornar apenas eventos futuros.
        *   `:date_range` ({DateTime.t(), DateTime.t()}): Filtrar por eventos dentro de um intervalo de datas.
        *   `:limit` (integer), `:offset` (integer): Para paginação.
*   **Retorno:** Lista de eventos do servidor.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    {:ok, upcoming_events} = DeeperHub.ServerEvents.list_events_by_server(\"server_123\", upcoming_only: true, limit: 5)
    ```

*(Outras funções como `get_event/1`, `update_event/2`, `cancel_event/1`, `mark_interest_in_event/2` seriam documentadas aqui).*

## ⚙️ 7. Configuração

*   **ConfigManager (`DeeperHub.Core.ConfigManager`):**
    *   `[:server_events, :default_event_duration_hours]`: Duração padrão para eventos sem `end_time` explícito. (Padrão: `2`)
    *   `[:server_events, :reminder_before_minutes]`: Com quantos minutos de antecedência enviar lembretes. (Padrão: `60`)
    *   `[:server_events, :worker, :status_update_interval_minutes]`: Intervalo para o worker atualizar status de eventos. (Padrão: `1`)
    *   `[:server_events, :max_upcoming_events_per_server_display]`: Limite padrão para exibir eventos futuros de um servidor.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.Repo`
*   `DeeperHub.Core.ConfigManager`
*   `DeeperHub.Core.EventBus`
*   `DeeperHub.Core.BackgroundTaskManager`
*   `DeeperHub.Notifications`
*   `DeeperHub.Servers`
*   `DeeperHub.Accounts`
*   `DeeperHub.Core.Logger`, `DeeperHub.Core.Metrics`

### 8.2. Bibliotecas Externas

*   `Ecto`
*   Opcionalmente, uma biblioteca para lidar com recorrência de eventos (ex: `RecurlyEx` - embora esta seja mais para pagamentos, ou uma lib de iCalendar).

## 🤝 9. Como Usar / Integração

*   **UI/Frontend:** Exibe listas de eventos, calendários, permite criação (para donos de servidor) e RSVP.
*   **Módulo `Servers`:** Pode exibir os próximos eventos na página de detalhes de um servidor.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar criação, atualização, cancelamento de eventos.
*   Testar a lógica de transição de status (agendado -> em andamento -> concluído).
*   Testar a listagem com diferentes filtros e ordenações.
*   Testar o envio de notificações de lembrete.
*   Localização: `test/deeper_hub/server_events/`

### 10.2. Métricas

*   `deeper_hub.server_events.created.count` (Contador): Tags: `server_id`, `event_type`.
*   `deeper_hub.server_events.status_changed.count` (Contador): Tags: `event_id`, `new_status`.
*   `deeper_hub.server_events.reminders_sent.count` (Contador): Tags: `event_id`.
*   `deeper_hub.server_events.active.gauge` (Gauge): Número de eventos atualmente em andamento.

### 10.3. Logs

*   `Logger.info(\"Evento '#{title}' (ID: #{id}) criado para o servidor #{server_id}\", module: DeeperHub.ServerEvents.Services.EventService)`
*   `Logger.info(\"Status do evento #{id} alterado para #{status}\", module: DeeperHub.ServerEvents.Workers.EventStatusUpdaterWorker)`

### 10.4. Telemetria

*   `[:deeper_hub, :server_events, :created | :updated | :deleted | :status_changed]`
*   `[:deeper_hub, :server_events, :reminder_sent]`

## ❌ 11. Tratamento de Erros

*   `{:error, :server_not_found}`
*   `{:error, :event_not_found}`
*   `{:error, :invalid_date_range}` (ex: `end_time` antes de `start_time`)
*   Falhas na validação dos dados do evento.

## 🛡️ 12. Considerações de Segurança

*   **Validação de Conteúdo:** Títulos e descrições de eventos devem ser sanitizados para prevenir XSS.
*   **Permissões de Criação/Edição:** Apenas proprietários de servidor ou usuários com permissão específica devem poder criar/editar eventos para um servidor.
*   **Abuso:** Monitorar a criação excessiva de eventos ou eventos com conteúdo inadequado.

## 🧑‍💻 13. Contribuição

*   Novos tipos de eventos ou funcionalidades de calendário podem ser adicionados.
*   A lógica de recorrência, se implementada, deve ser robusta.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar sistema de RSVP/manifestação de interesse.
*   [ ] Adicionar suporte completo para eventos recorrentes.
*   [ ] Integração com calendários externos (Google Calendar, iCal).
*   [ ] Permitir que usuários exportem eventos para seus calendários.
*   [ ] Interface de administração para gerenciar todos os eventos da plataforma.
*   [ ] Sugestões de eventos baseadas nos interesses do usuário.

---

*Última atualização: YYYY-MM-DD*

---

Próximo na lista é `DeeperHub.ServerPackages`. Continuamos?"""),
            ],
        ),
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(text="""SIM!"""),
            ],
        ),
        types.Content(
            role="model",
            parts=[
                types.Part.from_text(text="""Beleza! Vamos para o README do `DeeperHub.ServerPackages`.

---

