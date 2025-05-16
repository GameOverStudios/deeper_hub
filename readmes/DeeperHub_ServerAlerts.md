# Módulo: `Deeper_Hub.ServerAlerts` 🚨

## 📜 1. Visão Geral do Módulo `Deeper_Hub.ServerAlerts`

O módulo `Deeper_Hub.ServerAlerts` é responsável por gerenciar e disseminar alertas relacionados a servidores específicos dentro da plataforma Deeper_Hub. Estes alertas são mensagens importantes que os proprietários de servidores ou administradores da plataforma podem querer comunicar aos usuários de um servidor ou a todos os usuários da plataforma sobre um servidor específico. Exemplos incluem anúncios de manutenção, status do servidor, problemas técnicos urgentes, ou notificações sobre eventos importantes relacionados a um servidor. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Criação e Gerenciamento de Alertas:**
    *   CRUD para Alertas (`Alert`): título, mensagem, tipo/severidade do alerta (ex: informação, aviso, crítico), servidor associado (`server_id`), usuário que criou o alerta.
    *   Definição de público alvo para o alerta (ex: todos os usuários, apenas membros/seguidores do servidor, usuários online no servidor).
    *   Agendamento de alertas para exibição futura.
    *   Definição de tempo de expiração ou remoção manual de alertas.
*   **Exibição de Alertas:**
    *   Fornecer uma API para que a UI ou outros sistemas possam buscar alertas ativos para serem exibidos aos usuários relevantes.
    *   Formas de exibição podem incluir banners no site, notificações in-app, ou pop-ups.
*   **Notificações (Integração):**
    *   Integrar com `Deeper_Hub.Notifications` para enviar alertas urgentes por canais como email ou push, dependendo das preferências do usuário e da severidade do alerta.
*   **Controle de Ativação e Visibilidade:**
    *   Habilitar/desabilitar alertas.
    *   Marcar alertas como \"lidos\" por usuário (se necessário para alertas persistentes).
*   **Administração de Alertas:**
    *   Interface para proprietários de servidores criarem e gerenciarem alertas para seus servidores.
    *   Interface para administradores da plataforma criarem alertas globais sobre servidores ou gerenciarem/moderarem alertas de servidores.

## 🏗️ 3. Arquitetura e Design

`Deeper_Hub.ServerAlerts` atuará como uma fachada para um serviço de lógica de negócio e componentes de persistência.

*   **Interface Pública (`Deeper_Hub.ServerAlerts.ServerAlertsFacade` ou `Deeper_Hub.ServerAlerts`):** Funções como `create_alert/1`, `list_active_alerts_for_server/1`, `list_active_alerts_for_user/1`.
*   **Serviço de Alertas de Servidor (`Deeper_Hub.ServerAlerts.Services.AlertService`):**
    *   Contém a lógica de negócio principal para definir, gerenciar e disseminar alertas.
*   **Schemas Ecto:**
    *   `Deeper_Hub.ServerAlerts.Schema.Alert`: Define um alerta de servidor.
    *   `Deeper_Hub.ServerAlerts.Schema.UserAlertView` (Opcional): Para rastrear quais usuários visualizaram/dispensaram quais alertas.
*   **Cache (`Deeper_Hub.ServerAlerts.Cache` ou via `Core.Cache`):**
    *   Cache para alertas ativos frequentemente requisitados para exibição.
*   **Workers (via `Core.BackgroundTaskManager`):**
    *   Worker para gerenciar o ciclo de vida dos alertas (ativar alertas agendados, expirar alertas).
*   **Integrações:**
    *   `Deeper_Hub.Core.Repo`: Para persistência.
    *   `Deeper_Hub.Servers`: Para associar alertas a servidores.
    *   `Deeper_Hub.Accounts`: Para associar alertas a usuários criadores e para determinar o público alvo.
    *   `Deeper_Hub.Notifications`: Para enviar alertas por canais de notificação.

**Padrões de Design:**

*   **Fachada (Facade).**
*   **Serviço de Domínio.**

### 3.1. Componentes Principais

*   **`Deeper_Hub.ServerAlerts.ServerAlertsFacade`:** Ponto de entrada.
*   **`Deeper_Hub.ServerAlerts.Services.AlertService`:** Lógica de negócio.
*   **`Deeper_Hub.ServerAlerts.Schema.Alert`:** Schema do alerta.
*   **`Deeper_Hub.ServerAlerts.Supervisor`:** Supervisiona processos.
*   **Workers (ex: `AlertLifecycleWorker`).**

### 3.3. Decisões de Design Importantes

*   **Escopo dos Alertas:** Definir claramente se os alertas são apenas por servidor, ou se pode haver alertas \"globais\" da plataforma sobre um servidor específico.
*   **Mecanismo de Entrega/Exibição:** Como os alertas são efetivamente mostrados aos usuários (banner no topo, notificação in-app, etc.) será provavelmente responsabilidade da UI, mas este módulo fornece os dados.
*   **\"Lido\" vs. \"Dispensado\":** Como lidar com alertas que o usuário já viu.

