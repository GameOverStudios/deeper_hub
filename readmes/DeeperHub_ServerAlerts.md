# Módulo: `DeeperHub.ServerAlerts` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.ServerAlerts`

O módulo `DeeperHub.ServerAlerts` é responsável por gerenciar e entregar **alertas e anúncios importantes** dos proprietários de servidores para os jogadores ou para a comunidade de um servidor específico na plataforma DeeperHub. Diferentemente de mensagens de atualização mais longas (como patch notes, gerenciadas por `ServerUpdateMessages`), os alertas são tipicamente mensagens mais curtas, diretas e que podem ter um caráter de urgência ou aviso.

Exemplos incluem:
*   Anúncio de reinício iminente do servidor.
*   Aviso sobre problemas técnicos temporários.
*   Notificação de um evento especial começando agora.
*   Mensagens de boas-vindas para novos jogadores no servidor (se não automatizadas de outra forma).

Este módulo lida com a criação, visualização e, potencialmente, a forma como esses alertas são exibidos ou entregues aos usuários relevantes. 😊

*(Nota: Na documentação original, este era `DeeperHub.Services.ServerAlerts`. Será tratado como `DeeperHub.ServerAlerts`.)*

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Criação de Alertas (`create_alert/1`):**
    *   Permitir que proprietários de servidores (ou administradores com permissão) criem novos alertas para seus servidores.
    *   Cada alerta inclui: mensagem, tipo/severidade (ex: `:info`, `:warning`, `:critical`), servidor associado, data de início e fim de validade/exibição (opcional).
*   **Gerenciamento de Alertas (`update_alert/2`, `delete_alert/1`):**
    *   Permitir a edição (se o alerta ainda não foi amplamente disseminado) ou exclusão de alertas.
    *   Marcar alertas como ativos ou inativos.
*   **Listagem de Alertas:**
    *   Listar alertas ativos para um servidor específico (`list_active_alerts_by_server/2`).
    *   Listar todos os alertas (histórico) para um servidor (`list_alerts_by_server/2`).
    *   (Opcional) Listar alertas globais da plataforma, se essa funcionalidade também residir aqui.
