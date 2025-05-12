# Módulo: `DeeperHub.Support` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Support`

O módulo `DeeperHub.Support` é responsável por gerenciar o **sistema de tickets de suporte** da plataforma DeeperHub. Ele permite que os usuários criem solicitações de suporte (tickets) para relatar problemas, fazer perguntas ou solicitar assistência. A equipe de suporte (ou administradores) pode então visualizar, gerenciar, responder e resolver esses tickets.

Este módulo abrange todo o ciclo de vida de um ticket, desde sua criação até a resolução, incluindo atribuição a agentes, comunicação entre usuário e suporte, e categorização. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Criação de Tickets (`create_ticket/1`):**
    *   Permitir que usuários autenticados (e, opcionalmente, visitantes não autenticados, se configurado) criem novos tickets de suporte.
    *   Capturar informações essenciais: assunto, descrição detalhada do problema/pergunta, categoria do problema, prioridade (definida pelo usuário ou sistema), informações do usuário (se logado).
    *   Permitir o anexo de arquivos (imagens, logs) aos tickets (integrando com um serviço de armazenamento de arquivos).
*   **Gerenciamento de Tickets (para Usuários e Suporte):**
    *   Listar tickets (`list_tickets/1`, `list_user_tickets/2`) com filtros (status, prioridade, categoria, atribuído a) e paginação.
    *   Visualizar detalhes de um ticket específico (`get_ticket/1`), incluindo todo o histórico de mensagens.
    *   Atualizar status de um ticket (ex: Aberto, Em Andamento, Aguardando Resposta do Usuário, Resolvido, Fechado) (`update_ticket_status/2`).
    *   Atribuir tickets a agentes de suporte específicos (se houver um sistema de agentes).
    *   Definir prioridade de tickets.
*   **Comunicação no Ticket:**
    *   Permitir que usuários e agentes de suporte adicionem mensagens/respostas a um ticket existente (`add_message_to_ticket/3` - Nova Sugestão).
    *   Manter um histórico cronológico de todas as comunicações dentro de um ticket.
*   **Categorização e Priorização:**
    *   Permitir a definição de categorias de tickets (ex: Problema Técnico, Dúvida de Cobrança, Sugestão).
    *   Permitir a definição de níveis de prioridade (ex: Baixa, Média, Alta, Urgente).
*   **Notificações (Integração com `DeeperHub.Notifications`):**
    *   Notificar o usuário quando um ticket é criado ou atualizado pela equipe de suporte.
    *   Notificar a equipe de suporte (ou agente atribuído) quando um novo ticket é criado ou um usuário responde a um ticket existente (via `NotificationIntegration`).
*   **Base de Conhecimento (FAQ) (Integração/Opcional):**
    *   Sugerir artigos relevantes da base de conhecimento enquanto o usuário cria um ticket para tentar resolver o problema autonomamente.
    *   Permitir que agentes de suporte criem ou vinculem artigos da base de conhecimento a partir de tickets.
*   **Escalação de Tickets:**
    *   Mecanismo para escalar tickets que não são resolvidos dentro de um SLA (Service Level Agreement) ou que requerem atenção especializada (`check_request_escalation/2` - pode ser parte da lógica de atualização de status).
*   **Relatórios e Estatísticas:**
    *   Fornecer dados sobre o volume de tickets, tempos de resposta, tempos de resolução, satisfação do cliente (se houver pesquisa pós-resolução), etc. (`count_tickets_by_status/0`).
*   **Limitação de Taxa (`RateLimitIntegration`):**
    *   Aplicar rate limiting na criação de tickets e adição de mensagens para prevenir abuso.
*   **Validação e Sanitização de Conteúdo:**
    *   Validar e sanitizar o conteúdo dos tickets e mensagens para prevenir XSS e outros problemas (via `DeeperHub.Services.Shared.ContentValidation`).