## 🛠️ 4. Casos de Uso Principais

*   **Proprietário de Servidor Anuncia Manutenção:** O dono do servidor cria um alerta: \"Manutenção programada para hoje às 23:00 UTC por 1 hora.\"
*   **Administrador da Plataforma Alerta sobre Problema em um Servidor Popular:** Um admin cria um alerta visível para todos os usuários sobre instabilidade em um servidor específico.
*   **Usuário Vê Alertas Ativos:** Ao visitar a página de um servidor, o usuário vê quaisquer alertas ativos para aquele servidor.
*   **Sistema Remove Alerta Expirado:** Um worker remove automaticamente um alerta cujo `expires_at` já passou.

## 🌊 5. Fluxos Importantes (Opcional)

**Fluxo de Criação e Notificação de um Alerta Crítico:**

1.  Proprietário do servidor (ou admin) submete dados de um novo alerta crítico via API/UI.
2.  `Deeper_Hub.API` (Controller) chama `Deeper_Hub.ServerAlerts.create_alert(params)`.
3.  `AlertService` valida os dados e cria um registro `Alert` com status `active` e severidade `critical`.
4.  Um evento `ServerAlertCreatedEvent` é publicado no `Core.EventBus`.
5.  `Deeper_Hub.Notifications` (ou um handler de evento específico) escuta este evento.
6.  Com base na criticidade e no público alvo do alerta, `Notifications` envia notificações por canais apropriados (ex: push notification para seguidores do servidor).
7.  A UI que exibe alertas busca os alertas ativos para o servidor/usuário e exibe a nova mensagem.

## 📡 6. API (Se Aplicável)

### 6.1. `Deeper_Hub.ServerAlerts.create_alert/1`

*   **Descrição:** Cria um novo alerta para um servidor.
*   **`@spec`:** `create_alert(attrs :: map()) :: {:ok, Alert.t()} | {:error, Ecto.Changeset.t() | reason}`
*   **Parâmetros:**
    *   `attrs` (map): Atributos do alerta.
        *   `:server_id` (String, obrigatório): ID do servidor ao qual o alerta se refere.
        *   `:created_by_user_id` (String, obrigatório): ID do usuário que está criando o alerta.
        *   `:title` (String, obrigatório): Título curto do alerta.
        *   `:message` (String, obrigatório): Conteúdo detalhado do alerta.
        *   `:severity` (atom, opcional): Nível de severidade (ex: `:info`, `:warning`, `:critical`). (Padrão: `:info`)
        *   `:target_audience` (atom, opcional): Público do alerta (ex: `:all_server_users`, `:server_followers`, `:platform_wide_for_server`). (Padrão: `:all_server_users`)
        *   `:starts_at` (DateTime.t(), opcional): Quando o alerta deve começar a ser exibido. (Padrão: agora)
        *   `:expires_at` (DateTime.t(), opcional): Quando o alerta deve parar de ser exibido.
