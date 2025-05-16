# Módulo: `Deeper_Hub.Support` 🎫

## 📜 1. Visão Geral do Módulo `Deeper_Hub.Support`

O módulo `Deeper_Hub.Support` é responsável por gerenciar o sistema de suporte ao cliente/usuário dentro da plataforma Deeper_Hub. Ele permite que usuários criem tickets de suporte para relatar problemas, fazerencia o ciclo de vida desses tickets, desde a criação até a resolução, facilitando a comunicação entre os usuários e a equipe de suporte. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Criação de Tickets de Suporte:**
    *   Permitir que usuários criem novos tickets com assunto, descrição detalhada, categoria, prioridade e anexos (opcional).
*   **Gerenciamento do Ciclo de Vida do Ticket:**
    *   Atribuição de tickets a agentes de suporte (manual ou automática).
    *   Acompanhamento do status do ticket (ex: Aberto, Em Andamento, Aguardando Resposta do Usuário, Aguardando Resposta da Equipe, Resolvido, Fechado).
    *   Registro de todas as interações e mensagens trocadas dentro de um ticket.
*   **Comunicação:**
    *   Permitir que usuários e agentes de suporte adicionem mensagens e respostas aos tickets.
    *   Suporte para formatação de texto e anexos nas mensagens.
*   **Listagem e Busca de Tickets:**
    *   Permitir que usuários visualizem seus tickets abertos e históricos.
    *   Fornecer uma interface para agentes de suporte visual perguntas ou solicitar assistência, e que a equipe de suporte gerencie, responda e resolva esses tickets. O objetivo é fornecer um canal de comunicação eficiente para resolução de questões e melhoria da experiência do usuário. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Criação de Tickets de Suporte:**
    *   Permitir que usuários criem novos tickets com assunto, descrição detalhada, categoria, prioridade e anexos (opcional).
*   **Gerenciamento de Tickets:**
    *   CRUD para Tickets (`SupportTicket`): visualizar, atualizar status (aberto, em andamento, pendente de resposta do usuário, resolvido, fechado), atribuir a agentes de suporte.
    *   Adicionar comentários/respostas internas e para o usuário em um ticket.
    *   Visualizar o histórico de um ticket.
*   **Listagem e Filtragem de Tickets:**
    *   Permitir que usuários vejam seus próprios tickets.
    *   Permitir que a equipe de suporte veja todos os tickets ou filtre por status, prioridade, atribuição, categoria, etc.
    *   Paginação e ordenação de listas de tickets.
*   **Notificações:**
    *   Notificar usuários sobre atualizações em seus tickets (nova resposta, mudança de status) via `Deeper_Hub.Notifications`.
    *   Notificar a equipe de suporte sobre novos tickets ou atualizações em tickets atribuídos.