*   **Exibição/Entrega de Alertas:**
    *   Fornecer dados para que a UI exiba alertas relevantes (ex: um banner no topo da página do servidor, uma notificação in-app específica para quem está online naquele servidor).
    *   (Opcional) Integrar com `DeeperHub.Notifications` para enviar alertas como notificações push ou email para usuários inscritos em alertas de um servidor (se o usuário \"seguir\" o servidor ou optar por isso).
*   **Tipos de Alertas:**
    *   Suportar diferentes tipos de alertas que podem ter apresentações ou comportamentos distintos (ex: um alerta de \"manutenção\" pode ter um contador regressivo).
*   **Programação de Alertas (Opcional):**
    *   Permitir que alertas sejam agendados para aparecer em um horário específico.
*   **Observabilidade e Auditoria:**
    *   Logar a criação e modificação de alertas.
    *   Publicar eventos de domínio (ex: `server_alert.published`) no `Core.EventBus`.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.ServerAlerts` (Fachada Pública):**
    *   Ponto de entrada para operações de alertas de servidor.
    *   Delega para o `ServerAlertsService`.
2.  **`DeeperHub.ServerAlerts.Services.ServerAlertsService` (ou `DefaultServerAlertsService`):**
    *   **Responsabilidade:** Orquestra a lógica de negócio.
    *   **Interações:**
        *   `DeeperHub.Core.Repo`: Para CRUD com `AlertSchema`.
        *   `DeeperHub.Servers`: Para validar `server_id`.
        *   `DeeperHub.Accounts`: Para `user_id` do criador.
        *   `DeeperHub.Auth`/`RBAC`: Para permissões.
        *   `DeeperHub.Core.EventBus`.
        *   `DeeperHub.Core.Cache`: Para cachear alertas ativos.
        *   `DeeperHub.Notifications` (se alertas são enviados como notificações push/email).
3.  **`DeeperHub.ServerAlerts.Schemas.AlertSchema` (ex-`Alert`):**
    *   Campos: `id`, `server_id`, `created_by_user_id`, `message` (string/text), `alert_type` (atom, ex: `:info`, `:warning`, `:maintenance`, `:event_starting`), `severity` (atom, ex: `:low`, `:medium`, `:high`), `start_time` (DateTime UTC, para exibição agendada), `end_time` (DateTime UTC, para expiração automática), `is_active` (boolean), `target_audience` (atom, ex: `:all_server_players`, `:specific_roles_on_server` - opcional), `inserted_at`, `updated_at`.
4.  **`DeeperHub.ServerAlerts.Storage` (ou lógica no `ServerAlertsService`):**
    *   Encapsula as queries Ecto.
5.  **`DeeperHub.ServerAlerts.CachedAdapter` (Opcional):**
    *   Camada de cache explícita.
6.  **Workers (Opcional):**
    *   `AlertStatusUpdateWorker`: Para ativar/desativar alertas com base em `start_time` e `end_time`.

### 3.2. Estrutura de Diretórios (Proposta)

```
lib/deeper_hub/server_alerts/
├── server_alerts.ex                  # Fachada Pública
│
├── services/
│   └── server_alerts_service.ex      # Serviço principal
│
├── schemas/
│   └── alert_schema.ex
│
├── storage.ex                        # (Opcional)
├── cached_adapter.ex                 # (Opcional)
│
├── workers/                          # Opcional
│   └── alert_status_update_worker.ex
│
├── supervisor.ex                     # (Se houver GenServers)
└── telemetry.ex
```

### 3.3. Decisões de Design Importantes

*   **Diferenciação de `ServerUpdateMessages`:** Alertas são geralmente mais curtos, mais imediatos e podem ter um \"tempo de vida\" mais curto. `UpdateMessages` são mais para notas de patch e anúncios mais permanentes.
*   **Mecanismo de Exibição:** Como os alertas são mostrados aos usuários é uma decisão de UI/UX, mas este módulo precisa fornecer os dados de forma que possam ser facilmente consumidos (ex: \"mostrar os 3 alertas ativos mais recentes para este servidor\").
*   **Targeting de Audiência:** Inicialmente simples (todos os visitantes da página do servidor), mas pode evoluir para targeting mais específico.

## 🛠️ 4. Casos de Uso Principais

*   **Proprietário Anuncia Reinício Iminente do Servidor:**
    *   Cria um alerta: \"Servidor reiniciando em 15 minutos para atualização rápida!\" com tipo `:maintenance` e severidade `:high`.
    *   API chama `ServerAlerts.create_alert(user_id, server_id, attrs)`.
    *   O alerta aparece em destaque na página do servidor.
*   **Proprietário Avisa sobre Lag Temporário:**
    *   Cria um alerta: \"Estamos experienciando lag temporário devido a um problema com o provedor. Estamos trabalhando nisso.\" tipo `:warning`, severidade `:medium`.
*   **Jogador Visita a Página de um Servidor:**
    *   A UI chama uma API que internamente usa `ServerAlerts.list_active_alerts_by_server(server_id, %{limit: 3})` para buscar alertas a serem exibidos.

## 🌊 5. Fluxos Importantes

### Fluxo de Criação e Exibição de Alerta

1.  **Proprietário (UI):** Submete formulário de novo alerta.
2.  **Controller API:** Valida auth. Chama `DeeperHub.ServerAlerts.create_alert(current_user.id, server_id, params[\"alert_attrs\"])`.
3.  **`ServerAlertsService.create_alert/3`:**
    *   Valida permissão.
    *   Valida e sanitiza a mensagem.
    *   Cria um `AlertSchema` changeset (com `is_active: true`, `start_time` pode ser `now` ou futuro).
    *   `Core.Repo.insert(changeset)`.
    *   Se sucesso:
        *   Publica evento `server_alert.created` no `Core.EventBus`.
        *   Invalida cache de alertas ativos para o servidor.
        *   (Opcional) Se `start_time` for imediato e houver integração com notificações push/in-app para \"seguidores\", enfileira essas notificações.
        *   Retorna `{:ok, alert_struct}`.
4.  **Outro Usuário (UI):** Visita a página do servidor.
5.  **Controller API da Página do Servidor:** Chama `DeeperHub.ServerAlerts.list_active_alerts_by_server(server_id, %{limit: 3})`.
6.  **`ServerAlertsService.list_active_alerts_by_server/2`:**
    *   Verifica o cache.
    *   Se miss, constrói query Ecto para buscar `AlertSchema`s onde `server_id` corresponde, `is_active == true`, e `(start_time == nil OR start_time <= now()) AND (end_time == nil OR end_time >= now())`.
    *   Ordena por `inserted_at` descendente ou prioridade.
    *   Coloca no cache.
    *   Retorna a lista de alertas.
7.  **UI:** Exibe os alertas.

## 📡 6. API (Funções Públicas da Fachada `DeeperHub.ServerAlerts`)

*(Baseado na documentação original para `Alert` e expandindo)*

### 6.1. Gerenciamento de Alertas (Proprietário/Admin)

*   **`DeeperHub.ServerAlerts.create_alert(creator_user_id :: String.t(), server_id :: String.t(), attrs :: map()) :: {:ok, Alert.t()} | {:error, Ecto.Changeset.t()}`**
    *   `attrs`: `%{message: String.t(), alert_type: atom(), severity: atom() | nil, start_time: DateTime.t() | nil, end_time: DateTime.t() | nil}`.
*   **`DeeperHub.ServerAlerts.update_alert(alert_id :: String.t(), attrs :: map(), current_user_id :: String.t()) :: {:ok, Alert.t()} | {:error, Ecto.Changeset.t() | :unauthorized}`**
*   **`DeeperHub.ServerAlerts.delete_alert(alert_id :: String.t(), current_user_id :: String.t()) :: :ok | {:error, :unauthorized | :not_found}`**
*   **`DeeperHub.ServerAlerts.activate_alert(alert_id :: String.t(), current_user_id :: String.t()) :: {:ok, Alert.t()}`** (Muda `is_active` para true)
*   **`DeeperHub.ServerAlerts.deactivate_alert(alert_id :: String.t(), current_user_id :: String.t()) :: {:ok, Alert.t()}`** (Muda `is_active` para false)

### 6.2. Consulta de Alertas

*   **`DeeperHub.ServerAlerts.get_alert(alert_id :: String.t()) :: {:ok, Alert.t() | nil}`**
*   **`DeeperHub.ServerAlerts.list_alerts_by_server(server_id :: String.t(), opts :: keyword()) :: {:ok, list(Alert.t()), Pagination.t()}`**
    *   `opts`: `:is_active` (boolean), `:alert_type`, `:severity`, `:page`, `:per_page`, `:sort_by`.
*   **`DeeperHub.ServerAlerts.list_active_alerts_by_server(server_id :: String.t(), opts :: keyword()) :: {:ok, list(Alert.t())}`** (Atalho para `list_alerts_by_server` com filtros de atividade e data).
    *   `opts`: `:limit`.
*   **`DeeperHub.ServerAlerts.broadcast_alert/3` (da doc original, mas parece mais uma ação de alto nível que *usa* `create_alert` internamente para múltiplos usuários se o targeting for para usuários específicos, ou apenas cria um alerta de servidor se for para todos do servidor):**
    *   Se a intenção é notificar múltiplos usuários via `DeeperHub.Notifications` e também criar um `AlertSchema` visível na página do servidor, este nome faz sentido.
    *   `broadcast_alert(server_id, message, user_ids_or_target_group)`

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager`:

*   **`[:server_alerts, :enabled]`** (Boolean).
*   **`[:server_alerts, :max_message_length]`** (Integer). (Padrão: `500`)
*   **`[:server_alerts, :default_alert_duration_minutes]`** (Integer | nil): Se `end_time` não for fornecido, quanto tempo o alerta fica ativo. `nil` para indefinido. (Padrão: `60`)
*   **`[:server_alerts, :max_active_alerts_per_server_displayed]`** (Integer): Quantos alertas ativos mostrar na UI de uma vez. (Padrão: `3`)
*   **`[:server_alerts, :allowed_alert_types]`** (List de Atoms).
*   **`[:server_alerts, :cache, :active_alerts_ttl_seconds]`** (Integer).
*   **`[:server_alerts, :worker, :status_update_interval_minutes]`** (Integer).

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.*`.
*   `DeeperHub.Servers`: Para `server_id`.
*   `DeeperHub.Accounts`: Para `created_by_user_id`.
*   `DeeperHub.Auth`/`RBAC`: Para permissões.
*   `DeeperHub.Notifications` (Opcional): Se alertas também disparam notificações formais.
*   `DeeperHub.Security.XssProtection` / `Shared.ContentValidation`: Para sanitizar mensagens.

### 8.2. Bibliotecas Externas

*   `Ecto`.

## 🤝 9. Como Usar / Integração

*   **UI do Proprietário do Servidor:** Formulários para criar/gerenciar alertas.
*   **Página do Servidor (UI do Jogador):** Seção para exibir alertas ativos (`list_active_alerts_by_server`).
*   **`AlertStatusUpdateWorker`:** Para gerenciar o ciclo de vida de alertas agendados/expirados.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar CRUD para `AlertSchema`.
*   Testar a lógica de `is_active` com `start_time` e `end_time`.
*   Testar a listagem de alertas ativos vs. todos os alertas.
*   Testar a sanitização da mensagem do alerta.
*   Localização: `test/deeper_hub/server_alerts/`.

### 10.2. Métricas

*   `deeper_hub.server_alerts.created.count` (tags: `server_id`, `alert_type`, `severity`)
*   `deeper_hub.server_alerts.displayed.count` (tags: `server_id`, `alert_id`) (Se o rastreamento de visualização for implementado).
*   `deeper_hub.server_alerts.active.gauge` (Gauge, tags: `server_id`)

### 10.3. Logs

*   **Nível INFO:** Novo alerta criado/publicado. Alerta expirado/desativado.
*   **Nível WARNING:** Tentativa não autorizada de gerenciar um alerta.

### 10.4. Telemetria

*   `[:deeper_hub, :server_alerts, :alert, :created | :updated | :deleted | :status_changed]`
    *   Metadados: `%{alert_id: id, server_id: id, author_id: id, new_status: atom_if_changed}`

## ❌ 11. Tratamento de Erros

*   Falhas de validação ao criar/atualizar retornam `{:error, changeset}`.
*   Operações não autorizadas retornam `{:error, :unauthorized}`.

## 🛡️ 12. Considerações de Segurança

*   **Sanitização de Conteúdo:** A mensagem do alerta deve ser sanitizada para prevenir XSS, pois é exibida na UI.
*   **Autorização:** Apenas proprietários de servidores ou administradores devem poder criar/gerenciar alertas para um servidor.
*   **Abuso:** Limitar a frequência com que alertas podem ser postados ou o número de alertas ativos para evitar spam visual.

## 🧑‍💻 13. Contribuição

*   Novos tipos de alerta ou severidades devem ser adicionados à configuração.
*   Considere como os alertas serão renderizados na UI ao definir o comprimento e o tipo de conteúdo.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Permitir \"fixar\" um alerta importante para que ele permaneça visível por mais tempo ou no topo.
*   [ ] Suporte para alertas com ações (ex: um botão \"Junte-se ao Evento Agora!\" em um alerta de início de evento).
*   [ ] Permitir que usuários individuais \"dispensem\" alertas que já viram.
*   [ ] Histórico de alertas para administradores com mais detalhes de quem criou/modificou.
*   [ ] Internacionalização das mensagens de alerta se o conteúdo for padronizado para certos tipos.

---

*Última atualização: 2025-05-12*

---

Este cobre os Alertas de Servidor! Eles são uma forma útil de comunicação rápida.

Para o próximo, podemos fazer o `DeeperHub.ServerUpdateMessages` (que é para comunicação mais longa, como patch notes), ou `DeeperHub.Lists` (o módulo genérico de listas da documentação original), ou algum outro?"""),
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
                types.Part.from_text(text="""Já detalhamos o `DeeperHub.ServerUpdateMessages`.

Vamos agora para o `DeeperHub.Lists`. Este módulo, conforme a documentação original, parece ser um local para armazenar listas de dados genéricos como tipos de conquistas, categorias, tipos de conteúdo, engines de jogos, etc. Essencialmente, dados de enumeração ou \"lookup tables\".

---