*   **Auditoria:**
    *   Registrar todas as ações importantes em um ticket (criação, mudança de status, atribuição, resposta) no `DeeperHub.Audit`.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.Support` (Fachada Pública):**
    *   Ponto de entrada para todas as operações relacionadas a tickets de suporte.
    *   Delega para o `SupportService`.
2.  **`DeeperHub.Support.Services.SupportService` (ou `DefaultSupportService`):**
    *   **Responsabilidade:** Orquestra a lógica de negócio principal para o sistema de suporte.
    *   **Interações:**
        *   `DeeperHub.Core.Repo`: Para CRUD com `SupportTicketSchema` e `TicketMessageSchema`.
        *   `DeeperHub.Accounts`: Para informações do usuário.
        *   `DeeperHub.Auth`/`RBAC`: Para verificar permissões (ex: quem pode ver/responder/gerenciar tickets).
        *   `DeeperHub.Notifications`: Para enviar notificações sobre atualizações de tickets.
        *   `DeeperHub.Services.Shared.ContentValidation`: Para validar e sanitizar descrições e mensagens.
        *   `DeeperHub.Core.EventBus`: Para publicar eventos (ex: `ticket.created`, `ticket.message_added`).
        *   `DeeperHub.Core.ConfigManager`: Para configurações (categorias, prioridades padrão).
        *   `DeeperHub.Support.RateLimitIntegration`.
3.  **Schemas Ecto:**
    *   **`DeeperHub.Support.Schemas.SupportTicketSchema` (ex-`SupportTicket`):** Entidade principal do ticket (id, user_id, subject, description, status, priority, category, assigned_agent_id, created_at, updated_at, resolved_at, closed_at).
    *   **`DeeperHub.Support.Schemas.TicketMessageSchema` (Nova Sugestão):** Para armazenar as mensagens trocadas dentro de um ticket (ticket_id, user_id/agent_id, content, created_at, attachments).
    *   **`DeeperHub.Support.Schemas.TicketCategorySchema` (Nova Sugestão):** Definições de categorias de tickets.
    *   **`DeeperHub.Support.Schemas.TicketPrioritySchema` (Nova Sugestão):** Definições de prioridades.
4.  **`DeeperHub.Support.Storage` (ou lógica dentro do `SupportService`):**
    *   Encapsula as queries Ecto.
5.  **`DeeperHub.Support.NotificationIntegration`:**
    *   Lida especificamente com a lógica de quando e como enviar notificações relacionadas a tickets.
6.  **`DeeperHub.Support.RateLimitIntegration`:**
    *   Aplica políticas de rate limiting.
7.  **Workers (Opcional):**
    *   `TicketEscalationWorker`: Para verificar SLAs e escalar tickets.
    *   `TicketReminderWorker`: Para enviar lembretes sobre tickets aguardando resposta.
    *   `TicketAutoCloseWorker`: Para fechar automaticamente tickets resolvidos após um período de inatividade.

### 3.2. Estrutura de Diretórios (Proposta)

```
lib/deeper_hub/support/
├── support.ex                        # Fachada Pública
│
├── services/
│   └── support_service.ex            # Serviço principal
│
├── schemas/                          # (Ou schema/)
│   ├── support_ticket_schema.ex
│   ├── ticket_message_schema.ex
│   ├── ticket_category_schema.ex
│   └── ticket_priority_schema.ex
│
├── storage.ex                        # (Opcional) Módulo de queries Ecto
│
├── integrations/                     # Renomeado de NotificationIntegration para ser mais genérico
│   ├── notification_integration.ex
│   ├── audit_integration.ex          # Para logar no DeeperHub.Audit
│   └── event_integration.ex          # Para publicar no Core.EventBus
│
├── rate_limit_integration.ex
│
├── workers/                          # Opcional
│   ├── ticket_escalation_worker.ex
│   ├── ticket_reminder_worker.ex
│   └── ticket_auto_close_worker.ex
│
├── supervisor.ex
└── telemetry.ex
```
*(O `DefaultSupportService` e `SupportAdapter` da documentação original são consolidados no `SupportService` e na fachada `Support`)*

### 3.3. Decisões de Design Importantes

*   **Ciclo de Vida do Ticket:** Definir claramente os diferentes status de um ticket e as transições permitidas entre eles.
*   **Comunicação Clara:** Manter um histórico claro de todas as mensagens trocadas entre o usuário e a equipe de suporte dentro do ticket.
*   **Notificações Eficazes:** Notificar as partes corretas no momento certo sobre atualizações nos tickets.
*   **Métricas de Suporte:** Rastrear métricas chave (tempo de primeira resposta, tempo de resolução) é vital para a qualidade do serviço.

## 🛠️ 4. Casos de Uso Principais

*   **Usuário Cria um Novo Ticket de Suporte:**
    *   Usuário preenche formulário na seção de ajuda.
    *   API chama `DeeperHub.Support.create_ticket(user_id, ticket_attrs)`.
    *   Serviço valida dados, sanitiza, persiste. Notifica o usuário da criação e a equipe de suporte sobre o novo ticket.
*   **Agente de Suporte Responde a um Ticket:**
    *   Agente visualiza o ticket em seu painel.
    *   Escreve uma resposta e atualiza o status (ex: para \"Aguardando Resposta do Usuário\").
    *   API chama `DeeperHub.Support.add_message_to_ticket(agent_id, ticket_id, message_content)` e `DeeperHub.Support.update_ticket_status(ticket_id, new_status, agent_id)`.
    *   Notifica o usuário sobre a nova resposta.
*   **Ticket é Resolvido:**
    *   Após a solução do problema, o agente ou o usuário marca o ticket como resolvido.
    *   API chama `DeeperHub.Support.update_ticket_status(ticket_id, :resolved, agent_or_user_id)`.
    *   (Opcional) Envia uma pesquisa de satisfação.

## 🌊 5. Fluxos Importantes

### Fluxo de Criação e Primeira Resposta de um Ticket

1.  **Usuário (UI):** Submete o formulário de novo ticket.
2.  **Controller API:** Chama `DeeperHub.Support.create_ticket(current_user.id, params[\"ticket\"])`.
3.  **`SupportService.create_ticket/2`:**
    *   Verifica rate limit (via `RateLimitIntegration`).
    *   Valida e sanitiza `params[\"ticket\"]` (via `Shared.ContentValidation`).
    *   Cria um `SupportTicketSchema` changeset.
    *   Se válido, `Core.Repo.insert(changeset)`.
    *   Se sucesso:
        *   Chama `NotificationIntegration.notify_ticket_created(ticket, user_id)` -> que usa `DeeperHub.Notifications`.
        *   Publica evento `support.ticket.created` via `Core.EventBus`.
        *   Audita.
        *   Retorna `{:ok, ticket_struct}`.
4.  **Equipe de Suporte (UI Painel):** Vê o novo ticket.
5.  **Agente de Suporte:** Abre o ticket, escreve uma resposta.
6.  **Controller API (Painel Admin):** Chama `DeeperHub.Support.add_message_to_ticket(current_agent.id, ticket_id, message_params)` e depois `DeeperHub.Support.update_ticket_status(ticket_id, :in_progress, current_agent.id)`.
7.  **`SupportService`:**
    *   Valida e sanitiza a mensagem.
    *   Cria um `TicketMessageSchema` associado ao ticket.
    *   Atualiza o status do `SupportTicketSchema`.
    *   Chama `NotificationIntegration.notify_ticket_replied(ticket, new_message_data)` para notificar o usuário.
    *   Publica eventos e audita.

## 📡 6. API (Funções Públicas da Fachada `DeeperHub.Support`)

### 6.1. `DeeperHub.Support.create_ticket(user_id :: String.t() | nil, attrs :: map()) :: {:ok, SupportTicket.t()} | {:error, Ecto.Changeset.t() | term()}`

*   **Descrição:** Cria um novo ticket de suporte. `user_id` pode ser `nil` se tickets anônimos forem permitidos.
*   **`attrs`:** `%{subject: String.t(), description: String.t(), category_id: String.t() | nil, priority_id: String.t() | nil, attachments: list(map()) | nil}`.

### 6.2. `DeeperHub.Support.get_ticket(ticket_id :: String.t(), opts :: keyword()) :: {:ok, SupportTicketView.t() | nil}`

*   **Descrição:** Obtém os detalhes de um ticket, incluindo suas mensagens.
*   **`SupportTicketView.t()`:** Struct do ticket com `messages` pré-carregadas e informações de usuário/agente.
*   **`opts`:** `:requesting_user_id` (para verificar permissão de visualização).

### 6.3. `DeeperHub.Support.list_tickets(filters :: map(), opts :: keyword()) :: {:ok, list(SupportTicketListItem.t()), Pagination.t()}` (Admin/Suporte)

*   **Descrição:** Lista tickets para a equipe de suporte.
*   **`filters`:** `:status`, `:priority_id`, `:category_id`, `:assigned_agent_id`, `:user_email_contains`.
*   **`SupportTicketListItem.t()`:** Uma visão resumida do ticket.

### 6.4. `DeeperHub.Support.list_user_tickets(user_id :: String.t(), filters :: map(), opts :: keyword()) :: {:ok, list(SupportTicketListItem.t()), Pagination.t()}`

*   **Descrição:** Lista os tickets de um usuário específico.
*   **`filters`:** `:status`.

### 6.5. `DeeperHub.Support.add_message_to_ticket(actor_id :: String.t(), ticket_id :: String.t(), message_attrs :: map()) :: {:ok, TicketMessage.t()} | {:error, Ecto.Changeset.t() | :unauthorized | :ticket_closed}`

*   **Descrição:** Adiciona uma nova mensagem a um ticket existente.
*   **`actor_id`:** ID do usuário ou agente de suporte que está adicionando a mensagem.
*   **`message_attrs`:** `%{content: String.t(), attachments: list(map()) | nil, is_internal_note: boolean() | false}`.

### 6.6. `DeeperHub.Support.update_ticket_status(ticket_id :: String.t(), new_status :: atom(), actor_id :: String.t(), opts :: keyword()) :: {:ok, SupportTicket.t()} | {:error, :invalid_transition | term()}`

*   **Descrição:** Atualiza o status de um ticket.
*   **`new_status`:** Ex: `:open`, `:in_progress`, `:awaiting_user`, `:resolved`, `:closed`.
*   **`opts`:** `:resolution_notes` (String.t) se o status for `:resolved`.

### 6.7. `DeeperHub.Support.assign_ticket(ticket_id :: String.t(), agent_id :: String.t(), assigning_admin_id :: String.t()) :: {:ok, SupportTicket.t()} | {:error, term()}` (Nova Sugestão)

*   **Descrição:** Atribui um ticket a um agente de suporte.

### 6.8. `DeeperHub.Support.get_ticket_categories() :: {:ok, list(TicketCategory.t())}` (Nova Sugestão)
### 6.9. `DeeperHub.Support.get_ticket_priorities() :: {:ok, list(TicketPriority.t())}` (Nova Sugestão)

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager`:

*   **`[:support, :enabled]`** (Boolean): Habilita/desabilita o sistema de suporte.
*   **`[:support, :allow_anonymous_tickets]`** (Boolean): Permite que visitantes não logados criem tickets. (Padrão: `false`)
*   **`[:support, :default_priority_id]`** (String): ID da prioridade padrão para novos tickets.
*   **`[:support, :default_category_id]`** (String): ID da categoria padrão.
*   **`[:support, :max_description_length]`** (Integer): Comprimento máximo da descrição do ticket.
*   **`[:support, :max_attachments_per_ticket]`** (Integer).
*   **`[:support, :max_attachment_size_mb]`** (Integer).
*   **`[:support, :auto_close_resolved_tickets_after_days]`** (Integer | nil): Dias para fechar automaticamente tickets resolvidos sem resposta do usuário.
*   **`[:support, :sla, :first_response_hours, <priority_id>]`** (Integer): SLA de primeira resposta por prioridade.
*   **`[:support, :sla, :resolution_hours, <priority_id>]`** (Integer): SLA de resolução por prioridade.
*   **`[:support, :notification, :notify_user_on_creation]`** (Boolean).
*   **`[:support, :notification, :notify_agent_on_assignment]`** (Boolean).
*   **`[:support, :notification, :notify_user_on_reply]`** (Boolean).
*   **`[:support, :notification, :support_team_email_group]`** (String): Email do grupo de suporte para notificações de novos tickets.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.*`: Todos os módulos Core.
*   `DeeperHub.Accounts`: Para `user_id` e informações do usuário.
*   `DeeperHub.Auth`/`RBAC`: Para permissões de agentes e admins.
*   `DeeperHub.Notifications`: Para todas as notificações de ticket.
*   `DeeperHub.Services.Shared.ContentValidation`: Para validar e sanitizar conteúdo.
*   `DeeperHub.Support.RateLimitIntegration`.
*   Um serviço de Armazenamento de Arquivos (se houver anexos).
*   `DeeperHub.Audit`.

### 8.2. Bibliotecas Externas

*   `Ecto`.

## 🤝 9. Como Usar / Integração

*   **Interface do Usuário (Seção de Ajuda/Suporte):**
    *   Formulário para `create_ticket`.
    *   Listagem para `list_user_tickets`.
    *   Visualização e adição de mensagens para `get_ticket` e `add_message_to_ticket`.
*   **Painel de Administração/Suporte:**
    *   Dashboard com `list_tickets` e filtros avançados.
    *   Funcionalidades para atribuir, atualizar status, responder e escalar tickets.
*   **Alertas do Sistema:** Outros módulos podem, em caso de erro persistente ou problema complexo, programaticamente criar um ticket de suporte em nome do usuário ou para a equipe interna.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar o ciclo de vida completo de um ticket (criação, respostas, mudança de status, resolução, fechamento).
*   Testar a lógica de permissão (usuário só pode ver seus tickets, agente pode ver tickets atribuídos, etc.).
*   Testar a validação e sanitização de conteúdo.
*   Testar o envio de notificações em cada etapa.
*   Testar a funcionalidade de anexos.
*   Testar os workers (escalação, auto-fechamento).
*   Localização: `test/deeper_hub/support/`.

### 10.2. Métricas

*   `deeper_hub.support.tickets.created.count` (tags: `category_id`, `priority_id`, `channel` (`web`, `api`, `email`))
*   `deeper_hub.support.tickets.resolved.count` (tags: `category_id`)
*   `deeper_hub.support.tickets.closed.count`
*   `deeper_hub.support.tickets.status_changed.count` (tags: `from_status`, `to_status`)
*   `deeper_hub.support.tickets.messages_added.count` (tags: `actor_type` (`user`, `agent`))
*   `deeper_hub.support.tickets.avg_first_response_time_minutes.gauge` (Gauge, tags: `priority_id`)
*   `deeper_hub.support.tickets.avg_resolution_time_hours.gauge` (Gauge, tags: `priority_id`)
*   `deeper_hub.support.tickets.open_tickets.gauge` (Gauge, tags: `priority_id`, `category_id`)

### 10.3. Logs

*   **Nível INFO:** Ticket criado, status alterado, mensagem adicionada.
*   **Nível WARNING:** SLA de primeira resposta ou resolução próximo de estourar. Tentativa de ação não permitida (ex: usuário tentando fechar ticket de outro).
*   **Nível ERROR:** Falha ao criar ticket, falha ao enviar notificação de ticket.

### 10.4. Telemetria

*   `[:deeper_hub, :support, :ticket, :created | :updated | :status_changed | :message_added]`
    *   Metadados: `%{ticket_id: id, user_id: id, agent_id: id, changes: map}`
*   `[:deeper_hub, :support, :sla, :breached]`
    *   Metadados: `%{ticket_id: id, sla_type: :first_response | :resolution, priority: prio}`

## ❌ 11. Tratamento de Erros

*   Falhas de validação ao criar/atualizar retornam `{:error, changeset}`.
*   Operações não autorizadas retornam `{:error, :unauthorized}`.
*   Tentativas de operar em tickets não existentes retornam `{:error, :not_found}`.
*   Falhas no envio de notificações são logadas, mas não devem impedir a operação principal no ticket.

## 🛡️ 12. Considerações de Segurança

*   **Sanitização de Conteúdo:** Todas as descrições e mensagens devem ser sanitizadas para prevenir XSS.
*   **Proteção de Anexos:** Anexos devem ser escaneados por vírus e ter seu tipo de conteúdo validado. O acesso a anexos deve ser controlado.
*   **Privacidade dos Dados do Ticket:** Apenas o autor do ticket, agentes atribuídos e administradores com permissão devem poder visualizar o conteúdo completo de um ticket.
*   **Não Incluir Dados Sensíveis Desnecessários:** Instruir usuários a não incluir senhas ou outros dados altamente sensíveis nos tickets. Se necessário, fornecer um canal seguro separado.

## 🧑‍💻 13. Contribuição

*   Mantenha a lógica de transição de status clara e bem definida.
*   Garanta que as notificações sejam relevantes e enviadas para as partes corretas.
*   Adicione testes para todos os novos fluxos e validações.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar uma Base de Conhecimento (FAQ) integrada e sugestão de artigos durante a criação do ticket.
*   [ ] Permitir que usuários avaliem a qualidade do suporte recebido após a resolução do ticket.
*   [ ] Funcionalidade de \"campos customizados\" para tickets, permitindo que administradores adicionem campos específicos para diferentes categorias de problemas.
*   [ ] Integração com email para que usuários possam responder a notificações de ticket por email e suas respostas sejam adicionadas ao ticket.
*   [ ] Atribuição automática de tickets a agentes com base em carga de trabalho, especialidade ou round-robin.
*   [ ] Relatórios mais detalhados para a equipe de suporte (desempenho de agentes, gargalos, etc.).
*   [ ] Suporte a \"tickets internos\" para comunicação entre equipes.

---

*Última atualização: 2025-05-12*

---

O sistema de suporte é outra peça importante para a satisfação do usuário.

Agora, o que acha de explorarmos `DeeperHub.UserInteractions` para ver como os usuários interagem socialmente na plataforma, ou talvez o `DeeperHub.OAuth` para detalhar a autenticação com provedores externos?"""),
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
                types.Part.from_text(text="""Excelente! Vamos continuar com o `DeeperHub.UserInteractions`. Este módulo é focado nas funcionalidades sociais e de interação entre os usuários da plataforma DeeperHub.

---