*   **Categorização e Priorização:**
    *   Permitir a categorização de tickets (ex: \"Problema Técnico\", \"Dúvida de Faturamento\", \"Sugestão\").
    *   Definir níveis de prioridade para tickets (ex: Baixa, Média, Alta, Urgente).
izarem e gerenciarem a fila de tickets (com filtros por status, prioridade, agente, etc.).
    *   Busca de tickets por palavras-chave, ID, usuário, etc.
*   **Notificações:**
    *   Notificar usuários sobre atualizações em seus tickets (nova resposta, mudança de status) via `Deeper_Hub.Notifications`.
    *   Notificar agentes de suporte sobre novos tickets ou tickets atribuídos a eles.
*   **Priorização e SLA (Service Level Agreement):**
    *   Definir prioridades para tickets.
    *   (Opcional) Rastrear o tempo de resposta e resolução para garantir o cumprimento de SLAs.
*   **Categorização de Tickets:**
    *   Permitir a categorização de tickets para melhor organização e encaminhamento (ex: Técnico, Cobrança, Dúvida Geral).
*   **Base de Conhecimento/FAQ (Integração Opcional):**
    *   Sugerir artigos da base de conhecimento relevantes enquanto o usuário cria um ticket.
    *   Permitir que agentes transformem respostas de tickets em artigos da base de conhecimento.
*   **Administração e Relatórios:**
    *   Interface para administradores configurarem o sistema de suporte (categorias, prioridades, regras de atribuição).
    *   Geração de relatórios sobre o desempenho do suporte (tempo médio de resposta, volume de tickets, satisfação do cliente).

## 🏗️ 3. Arquitetura e Design

`Deeper_Hub.Support` será uma fachada que interage com serviços de lógica de negócio e componentes de persistência.

*   **Interface Pública (`Deeper_Hub.Support.SupportFacade` ou `Deeper_Hub.Support`):** Funções como `create_ticket/1`, `get_ticket/1`, `add_message_to_ticket/3`, `list_user_tickets/2`.
*   **Serviço de Tickets (`Deeper_Hub.Support.Services.TicketService`):**
    *   Contém a lógica de negócio principal para criar, atualizar, e gerenciar o estado dos tickets e mensagens.
*   **Schemas Ecto:**
    *   `Deeper_Hub.Support.Schema.SupportTicket`: Define um ticket de suporte.
    *   `Deeper_Hub.Support.Schema.TicketMessage` (Novo Sugerido): Define uma mensagem individual dentro de um ticket.
    *   `Deeper_Hub.Support.Schema.TicketCategory` (Opcional): Para categorias de tickets.
    *   `Deeper*   **Anexos:**
    *   Permitir que usuários e equipe de suporte anexem arquivos (logs, screenshots) aos tickets.
*   **Métricas e Relatórios de Suporte:**
    *   Coletar métricas como tempo de primeira resposta, tempo de resolução, número de tickets por categoria/status.
    *   Gerar relatórios sobre o desempenho do suporte.
*   **Base de Conhecimento/FAQ (Integração Potencial):**
    *   Sugerir artigos da base de conhecimento relevantes ao usuário durante a criação do ticket.
    *   Permitir que agentes de suporte facilmente referenciem ou criem artigos da base de conhecimento a partir de tickets.
*   **Rate Limiting:**
    *   Aplicar limites na criação de tickets ou adição de mensagens para prevenir abuso (via `Deeper_Hub.Services.Support.RateLimitIntegration`).
*   **Validação e Sanitização de Conteúdo:**
    *   Validar e sanitizar o conteúdo dos tickets e mensagens para prevenir XSS e outros problemas (via `Deeper_Hub.Services.Shared.ContentValidation`).

## 🏗️ 3. Arquitetura e Design

`Deeper_Hub.Support` atuará como uma fachada para um serviço de lógica de negócio e componentes de persistência.

*   **Interface Pública (`Deeper_Hub.Support.SupportFacade` ou `Deeper_Hub.Support`):** Funções como `create_ticket/1`, `get_ticket/1`, `list_user_tickets/2`, `add_reply_to_ticket/3`.
*   **Serviço de Suporte (`Deeper_Hub.Support.Services.SupportService` ou `DefaultSupportService`):**
    *   Contém a lógica de negócio principal para gerenciar tickets.
*   **Schemas Ecto:**
    *   `Deeper_Hub.Support.Schema.SupportTicket`: Define um ticket de suporte.
    *   `Deeper_Hub.Support.Schema.TicketMessage` (Novo Sugerido): Define uma mensagem/resposta dentro de um ticket.
    *   `Deeper_Hub.Support.Schema.TicketAttachment` (Novo Sugerido): Define um anexo de ticket.
*   **Integrações:**
    *   `Deeper_Hub.Core.Repo`: Para persistência.
    *   `Deeper_Hub.Core.EventBus`: Para publicar eventos (ex: `TicketCreatedEvent`, `TicketUpdatedEvent`).
    *   `Deeper_Hub.Notifications`: Para enviar notificações a usuários e equipe de suporte.
    *   `Deeper_Hub.Services.Shared.ContentValidation`: Para validar o conteúdo dos tickets.
    *   `Deeper_Hub.Services.Support.RateLimitIntegration`: Para controle de taxa.
    *   `Deeper_Hub.Core.BackgroundTaskManager`: Para tarefas como envio de lembretes ou escalonamento automático.

**Padrões de Design:**

*   **Fachada (Facade).**
*   **Serviço de Domínio.**

### 3.1. Componentes Principais

*   **`Deeper_Hub.Support.SupportFacade`:** Ponto de entrada.
*   **`Deeper_Hub.Support.Services.DefaultSupportService`:** Lógica de negócio.
*   **`Deeper_Hub.Support.Schema.SupportTicket`:** Schema principal.
*   **`Deeper_Hub.Support.Schema.TicketMessage`:** Schema para mensagens/respostas.
*   **`Deeper_Hub.Support.NotificationIntegration`:** Lida com o envio de notificações específicas de suporte.
*   **`Deeper_Hub.Support.RateLimitIntegration`:** Gerencia a limitação de taxa para operações de suporte.
*   **`Deeper_Hub.Support.Supervisor`:** Supervisiona processos.

### 3.3. Decisões de Design Importantes

*   **Fluxo de Status do Ticket:** Definir claramente os possíveis status de um ticket e as transições permitidas entre eles.
*   **Hub.Support.Schema.TicketPriority` (Opcional): Para prioridades de tickets.
*   **Serviço de Notificações (via `Deeper_Hub.Support.NotificationIntegration`):**
    *   Lida com o envio de notificações para usuários e agentes.
*   **Rate Limiting (via `Deeper_Hub.Support.RateLimitIntegration`):**
    *   Protege contra abuso na criação de tickets ou mensagens.
*   **Integrações:**
    *   `Deeper_Hub.Core.Repo`: Para persistência.
    *   `Deeper_Hub.Core.EventBus`: Para publicar eventos (ex: `TicketCreatedEvent`, `TicketUpdatedEvent`).
    *   `Deeper_Hub.Notifications`: Para enviar emails/alertas sobre tickets.
    *   `Deeper_Hub.Accounts`: Para associar tickets a usuários.
    *   `Deeper_Hub.Core.InputValidator` e `Deeper_Hub.Services.Shared.ContentValidation`: Para validar e sanitizar o conteúdo dos tickets.

**Padrões de Design:**

*   **Fachada (Facade).**
*   **Serviço de Domínio.**
*   **State Machine:** Para gerenciar os diferentes status de um ticket e as transições permitidas.

### 3.1. Componentes Principais

*   **`Deeper_Hub.Support.SupportFacade`:** Ponto de entrada.
*   **`Deeper_Hub.Support.Services.TicketService`:** Lógica de negócio principal.
*   **`Deeper_Hub.Support.Schema.SupportTicket`:** Schema do ticket.
*   **`Deeper_Hub.Support.Schema.TicketMessage`:** Schema das mensagens do ticket.
*   **`Deeper_Hub.Support.NotificationIntegration`:** Envia notificações.
*   **`Deeper_Hub.Support.RateLimitIntegration`:** Controla limites de taxa.
*   **`Deeper_Hub.Support.Supervisor`:** Supervisiona processos.
*   **Workers (ex: `TicketReminderWorker`, `AutoCloseWorker`):** Para tarefas periódicas como enviar lembretes ou fechar tickets inativos.

### 3.3. Decisões de Design Importantes

*   **Modelo de Dados:** Definir claramente a relação entre Tickets, Mensagens, Usuários e Agentes.
*   **Fluxo de Status do Ticket:** Mapear todos os possíveis status de um ticket e as transições válidas entre eles.
*   **Atribuição de Tickets:** Decidir sobre a estratégia de atribuição (manual, round-robin, baseada em categoria/habilidade).

## 🛠️ 4. Casos de Uso Principais

*   **Usuário Cria um Novo Ticket:** Um usuário preenche um formulário no site/app para relatar um problema.
*   **Agente de Suporte Responde a um Ticket:** Um agente visualiza o ticket, escreve uma resposta e atualiza o status.
*   **Usuário Adiciona Informações a um Ticket Existente:** O usuário responde a uma solicitação de mais informações da equipe de suporte.
*   **Ticket é Resolvido e Fechado:** Após a solução do problema, o ticket é marcado como resolvido e, eventualmente, fechado.
*   **Administrador Visualiza Relatórios de Suporte:** Um gerente de suporte analisa métricas como volume de tickets por categoria e tempo médio de resolução.

## 🌊 5. Fluxos Importantes (Opcional)

**Fluxo de Criação de um Novo Ticket:**

1.  Usuário submete dados do novo ticket via API/UI.
2.  `Deeper_Hub.API` (Controller) chama `Deeper_Hub.Support.SupportFacade.create_ticket(params)`.
3.  `SupportFacade` delega para `Deeper_Hub.Support.Services.TicketService.create_ticket(params)`.
4.  `TicketService` valida os `params` usando `Core.InputValidator` e `ContentValidation`.
5.  Se válido, um novo registro `SupportTicket` é criado e persistido via `Core.Repo`.
6.  Uma primeira `TicketMessage` (com a descrição inicial) pode ser criada e associada ao ticket.
7.  Um evento `TicketCreatedEvent` é publicado no `Core.EventBus`.
8.  O `Support.NotificationIntegration` (ou um listener do evento) envia uma notificação de confirmação para o usuário e, possivelmente, para a equipe de suporte.
9.  Retorna `{:ok, ticket_criado}`.

## 📡 6. API (Se Aplicável)

### 6.1. `Deeper_Hub.Support.create_ticket/1`

*   **Descrição:** Cria um novo ticket de suporte.
*   **`@spec`:** `create_ticket(attrs :: map()) :: {:ok, SupportTicket.t()} | {:error, Ecto.Changeset.t() | reason}`
*   **Parâmetros:**
    *   `attrs` (map): Atributos do ticket.
        *   `:user_id` (String, obrigatório): ID do usuário queAtribuição de Tickets:** Como os tickets são atribuídos à equipe de suporte (manual, round-robin, baseado em categoria/habilidade).
*   **SLA (Service Level Agreements):** Se o sistema precisa rastrear e alertar sobre SLAs (ex: tempo de primeira resposta, tempo de resolução).

## 🛠️ 4. Casos de Uso Principais

*   **Usuário Cria um Novo Ticket:** Um usuário com um problema preenche um formulário e submete um novo ticket de suporte.
*   **Agente de Suporte Responde a um Ticket:** Um agente da equipe de suporte visualiza um ticket atribuído a ele e adiciona uma resposta para o usuário.
*   **Usuário Verifica o Status do seu Ticket:** O usuário acessa a seção de suporte para ver o status atual de seus tickets abertos.
*   **Sistema Envia Lembrete:** Para um ticket que está aguardando resposta do usuário por X dias, o sistema envia um lembrete.
*   **Administrador Gera Relatório de Suporte:** Um administrador gera um relatório sobre o número de tickets resolvidos no último mês, categorizados por tipo.

## 🌊 5. Fluxos Importantes (Opcional)

**Fluxo de Criação e Primeira Resposta de um Ticket:**

1.  Usuário submete um formulário de criação de ticket via API/UI.
2.  `Deeper_Hub.API` (Controller) chama `Deeper_Hub.Support.SupportFacade.create_ticket(params)`.
3.  `SupportFacade` delega para `DefaultSupportService.create_ticket(params)`.
4.  `DefaultSupportService`:
    *   Valida os `params` usando `SupportTicket.changeset/2` e `Shared.ContentValidation`.
    *   Se válido, cria o registro `SupportTicket` no banco de dados via `Core.Repo`.
    *   Publica um evento `TicketCreatedEvent` no `Core.EventBus`.
    *   Envia uma notificação para o usuário confirmando a criação do ticket (via `NotificationIntegration`).
    *   Envia uma notificação para a equipe de suporte sobre o novo ticket.
5.  O ticket aparece na fila da equipe de suporte.
6.  Um agente de suporte seleciona o ticket e adiciona uma resposta via API/UI.
7.  `Deeper_Hub.API` chama `Deeper_Hub.Support.SupportFacade.add_reply_to_ticket(ticket_id, agent_id, reply_params)`.
8.  `DefaultSupportService`:
    *   Valida a resposta.
    *   Cria um registro `TicketMessage`.
    *   Atualiza o status do `SupportTicket` (ex: para \"Aguardando Resposta do Usuário\").
    *   Publica um evento `TicketRepliedEvent`.
    *   Envia uma notificação para o usuário sobre a nova resposta.

## 📡 6. API (Se Aplicável)

### 6.1. `Deeper_Hub.Support.create_ticket/1`

*   **Descrição:** Cria um novo ticket de suporte.
*   **`@spec`:** `create_ticket(attrs :: map()) :: {:ok, SupportTicket.t()} | {:error, Ecto.Changeset.t() | reason}`
*   **Parâmetros:**
    *   `attrs` (map): Atributos do ticket.
        *   `user_id` (String): ID do usuário que está criando o ticket.
        *   `subject` (String): Assunto do ticket.
        *   `description` (String): Descrição detalhada do problema/pergunta.
        *   `category` (String, opcional): Categoria do ticket.
        *   `priority` (atom, opcional): Prioridade (ex: `:low`, `:medium`, `:high`). (Padrão: `:medium`)
*   **Retorno:** O ticket criado ou um changeset/razão de erro.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    ticket_attrs = %{
      user_id: current_user.id,
      subject: \"Não consigo fazer login\",
      description: \"Ao tentar logar, recebo a mensagem 'Usuário não encontrado', mas tenho certeza que meu email está correto.\",
      category: \"Problema Técnico\"
    }
    case Deeper_Hub.Support.create_ticket(ticket_attrs) do
      {:ok, ticket} -> Logger.info(\"Ticket #{ticket.id} criado.\")
      {:error, reason} -> Logger.error(\"Falha ao criar ticket: #{inspect(reason)}\")
    end
    ```

### 6.2. `Deeper_Hub.Support.get_ticket/1`

*   **Descrição:** Obtém os detalhes de um ticket de suporte específico.
*   **`@spec`:** `get_ticket(ticket_id :: String.t()) :: {:ok, SupportTicket.t()} | {:error, :not_found | reason}`
*   **Parâmetros:**
    *   `ticket_id` (String): O ID do ticket.
*   **Retorno:** O ticket encontrado ou um erro.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    {:ok, ticket_details} = Deeper_Hub.Support.get_ticket(\"ticket_xyz\")
    ```

### 6.3. `Deeper está criando o ticket.
        *   `:subject` (String, obrigatório): Assunto do ticket.
        *   `:description` (String, obrigatório): Descrição detalhada do problema/pergunta.
        *   `:category_id` (String, opcional): ID da categoria do ticket.
        *   `:priority` (atom, opcional): Prioridade (ex: `:low`, `:normal`, `:high`, `:urgent`). (Padrão: `:normal`)
        *   `:attachments` (list, opcional): Lista de informações de anexos.
*   **Retorno:** O ticket criado ou um changeset com erros.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    ticket_data = %{
      user_id: current_user.id,
      subject: \"Problema com login\",
      description: \"Não consigo acessar minha conta, aparece erro X.\",
      priority: :high
    }
    case Deeper_Hub.Support.create_ticket(ticket_data) do
      {:ok, ticket} -> Logger.info(\"Ticket #{ticket.id} criado.\")
      {:error, changeset} -> Logger.error(\"Erro ao criar ticket: #{inspect(changeset.errors)}\")
    end
    ```

### 6.2. `Deeper_Hub.Support.add_message_to_ticket/3`

*   **Descrição:** Adiciona uma nova mensagem (resposta) a um ticket existente.
*   **`@spec`:** `add_message_to_ticket(ticket_id :: String.t(), author_id :: String.t(), message_attrs :: map()) :: {:ok, TicketMessage.t()} | {:error, reason}`
*   **Parâmetros:**
    *   `ticket_id` (String): O ID do ticket.
    *   `author_id` (String): O ID do autor da mensagem (usuário ou agente).
    *   `message_attrs` (map): Atributos da mensagem.
        *   `:content` (String, obrigatório): Conteúdo da mensagem.
        *   `:is_internal_note` (boolean, opcional): Se a mensagem é uma nota interna para a equipe. (Padrão: `false`)
        *   `:attachments` (list, opcional).
*   **Retorno:** A mensagem criada ou um erro.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    message_data = %{content: \"Por favor, poderia me fornecer mais detalhes sobre o erro?\"}
    case Deeper_Hub.Support.add_message_to_ticket(\"ticket_abc\", agent_user.id, message_data) do
      {:ok, msg} -> Logger.info(\"Mensagem adicionada ao ticket #{msg.ticket_id}\")
      {:error, reason} -> Logger.error(\"Erro ao adicionar mensagem: #{reason}\")
    end
    ```

*(Outras funções como `get_ticket/1`, `list_user_tickets/2`, `update_ticket_status/2` seriam documentadas aqui).*

## ⚙️ 7. Configuração

*   **ConfigManager (`Deeper_Hub.Core.ConfigManager`):**
    *   `[:support, :default_priority]`: Prioridade padrão para novos tickets. (Padrão: `:normal`)
    *   `[:support, :categories]`: Lista de categorias de tickets disponíveis (ex: `[\"technical\", \"billing\", \"general\"]`).
    *   `[:support, :sla, :response_time_hours, :high_priority]`: SLA de tempo de resposta para tickets de alta prioridade.
    *   `[:support, :auto_close_inactive_days]`: Número de dias de inatividade para fechar automaticamente um ticket resolvido. (Padrão: `7`)
    *   `[:support, :attachments, :max_size_mb]`: Tamanho máximo para anexos.
    *   `[:support, :attachments, :allowed_types]`: Tipos de arquivos permitidos para anexos.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `Deeper_Hub.Core.Repo`
*   `Deeper_Hub.Core.ConfigManager`
*   `Deeper_Hub.Core.EventBus`
*   `Deeper_Hub.Core.BackgroundTaskManager`
*   `Deeper_Hub.Notifications`
*   `Deeper_Hub.Accounts`
*   `Deeper_Hub.Core.InputValidator`, `Deeper_Hub.Services.Shared.ContentValidation`
*   `Deeper_Hub.Core.Logger`, `Deeper_Hub.Core.Metrics`

### 8.2. Bibliotecas Externas

*   `Ecto`
*   Opcionalmente, bibliotecas para parsear/renderizar markdown se usado nas mensagens.

## 🤝 9. Como Usar / Integração

*   **UI/Frontend:** Os usuários interagem com o sistema de suporte através de uma interface web ou mobile para criar e acompanhar tickets.
*   **Equipe de Suporte:** Agentes usam uma interface de backoffice para gerenciar e responder aos tickets.
*   O módulo `Notifications` é usado extensivamente para manter todos informados.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar o fluxo completo de criação de ticket, adição de mensagens e mudança de status.
*   Testar as validações de entrada para criação de tickets e mensagens.
*   Testar a lógica de atribuição de tickets (se houver).
*   Testar o envio de notificações em diferentes etapas.
*   Localização: `test/deeper_hub/support/`

### 10.2. Métricas

*   `deeper_hub.support.ticket.created.count` (Contador): Número de tickets criados. Tags: `category`, `priority`.
*   `deeper_hub.support.ticket.resolved.count` (Contador): Número de tickets resolvidos.
*   `deeper_hub.support.ticket.closed.count` (Contador): Número de tickets fechados.
*   `deeper_hub.support.ticket.response_time_hours` (Histograma): Tempo para a primeira resposta a um ticket. Tags: `priority`.
*   `deeper_hub.support.ticket.resolution_time_hours` (Histograma): Tempo total para resolver um ticket. Tags: `priority`.
*   `deeper_hub.support.tickets_open.gauge` (Gauge): Número de tickets atualmente abertos. Tags: `category`.

### 10.3. Logs

*   `Logger.info(\"Ticket #{id} criado por user_id: #{uid}\", module: Deeper_Hub.Support.Services.TicketService)`
*   `Logger.info(\"Mensagem adicionada ao ticket #{id} por author_id: #{aid}\", module: Deeper_Hub.Support.Services.TicketService)`
*   `Logger.info(\"Status do ticket #{id} alterado para #{new_status} por actor_id: #{act_id}\", module: Deeper_Hub.Support.Services.TicketService)`

### 10.4. Telemetria

*   `[:deeper_hub, :support, :ticket, :created]`: Payload: `%{ticket: ticket_struct}`.
*   `[:deeper_hub, :support, :ticket, :message_added]`: Payload: `%{ticket_id: tid, message: message_struct}`.
*   `[:deeper_hub, :support, :ticket, :status_changed]`: Payload: `%{ticket_id: tid, old_status: old, new_status: new, actor_id: aid}`.

## ❌ 11. Tratamento de Erros

*   Falhas de validação na criação de tickets/mensagens retornam `{:error, changeset}`.
*   `{:error, :ticket_not_found}`.
*   `{:error, :unauthorized_action}` (ex: usuário tentando modificar ticket de outro).
*   Erros de comunicação com o serviço de notificações devem ser tratados de forma resiliente.

## 🛡️ 12. Considerações de Segurança

*   **Validação de Conteúdo:** O conteúdo de tickets e mensagens deve ser sanitizado para prevenir XSS, especialmente se for exibido em uma interface web.
*   **Anexos:** Anexos devem ser verificados quanto a malware e tipos de arquivo perigosos.
*   **Controle de Acesso:** Garantir que apenas o criador do ticket e os agentes de suporte autorizados possam visualizar e interagir com um ticket. Notas internas devem ser visíveis apenas para agentes.
*   **Privacidade de Dados:** Tickets podem conter informações pessoais. Proteger o acesso e considerar políticas de retenção para dados de suporte.

## 🧑‍💻 13. Contribuição

*   Novas funcionalidades (ex: atribuição automática, integração com FAQ) devem ser adicionadas em módulos de serviço dedicados ou estendendo o `TicketService`.
*   Manter os fluxos de status e as notificações consistentes.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar uma base de conhecimento (FAQ) e sugerir artigos durante a criação do ticket.
*   [ ] Adicionar atribuição automática de tickets para agentes com base em carga de trabalho ou especialidade.
*   [ ] Suporte para campos customizados em tickets.
*   [ ] Integração com ferramentas de chat de suporte ao vivo.
*   [ ] Implementar SLAs mais detalhados e relatórios de conformidade.
*   [ ] Pesquisa full-text no conteúdo dos tickets.

---

*Última atualização: YYYY-MM-DD*

---

Continuamos com `Deeper_Hub.UserInteractions`?"""),
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
                types.Part.from_text(text="""Perfeito! Próximo README: `Deeper_Hub.UserInteractions`.

---

