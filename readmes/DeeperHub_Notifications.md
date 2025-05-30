# Módulo: `DeeperHub.Notifications` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Notifications`

O módulo `DeeperHub.Notifications` é o sistema centralizado para **gerenciar e entregar notificações** aos usuários do DeeperHub através de múltiplos canais. Ele permite que diferentes partes da aplicação enviem mensagens importantes, alertas, lembretes ou atualizações para os usuários de forma consistente e configurável.

As notificações podem ser enviadas por canais como email, SMS (opcional), notificações push para aplicativos móveis, e notificações in-app (dentro da própria interface web/mobile do DeeperHub). O sistema também gerencia as preferências de notificação dos usuários, permitindo que eles escolham quais tipos de notificações desejam receber e por quais canais. 😊

*(Nota: A documentação original tem `DeeperHub.Core.NotificationsFacade`, `DeeperHub.Notifications` (módulo principal), `Services.DefaultNotificationService`, `Channels`, `Cache`, `Templates`, `Workers`, etc. Esta documentação consolida a fachada em `DeeperHub.Notifications` e organiza os componentes internos.)*

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Envio de Notificações Multicanal:**
    *   Enviar notificações através de canais configurados: Email, In-App, Push (e opcionalmente SMS, Slack, etc.).
    *   Abstrair a complexidade de cada canal de entrega.
*   **Gerenciamento de Conteúdo e Templates (`Templates.TemplateManager`):**
    *   Utilizar templates para formatar o conteúdo das notificações.
    *   Suporte à internacionalização (i18n) de templates (`Templates.I18n.Translator`).
*   **Gerenciamento de Preferências do Usuário (`Services.PreferencesService`):**
    *   Permitir que usuários configurem quais tipos de notificações desejam receber em cada canal.
    *   Respeitar as preferências do usuário ao decidir se e como enviar uma notificação.
*   **Agendamento de Notificações (`Core.Notifications.Scheduler`):**
    *   Permitir o agendamento de notificações para serem enviadas em um momento futuro.
*   **Rastreamento e Histórico de Notificações (`Services.HistoryService`):**
    *   Manter um histórico das notificações enviadas aos usuários.
    *   Rastrear o status de entrega (enviada, entregue, falha, lida - se possível).
    *   Permitir que usuários visualizem seu histórico de notificações.
*   **Notificações In-App (`Channels.InAppChannel`):**
    *   Armazenar e exibir notificações dentro da interface da aplicação.
    *   Gerenciar o status de \"lida/não lida\" para notificações in-app.
*   **Processamento Assíncrono (`Workers`):**
    *   Enviar notificações (especialmente email e push) de forma assíncrona para não bloquear o fluxo principal da aplicação.
*   **Observabilidade e Métricas (`Telemetry`, `Metrics.MetricsReporter`):**
    *   Registrar métricas sobre o volume de notificações enviadas, taxas de entrega, taxas de abertura (se rastreável), erros.
    *   Logar atividades importantes e falhas.
*   **Limpeza de Dados Antigos (`Workers.RetentionWorker`):**
    *   Remover registros de notificações antigas conforme políticas de retenção.
*   **Integração com Eventos do Sistema (`Integrations.EventIntegration`):**
    *   Escutar eventos do `Core.EventBus` (ex: `user.created`, `password.reset_requested`) para disparar notificações relevantes automaticamente.
    *   Publicar eventos sobre o ciclo de vida das notificações (ex: `notification.sent`, `notification.read`).