*   **Retorno:** O alerta criado ou um changeset com erros.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    alert_attrs = %{
      server_id: \"server_123\",
      created_by_user_id: \"admin_user_abc\",
      title: \"Manutenção Urgente\",
      message: \"O servidor ficará offline por aproximadamente 30 minutos para uma manutenção urgente.\",
      severity: :critical,
      expires_at: DateTime.add(DateTime.utc_now(), 1, :hour)
    }
    case Deeper_Hub.ServerAlerts.create_alert(alert_attrs) do
      {:ok, alert} -> Logger.info(\"Alerta #{alert.id} criado: #{alert.title}\")
      {:error, reason} -> Logger.error(\"Falha ao criar alerta: #{inspect(reason)}\")
    end
    ```

### 6.2. `Deeper_Hub.ServerAlerts.list_active_alerts_for_user/2`

*   **Descrição:** Lista todos os alertas ativos que são relevantes para um usuário específico (ex: para servidores que ele segue ou alertas globais sobre servidores).
*   **`@spec`:** `list_active_alerts_for_user(user_id :: String.t(), opts :: Keyword.t()) :: {:ok, list(Alert.t())} | {:error, reason}`
*   **Parâmetros:**
    *   `user_id` (String): O ID do usuário.
    *   `opts` (Keyword.t()): Opções de filtragem (ex: `[limit: 5]`).
*   **Retorno:** Lista de alertas ativos relevantes para o usuário.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    {:ok, user_alerts} = Deeper_Hub.ServerAlerts.list_active_alerts_for_user(current_user.id)
    ```

*(Outras funções como `get_alert/1`, `update_alert/2`, `delete_alert/1`, `list_alerts_by_server/2` seriam documentadas aqui).*

## ⚙️ 7. Configuração

*   **ConfigManager (`Deeper_Hub.Core.ConfigManager`):**
    *   `[:server_alerts, :default_severity]`: Severidade padrão para novos alertas. (Padrão: `:info`)
    *   `[:server_alerts, :default_expiration_hours]`: Duração padrão em horas para alertas sem `expires_at` explícito. (Padrão: `24`)
    *   `[:server_alerts, :worker, :lifecycle_check_interval_minutes]`: Intervalo para o worker verificar e atualizar status de alertas. (Padrão: `5`)
    *   `[:server_alerts, :max_active_alerts_display]`: Limite de alertas a serem exibidos simultaneamente na UI (a UI pode ter sua própria lógica).

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `Deeper_Hub.Core.Repo`
*   `Deeper_Hub.Core.ConfigManager`
*   `Deeper_Hub.Core.EventBus`
*   `Deeper_Hub.Core.BackgroundTaskManager`
*   `Deeper_Hub.Notifications`
*   `Deeper_Hub.Servers`
*   `Deeper_Hub.Accounts`
*   `Deeper_Hub.Core.Logger`, `Deeper_Hub.Core.Metrics`

### 8.2. Bibliotecas Externas

*   `Ecto`

## 🤝 9. Como Usar / Integração

*   **UI/Frontend:** Busca e exibe alertas relevantes para o usuário ou para a página de servidor que está sendo visualizada.
*   **API de Gerenciamento:** Proprietários de servidor e administradores da plataforma interagem com a API para criar e gerenciar alertas.
*   O módulo `Notifications` pode ser acionado para enviar alertas críticos por canais mais diretos.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar CRUD de alertas.
*   Testar a lógica de ativação e expiração de alertas pelo worker.
*   Testar a listagem de alertas com diferentes filtros e para diferentes públicos alvo.
*   Testar o envio de notificações para alertas críticos.
*   Localização: `test/deeper_hub/server_alerts/`

### 10.2. Métricas

*   `deeper_hub.server_alerts.created.count` (Contador): Tags: `server_id`, `severity`, `target_audience`.
*   `deeper_hub.server_alerts.displayed.count` (Contador): (Se rastreável) Número de vezes que alertas foram exibidos. Tags: `alert_id`.
*   `deeper_hub.server_alerts.expired.count` (Contador): Tags: `alert_id`.
*   `deeper_hub.server_alerts.active.gauge` (Gauge): Número de alertas atualmente ativos.

### 10.3. Logs

*   `Logger.info(\"Alerta '#{title}' (ID: #{id}) criado para o servidor #{server_id}\", module: Deeper_Hub.ServerAlerts.Services.AlertService)`
*   `Logger.info(\"Alerta #{id} ativado/expirado.\", module: Deeper_Hub.ServerAlerts.Workers.AlertLifecycleWorker)`

### 10.4. Telemetria

*   `[:deeper_hub, :server_alerts, :created | :updated | :deleted | :status_changed]`
*   `[:deeper_hub, :server_alerts, :notification_sent]` (quando integrado com Notifications)

## ❌ 11. Tratamento de Erros

*   `{:error, :server_not_found}`
*   `{:error, :alert_not_found}`
*   `{:error, :unauthorized_action}` (ex: usuário tentando criar alerta para servidor que não é dele).
*   Falhas na validação dos dados do alerta.

## 🛡️ 12. Considerações de Segurança

*   **Validação de Conteúdo:** Títulos e mensagens de alertas devem ser sanitizados para prevenir XSS, pois podem ser exibidos diretamente na UI.
*   **Abuso do Sistema de Alertas:** Limitar a frequência com que alertas podem ser criados por um servidor ou usuário para evitar spam.
*   **Permissões:** Controlar rigorosamente quem pode criar alertas de alta severidade ou com público alvo amplo (ex: `platform_wide`).

## 🧑‍💻 13. Contribuição

*   A lógica de seleção de público alvo pode ser expandida.
*   Novos tipos de severidade ou categorias de alerta podem ser adicionados.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Permitir que usuários \"dispensem\" alertas para não vê-los novamente.
*   [ ] Adicionar suporte para alertas com ações (ex: um botão \"Saiba Mais\" no alerta).
*   [ ] Permitir que proprietários de servidor vejam estatísticas de visualização de seus alertas.
*   [ ] Integração com sistemas de status de terceiros para postar automaticamente alertas sobre servidores.
*   [ ] Templates para alertas comuns.

---

*Última atualização: YYYY-MM-DD*

---

O próximo da lista de \"Services\" seria `Deeper_Hub.ServerTags`. Você mencionou que já tem um README para ele (`Deeper_Hub_ServerTags.md`). Quer que eu crie um novo seguindo este padrão detalhado, ou prefere que eu revise o que você já tem e sugira adições/alterações com base neste template? Ou podemos pular para o próximo item inédito?"""),
            ],
        ),
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(text="""faz um novo e mostre completo
"""),
            ],
        ),
        types.Content(
            role="model",
            parts=[
                types.Part.from_text(text="""Entendido! Vamos criar um README novo e completo para `Deeper_Hub.ServerTags`, seguindo o padrão que estabelecemos.

---