*   **Notificações de Segurança (`Services.SecurityNotificationService`, `TokenNotifications`):**
    *   Enviar notificações críticas relacionadas à segurança da conta do usuário.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.Notifications` (Fachada Pública):**
    *   Ponto de entrada principal para enviar notificações e gerenciar preferências.
    *   Delega para `NotificationService` (ou `DefaultNotificationService`).
2.  **`DeeperHub.Notifications.Services.DefaultNotificationService` (GenServer ou Serviço Coordenador):**
    *   **Responsabilidade:** Orquestra o processo de envio de notificações.
    *   **Interações:**
        *   `PreferencesService`: Para verificar as preferências do usuário.
        *   `TemplateManager`: Para renderizar o conteúdo da notificação.
        *   `Channel Adapters/Handlers` (ex: `EmailChannel`, `PushChannel`, `InAppChannel`): Para despachar a notificação para o canal apropriado.
        *   `Core.BackgroundTaskManager`: Para enfileirar o envio de notificações assíncronas.
        *   `HistoryService`: Para registrar a notificação enviada.
        *   `Core.ConfigManager`: Para configurações do sistema de notificações.
3.  **`DeeperHub.Notifications.Services.PreferencesService`:**
    *   Gerencia as preferências de notificação dos usuários (CRUD e consulta).
    *   Utiliza `DeeperHub.Notifications.Cache.PreferencesCache`.
4.  **`DeeperHub.Notifications.Services.HistoryService`:**
    *   Gerencia o histórico de notificações (CRUD e consulta).
5.  **`DeeperHub.Notifications.Templates.TemplateManager`:**
    *   Responsável por carregar, renderizar e cachear templates de notificação.
    *   Usa `Templates.I18n.Translator` para internacionalização.
6.  **`DeeperHub.Notifications.Channels.<ChannelName>Channel` (Behaviours e Implementações):**
    *   Cada canal (Email, Push, InApp, SMS) tem seu próprio módulo que implementa um `NotificationChannelBehaviour`.
    *   Ex: `EmailChannel` usa `DeeperHub.Mailer` para enviar emails.
    *   Ex: `PushChannel` interage com serviços como FCM/APNS.
7.  **`DeeperHub.Core.Notifications.Scheduler` (GenServer):**
    *   Gerencia o agendamento e disparo de notificações futuras.
8.  **Workers (`EmailWorker`, `PushWorker`, `InAppWorker`, `RetentionWorker`, `MetricsWorker`):**
    *   Processam o envio real de notificações, coletam métricas, limpam dados antigos.
9.  **Schemas Ecto:**
    *   `DeeperHub.Notifications.Schema.Notification`: Entidade principal da notificação.
    *   `DeeperHub.Notifications.Schema.NotificationPreference`: Preferências do usuário.
    *   `DeeperHub.Notifications.Schema.ScheduledNotification`: Notificações agendadas.
    *   `DeeperHub.Notifications.Schema.NotificationDelivery`: (Opcional) Para rastrear o status de entrega por canal.
10. **Cache (`PreferencesCache`, `TemplateCache`):**
    *   Para otimizar o acesso a preferências e templates renderizados.
11. **Integrações (`AuditIntegration`, `EventIntegration`):**
    *   Para logar no sistema de auditoria e interagir com o EventBus.

### 3.2. Estrutura de Diretórios (Proposta)

```
notifications/
├── notifications.ex                  # Fachada Pública
│
├── services/
│   ├── default_notification_service.ex
│   ├── preferences_service.ex
│   ├── history_service.ex
│   └── security_notification_service.ex # (Ou TokenNotifications.ex)
│
├── channels/
│   ├── notification_channel_behaviour.ex
│   ├── email_channel.ex
│   ├── in_app_channel.ex
│   └── push_channel.ex
│   #├── sms_channel.ex (Opcional)
│
├── templates/
│   ├── template_manager.ex
│   ├── i18n/
│   │   ├── translator.ex
│   │   └── pt_br.ex # Exemplo de arquivo de tradução
│   └── email/ # Subdiretório para templates de email
│       └── welcome_email.html.eex
│
├── schemas/                          # (Ou schema/ singular)
│   ├── notification.ex
│   ├── notification_preference.ex
│   ├── scheduled_notification.ex
│   └── notification_delivery.ex      # Opcional
│
├── workers/
│   ├── email_worker.ex
│   ├── push_worker.ex
│   ├── in_app_worker.ex
│   ├── retention_worker.ex
│   └── metrics_worker.ex             # Para coletar métricas periódicas do sistema de notificações
│
├── cache/
│   ├── preferences_cache.ex
│   └── template_cache.ex
│
├── integrations/
│   ├── audit_integration.ex
│   └── event_integration.ex
│
├── scheduler.ex                      # (Core.Notifications.Scheduler)
├── supervisor.ex                     # Supervisor principal do módulo Notifications
├── unified_supervisor.ex             # Supervisor que inicia o supervisor principal
└── telemetry.ex
```

### 3.3. Decisões de Design Importantes

*   **Desacoplamento de Canais:** A lógica de envio para cada canal é isolada em seu próprio módulo, facilitando a adição ou modificação de canais.
*   **Processamento Assíncrono:** O envio de notificações (especialmente email/push) é feito em background para não impactar a performance da requisição original.
*   **Preferências do Usuário em Primeiro Lugar:** O sistema deve sempre respeitar as preferências do usuário antes de enviar uma notificação.
*   **Templates e I18n:** Usar templates e internacionalização torna as notificações flexíveis e personalizáveis.
*   **Rastreabilidade:** Manter um histórico e status de entrega é importante para diagnóstico e para o usuário.

## 🛠️ 4. Casos de Uso Principais

*   **Novo Usuário se Registra:**
    *   `DeeperHub.Accounts` publica evento `user.created`.
    *   `Notifications.Integrations.EventIntegration` (ou um listener específico) recebe o evento.
    *   Chama `Notifications.send_notification(user_id, :welcome_email, %{name: user.name}, opts)` (o tipo `:welcome_email` define o template e canais padrão).
    *   `DefaultNotificationService` verifica preferências, renderiza o template e enfileira a tarefa de envio para `EmailWorker`.
*   **Alerta de Segurança: Login de Novo Dispositivo:**
    *   `DeeperHub.Security` detecta o novo dispositivo.
    *   Chama `Notifications.Services.SecurityNotificationService.notify_new_device(user_id, device_info, opts)`.
    *   Esta função pode ter canais prioritários (ex: email e push) e um template específico.
*   **Lembrete de Tarefa Agendada:**
    *   Uma tarefa foi agendada para notificar o usuário.
    *   `Core.Notifications.Scheduler` dispara a notificação no momento correto.
    *   Chama `Notifications.send_notification(...)`.
*   **Usuário Atualiza Preferências de Notificação:**
    *   Usuário desmarca notificações por email para \"novidades\".
    *   UI chama `Notifications.update_notification_preferences(user_id, new_preferences)`.
    *   `PreferencesService` atualiza e invalida o cache.

## 🌊 5. Fluxos Importantes

### Fluxo de Envio de Notificação (Exemplo: Email)

1.  **Chamador (ex: `AccountsService`):** Chama `DeeperHub.Notifications.send_notification(user_id, :user_registered, %{user_name: \"John\"}, opts)`.
2.  **`Notifications` (Fachada):** Delega para `DefaultNotificationService`.
3.  **`DefaultNotificationService`:**
    *   Chama `PreferencesService.get_user_preferences(user_id)` para ver se o usuário quer receber notificações do tipo `:user_registered` e por quais canais.
    *   Se o canal email estiver habilitado para este tipo:
        *   Chama `TemplateManager.render_email_template(\"user_registered_email\", locale, %{user_name: \"John\", ...})` para obter o assunto e corpo do email.
        *   Chama `TemplateManager.get_email_subject(\"user_registered_email\", locale)`.
        *   Cria uma struct `Notification` com os detalhes.
        *   Persiste a `Notification` via `HistoryService` (ou diretamente via Repo).
        *   Enfileira uma tarefa para `DeeperHub.Notifications.Workers.EmailWorker` via `Core.BackgroundTaskManager` passando o `notification_id` ou todos os dados do email.
4.  **`EmailWorker` (Background Task):**
    *   Recebe a tarefa.
    *   Busca os detalhes da notificação (se apenas o ID foi passado).
    *   Chama `DeeperHub.Mailer.send_email(%{to: user.email, subject: ..., body: ...})`.
    *   Atualiza o status da `Notification` (e/ou `NotificationDelivery`) para `:sent` ou `:failed` via `HistoryService`.
    *   Publica evento `notification.sent` ou `notification.failed` via `Core.EventBus`.

## 📡 6. API (Funções Públicas da Fachada `DeeperHub.Notifications`)

*(Muitas já foram vistas na documentação original de `NotificationsFacade` e `Core.NotificationsFacade`. Consolidando e refinando.)*

### 6.1. `DeeperHub.Notifications.send_notification(user_id :: String.t(), notification_type :: atom(), content_data :: map(), opts :: keyword()) :: {:ok, Notification.t() | list(Notification.t())} | {:error, term()}`

*   **Descrição:** Envia uma notificação para um usuário. O `notification_type` é usado para buscar o template, determinar os canais padrão e respeitar as preferências do usuário.
*   **`content_data`:** Mapa com variáveis para o template.
*   **`opts`:**
    *   `:channels` (list(atom)): Força o envio por canais específicos, ignorando algumas preferências (usar com cautela). Ex: `[:email, :in_app]`.
    *   `:priority` (atom): `:low`, `:normal`, `:high`.
    *   `:metadata` (map): Metadados adicionais.
*   **Retorno:** Pode retornar a `Notification` criada ou uma lista se for para múltiplos canais/entregas.

### 6.2. `DeeperHub.Notifications.send_bulk_notification(user_ids :: list(String.t()), notification_type :: atom(), content_data :: map(), opts :: keyword()) :: {:ok, BulkNotificationJob.t()} | {:error, term()}`

*   **Descrição:** Envia a mesma notificação para múltiplos usuários. Geralmente enfileira um job de background.
*   **`BulkNotificationJob.t()`:** Uma struct com informações sobre o job em lote.

### 6.3. `DeeperHub.Notifications.schedule_notification(user_id :: String.t(), notification_type :: atom(), content_data :: map(), scheduled_at :: DateTime.t(), opts :: keyword()) :: {:ok, ScheduledNotification.t()} | {:error, term()}`

*   **Descrição:** Agenda uma notificação para envio futuro.

### 6.4. `DeeperHub.Notifications.cancel_scheduled_notification(scheduled_notification_id :: String.t(), opts :: keyword()) :: :ok | {:error, :not_found | term()}`

*   **Descrição:** Cancela uma notificação agendada.

### 6.5. `DeeperHub.Notifications.get_user_notification_preferences(user_id :: String.t()) :: {:ok, NotificationPreference.t()} | {:error, term()}`

*   **Descrição:** Obtém as preferências de notificação de um usuário.

### 6.6. `DeeperHub.Notifications.update_user_notification_preferences(user_id :: String.t(), preferences_map :: map()) :: {:ok, NotificationPreference.t()} | {:error, Ecto.Changeset.t()}`

*   **Descrição:** Atualiza as preferências de notificação de um usuário.
*   **`preferences_map`:** Ex: `%{email: %{marketing_updates: false, security_alerts: true}, push: %{all_enabled: true}}`.

### 6.7. `DeeperHub.Notifications.get_unread_notifications(user_id :: String.t(), opts :: keyword()) :: {:ok, list(Notification.t()), Pagination.t()}`

*   **Descrição:** Obtém notificações in-app não lidas para um usuário.
*   **`opts`:** `:channel` (se houver múltiplos tipos de in-app), `:limit`, `:page`.

### 6.8. `DeeperHub.Notifications.mark_notification_as_read(notification_id :: String.t(), user_id :: String.t()) :: :ok | {:error, :not_found | :unauthorized}`

*   **Descrição:** Marca uma notificação específica (geralmente in-app) como lida.

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager`:

*   **`[:notifications, :enabled]`** (Boolean): Habilita/desabilita o sistema de notificações.
*   **`[:notifications, :default_channels, <notification_type>]`** (List de Atoms): Canais padrão para um tipo de notificação se o usuário não tiver preferências (ex: `%{user_registered: [:email, :in_app]}`).
*   **`[:notifications, :channels, :email, :adapter]`** (Module): Adaptador para envio de email (ex: `DeeperHub.Mailer`).
*   **`[:notifications, :channels, :email, :from_address]`** (String).
*   **`[:notifications, :channels, :push, :fcm_api_key]`** (String).
*   **`[:notifications, :channels, :sms, :provider_api_key]`** (String).
*   **`[:notifications, :templates, :base_path]`** (String): Caminho para os arquivos de template.
*   **`[:notifications, :templates, :cache_ttl_seconds]`** (Integer).
*   **`[:notifications, :preferences_cache, :ttl_seconds]`** (Integer).
*   **`[:notifications, :scheduler, :check_interval_seconds]`** (Integer).
*   **`[:notifications, :retention, :history_days]`** (Integer): Por quantos dias manter o histórico de notificações.
*   **`[:notifications, :retention, :scheduled_cleanup_days]`** (Integer): Por quantos dias manter scheduled notifications antigas.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.ConfigManager`, `Core.EventBus`, `Core.Logger`, `Core.Metrics`, `Core.Repo`, `Core.Cache`, `Core.BackgroundTaskManager`.
*   `DeeperHub.Mailer`: Para o canal de email.
*   `DeeperHub.Accounts`: Para obter informações do usuário (email, device tokens para push).
*   `DeeperHub.Audit` (via `Integrations.AuditIntegration`).

### 8.2. Bibliotecas Externas

*   Bibliotecas de template (EEx é nativo, mas outras como `NimblePublisher` para markdown podem ser usadas).
*   Bibliotecas cliente para serviços de Push (FCM, APNS) ou SMS, se usados.
*   `Jason` para payloads de push.

## 🤝 9. Como Usar / Integração

*   **Disparar Notificações a Partir de Eventos:** Criar listeners do `Core.EventBus` que chamam `Notifications.send_notification`.
    ```elixir
    # Em um módulo listener
    def handle_event(\"user.password_reset_requested\", %{user_id: user_id, reset_token: token}, _metadata) do
      DeeperHub.Notifications.send_notification(
        user_id, 
        :password_reset_instruction, 
        %{reset_link: \"https://.../#{token}\"}
      )
    end
    ```
*   **Envio Direto de Serviços:**
    ```elixir
    # Em DeeperHub.Support.TicketService
    def assign_ticket_to_agent(ticket_id, agent_id) do
      # ... lógica ...
      DeeperHub.Notifications.send_notification(
        agent_id, 
        :ticket_assigned_to_you, 
        %{ticket_id: ticket_id, ticket_subject: ticket.subject}
      )
      # ...
    end
    ```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar o envio de notificações para cada canal (com mocks para serviços externos).
*   Testar a lógica de preferências do usuário (usuário recebe/não recebe conforme configurado).
*   Testar a renderização de templates com diferentes dados e locales.
*   Testar o agendamento e cancelamento de notificações.
*   Testar a marcação de \"lida\" para notificações in-app.
*   Testar os workers de envio e limpeza.
*   Localização: `test/deeper_hub/notifications/`.

### 10.2. Métricas

*   `deeper_hub.notifications.sent.count` (tags: `channel`, `notification_type`, `status` (`success`, `failed`))
*   `deeper_hub.notifications.delivery.duration_ms` (Histograma, tags: `channel`)
*   `deeper_hub.notifications.scheduled.enqueued.count`
*   `deeper_hub.notifications.in_app.read.count`
*   `deeper_hub.notifications.preferences.updated.count`
*   `deeper_hub.notifications.template.render.duration_ms` (Histograma, tags: `template_name`)

### 10.3. Logs

*   **Nível INFO:** Notificação enfileirada, enviada com sucesso, agendada. Preferências atualizadas.
*   **Nível WARNING:** Falha temporária no envio para um canal (com retentativa). Template não encontrado.
*   **Nível ERROR:** Falha persistente no envio para um canal. Erro ao renderizar template. Erro crítico no serviço de notificações.

### 10.4. Telemetria

*   `[:deeper_hub, :notifications, :dispatch, :start | :stop | :exception]`
    *   Metadados: `%{user_id: id, notification_type: type, channels: list}`
*   `[:deeper_hub, :notifications, :delivery_attempt, :start | :stop | :exception]`
    *   Metadados: `%{notification_id: id, channel: channel, attempt: num}`
    *   No `:stop`: `%{status: :success | :failure, error_reason: reason_if_any}`
*   `[:deeper_hub, :notifications, :preference, :queried | :updated]`
    *   Metadados: `%{user_id: id}`

## ❌ 11. Tratamento de Erros

*   **Falha no Canal de Entrega:** Se um canal (ex: servidor SMTP) estiver indisponível, o worker correspondente deve registrar o erro e tentar novamente conforme a política de retry. Falhas em um canal não devem impedir o envio por outros canais para a mesma notificação.
*   **Usuário Sem Preferências ou Informações de Contato:** O sistema deve lidar graciosamente (ex: não enviar, logar aviso) se não houver como contatar o usuário por um canal selecionado.
*   **Template Inválido/Ausente:** Logar erro e possivelmente enviar uma notificação genérica/padrão, ou não enviar por aquele canal.

## 🛡️ 12. Considerações de Segurança

*   **Conteúdo das Notificações:** Dados sensíveis não devem ser incluídos diretamente no corpo de emails ou pushes, a menos que seja estritamente necessário e o canal seja seguro. É preferível linkar para a aplicação (onde o usuário está autenticado) para ver detalhes.
*   **Phishing:** Emails e SMSs de notificação devem ter uma aparência consistente e identificável para evitar que os usuários cliquem em links de phishing. Incluir informações que só o sistema e o usuário saberiam (com moderação).
*   **Privacidade:** Respeitar as preferências do usuário é fundamental. Não enviar notificações que o usuário desabilitou.
*   **Rate Limiting (para o sistema):** O próprio sistema de notificações pode ser um alvo se puder ser usado para spam. Limitar a frequência de certos tipos de notificações (ex: notificações de segurança repetidas).

## 🧑‍💻 13. Contribuição

*   Crie novos templates em `templates/<channel>/<notification_type>.<format>.eex`.
*   Adicione traduções em `templates/i18n/`.
*   Ao definir um novo `notification_type`, configure seus canais padrão e adicione opções nas preferências do usuário.
*   Use `content_data` para passar todas as variáveis necessárias para o template, evitando lógica complexa dentro dos templates.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar um painel para usuários gerenciarem visualmente seus históricos de notificação e preferências de forma mais granular.
*   [ ] Adicionar suporte a notificações Web Push para navegadores desktop/mobile.
*   [ ] Permitir que usuários \"silenciem\" notificações por um período.
*   [ ] Agregação de notificações similares para evitar sobrecarregar o usuário (ex: \"Você tem 3 novas mensagens\" em vez de 3 pushes separados).
*   [ ] Testes A/B para o conteúdo e timing de notificações para otimizar o engajamento.
*   [ ] Integração com um serviço de análise para rastrear taxas de abertura/clique (para email, push).
*   [ ] Canal de Slack ou Discord para notificações para administradores ou equipes internas.

---

*Última atualização: 2025-05-12*

---

O sistema de notificações é um componente complexo e muito importante para a experiência do usuário e para a operação do sistema.

Agora, para onde vamos? Podemos detalhar os submódulos do `DeeperHub.Notifications` como o `TemplateManager` ou o `Scheduler`, ou mudar para outro módulo Core, como `DeeperHub.Core.CircuitBreakerFactory` ou `DeeperHub.Core.EncryptionService`?"""),
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
                types.Part.from_text(text="""Ok! Dado que o `DeeperHub.Core.CircuitBreakerFactory` (ou apenas `CircuitBreaker`) foi mencionado como uma dependência para interações com serviços externos (como GeoIP, SMTP, e potencialmente o próprio `DeeperHub.Notifications` se ele usar provedores externos de push/SMS), vamos detalhá-lo agora. Ele é crucial para a resiliência do sistema.

---

