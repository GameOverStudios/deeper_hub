# Módulo: `Deeper_Hub.Achievements` 🏆

## 📜 1. Visão Geral do Módulo `Deeper_Hub.Achievements`

O módulo `Deeper_Hub.Achievements` é responsável por gerenciar o sistema de conquistas (achievements) dentro da plataforma Deeper_Hub. Ele permite a definição de várias conquistas, o rastreamento do progresso dos usuários em relação a elas, e a concessão de conquistas quando os critérios são atendidos. O objetivo é engajar e recompensar os usuários por suas interações e marcos alcançados no sistema. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Definição de Conquistas:**
    *   CRUD para Conquistas (`Achievement`): nome, descrição, ícone, critérios para desbloquear, pontos/recompensas associadas.
    *   Suporte a diferentes tipos de conquistas (ex: baseadas em contagem de ações, marcos específicos, participação em eventos, desafios completados).
    *   Agrupamento de conquistas por categorias ou temas.
*   **Rastreamento de Progresso do Usuário:**
    *   Registrar ações de usuários que contribuem para o progresso de uma conquista.
    *   Manter o estado do progresso de cada usuário para cada conquista (ex: `UserAchievement` com campos `progress` e `unlocked_at`).
*   **Desbloqueio de Conquistas:**
    *   Verificar automaticamente se um usuário atendeu aos critérios para desbloquear uma conquista após uma ação relevante.
    *   Marcar uma conquista como desbloqueada para um usuário e registrar a data.
*   **Listagem e Visualização:**
    *   Permitir que usuários visualizem as conquistas disponíveis, seu progresso e as que já desbloquearam.
    *   Fornecer APIs para exibir informações de conquistas em perfis de usuário ou outras áreas da plataforma.
*   **Notificações:**
    *   Notificar usuários quando eles desbloqueiam uma nova conquista (via `Deeper_Hub.Notifications`).
*   **Integração com Outros Módulos:**
    *   Receber eventos de outros módulos (via `Core.EventBus`) que podem acionar o progresso de conquistas (ex: `UserCreatedReviewEvent` do `Deeper_Hub.ServerReviews` pode contar para uma conquista \"Crítico Ativo\").
    *   Potencialmente, desbloquear recompensas do módulo `Deeper_Hub.Rewards` ao alcançar certas conquistas.
*   **Administração de Conquistas:**
    *   Interface para administradores gerenciarem as definições de conquistas.
    *   Capacidade de conceder manualmente uma conquista a um usuário (com auditoria).

## 🏗️ 3. Arquitetura e Design

`Deeper_Hub.Achievements` atuará como uma fachada para um serviço de lógica de negócio e componentes de persistência.

*   **Interface Pública (`Deeper_Hub.Achievements.AchievementsFacade` ou `Deeper_Hub.Achievements`):** Funções como `list_achievements/1`, `get_user_progress/2`, `unlock_achievement_for_user/2`.
*   **Serviço de Conquistas (`Deeper_Hub.Achievements.Services.AchievementsService`):**
    *   Contém a lógica de negócio principal para gerenciar definições de conquistas, processar progresso e desbloquear conquistas.
*   **Schemas Ecto:**
    *   `Deeper_Hub.Achievements.Schema.Achievement`: Define uma conquista.
    *   `Deeper_Hub.Achievements.Schema.UserAchievement`: Rastreia o progresso e o desbloqueio de uma conquista por um usuário.
    *   `Deeper_Hub.Achievements.Schema.AchievementType` (Opcional, herdado de `Lists`): Para categorizar tipos de conquistas.
*   **Processamento de Eventos (Opcional):**
    *   Um GenServer ou worker que escuta eventos do `Core.EventBus` para atualizar o progresso das conquistas de forma assíncrona.
*   **Cache (`Deeper_Hub.Achievements.Cache` ou via `Core.Cache`):**
    *   Cache para definições de conquistas frequentemente acessadas ou progresso de usuários ativos.
*   **Integrações:**
    *   `Deeper_Hub.Core.Repo`: Para persistência.
    *   `Deeper_Hub.Core.EventBus`: Para escutar eventos relevantes de outros módulos.
    *   `Deeper_Hub.Notifications`: Para notificar usuários.
    *   `Deeper_Hub.Rewards` (Potencial): Para associar recompensas a conquistas.

**Padrões de Design:**

*   **Fachada (Facade).**
*   **Serviço de Domínio.**
*   **Observer (via EventBus):** Para reagir a ações em outros módulos.

### 3.1. Componentes Principais

*   **`Deeper_Hub.Achievements.AchievementsFacade`:** Ponto de entrada.
*   **`Deeper_Hub.Achievements.Services.AchievementsService`:** Lógica de negócio.
*   **`Deeper_Hub.Achievements.Schema.Achievement`:** Schema da conquista.
*   **`Deeper_Hub.Achievements.Schema.UserAchievement`:** Schema do progresso do usuário.
*   **`Deeper_Hub.Achievements.EventHandler` (Novo Sugerido):** Módulo/GenServer para lidar com eventos de outros módulos que afetam o progresso.
*   **`Deeper_Hub.Achievements.Supervisor`:** Supervisiona processos.

### 3.3. Decisões de Design Importantes

*   **Definição de Critérios:** Como os critérios para desbloquear conquistas serão definidos e avaliados (ex: código Elixir customizado por conquista, um sistema de regras configurável, contagem de eventos específicos).
*   **Processamento de Progresso:** Se o progresso será atualizado em tempo real (síncrono com a ação do usuário) ou de forma assíncrona (via eventos e workers). Assíncrono é geralmente melhor para performance.
*   **Retroatividade:** Como lidar com a concessão de conquistas retroativamente se novos critérios forem adicionados ou se um bug for corrigido.

## 🛠️ 4. Casos de Uso Principais

*   **Usuário Completa uma Tarefa:** Um usuário posta 10 reviews. Um `EventHandler` no módulo `Achievements` escuta o evento `ReviewCreated`, incrementa um contador para a conquista \"Comentarista Prolífico\" e, se o critério for atingido, desbloqueia a conquista.
*   **Administrador Cria Nova Conquista:** Um admin usa uma interface para definir uma nova conquista \"Explorador\", seus critérios (visitar X servidores diferentes) e seu ícone.
*   **Usuário Visualiza seu Perfil:** O perfil do usuário exibe as conquistas desbloqueadas e o progresso nas conquistas em andamento, buscando dados via `AchievementsFacade`.

## 🌊 5. Fluxos Importantes (Opcional)

**Fluxo de Desbloqueio de Conquista Baseada em Evento:**

1.  Outro módulo (ex: `Deeper_Hub.ServerReviews`) emite um evento (ex: `ReviewCreatedEvent`) no `Core.EventBus` contendo `%{user_id: \"123\", review_id: \"abc\"}`.
2.  `Deeper_Hub.Achievements.EventHandler` (inscrito neste evento) recebe o evento.
3.  O `EventHandler` identifica quais conquistas podem ser afetadas por este tipo de evento (ex: conquista \"Primeira Review\", \"10 Reviews\").
4.  Para cada conquista relevante, o `EventHandler` chama o `AchievementsService` para atualizar o progresso do `user_id`.
5.  O `AchievementsService`:
    *   Busca ou cria o registro `UserAchievement` para o usuário e a conquista.
    *   Atualiza o progresso (ex: incrementa contagem).
    *   Verifica se os critérios da conquista foram atendidos.
    *   Se sim, marca a `UserAchievement` como desbloqueada, define `unlocked_at`.
    *   Persiste as alterações.
    *   Emite um evento `AchievementUnlockedEvent` no `Core.EventBus`.
    *   (Opcional) Enfileira uma notificação para o usuário via `Deeper_Hub.Notifications`.
6.  O `EventHandler` confirma o processamento do evento para o `EventBus`.

## 📡 6. API (Se Aplicável)

### 6.1. `Deeper_Hub.Achievements.list_achievements/1`

*   **Descrição:** Lista todas as definições de conquistas disponíveis no sistema.
*   **`@spec`:** `list_achievements(opts :: Keyword.t()) :: {:ok, list(Achievement.t())} | {:error, reason}`
*   **Parâmetros:**
    *   `opts` (Keyword.t()): Opções de filtragem (ex: `[category: \"social\", include_hidden: false]`).
*   **Retorno:** Lista de structs `Achievement.t()`.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    {:ok, all_achievements} = Deeper_Hub.Achievements.list_achievements()
    ```

### 6.2. `Deeper_Hub.Achievements.get_user_achievements/2`

*   **Descrição:** Lista todas as conquistas de um usuário específico, incluindo seu status (bloqueada, em progresso, desbloqueada) e progresso atual.
*   **`@spec`:** `get_user_achievements(user_id :: String.t(), opts :: Keyword.t()) :: {:ok, list(map())} | {:error, reason}`
    *   O mapa retornado pode ser uma combinação de `Achievement.t()` e `UserAchievement.t()`.
*   **Parâmetros:**
    *   `user_id` (String): O ID do usuário.
    *   `opts` (Keyword.t()): Opções (ex: `[status: :unlocked]`).
*   **Retorno:** Lista de mapas, cada um representando uma conquista e o progresso/status do usuário nela.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    {:ok, my_achievements} = Deeper_Hub.Achievements.get_user_achievements(current_user.id, status: :all)
    ```

### 6.3. `Deeper_Hub.Achievements.record_user_action/3` (Potencial API Interna ou via Eventos)

*   **Descrição:** Registra uma ação de um usuário que pode contribuir para o progresso de uma ou mais conquistas. (Esta função pode ser interna e acionada por eventos, ou uma API para casos específicos).
*   **`@spec`:** `record_user_action(user_id :: String.t(), action_type :: atom(), details :: map()) :: :ok | {:error, reason}`
*   **Parâmetros:**
    *   `user_id`: ID do usuário.
    *   `action_type`: Tipo da ação (ex: `:posted_review`, `:joined_server`).
    *   `details`: Detalhes da ação.
*   **Retorno:** `:ok` se a ação foi processada para progresso.

## ⚙️ 7. Configuração

*   **ConfigManager (`Deeper_Hub.Core.ConfigManager`):**
    *   `[:achievements, :default_icon_url]`: URL de um ícone padrão para conquistas sem ícone específico.
    *   `[:achievements, :notify_on_unlock]`: (Boolean) Se deve enviar notificação ao usuário ao desbloquear uma conquista. (Padrão: `true`)
    *   `[:achievements, :cache, :definitions_ttl_seconds]`: TTL para cache de definições de conquistas.
    *   `[:achievements, :definitions_source]`: Origem das definições de conquistas (ex: `:database`, `:config_file`).

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `Deeper_Hub.Core.Repo`
*   `Deeper_Hub.Core.ConfigManager`
*   `Deeper_Hub.Core.EventBus`
*   `Deeper_Hub.Core.Cache`
*   `Deeper_Hub.Notifications`
*   `Deeper_Hub.Rewards` (Potencial)
*   `Deeper_Hub.Core.Logger`, `Deeper_Hub.Core.Metrics`

### 8.2. Bibliotecas Externas

*   `Ecto`

## 🤝 9. Como Usar / Integração

*   **Outros Módulos:** Publicam eventos no `Core.EventBus` que o `Achievements.EventHandler` escuta para atualizar o progresso.
*   **Frontend/API:** Consomem `get_user_achievements/2` e `list_achievements/1` para exibir informações.

```elixir
# Em Deeper_Hub.ServerReviews, após criar uma review:
# Core.EventBus.publish({:review, :created}, %{user_id: review.user_id, server_id: review.server_id})
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar a lógica de desbloqueio para diferentes tipos de critérios.
*   Testar o processamento de eventos e a atualização correta do progresso.
*   Testar a listagem e visualização de conquistas e progresso.
*   Localização: `test/deeper_hub/achievements/`

### 10.2. Métricas

*   `deeper_hub.achievements.unlocked.count` (Contador): Número de conquistas desbloqueadas. Tags: `achievement_id`, `achievement_type`.
*   `deeper_hub.achievements.progress_updated.count` (Contador): Número de atualizações de progresso. Tags: `achievement_id`.
*   `deeper_hub.achievements.event_handler.processed.count` (Contador): Eventos processados pelo `EventHandler`. Tags: `event_source_module`.

### 10.3. Logs

*   `Logger.info(\"Conquista '#{name}' desbloqueada para user_id: #{id}\", module: Deeper_Hub.Achievements.Services.AchievementsService)`
*   `Logger.debug(\"Progresso da conquista '#{name}' atualizado para user_id: #{id}\", module: Deeper_Hub.Achievements.Services.AchievementsService)`

### 10.4. Telemetria

*   `[:deeper_hub, :achievements, :unlocked]`: Payload: `%{user_id: id, achievement_id: aid, unlocked_at: ts}`.
*   `[:deeper_hub, :achievements, :progress_updated]`: Payload: `%{user_id: id, achievement_id: aid, new_progress: p}`.

## ❌ 11. Tratamento de Erros

*   Falhas ao processar progresso de um evento não devem impedir o processamento de outros eventos.
*   Erros de persistência devem ser logados e, possivelmente, retentados.

## 🛡️ 12. Considerações de Segurança

*   A concessão manual de conquistas deve ser uma operação restrita a administradores e devidamente auditada.
*   Evitar lógicas de critério que possam ser facilmente exploradas por usuários para desbloquear conquistas indevidamente.

## 🧑‍💻 13. Contribuição

*   Ao adicionar novos tipos de critérios para conquistas, garantir que a lógica de avaliação seja eficiente.
*   Manter a documentação das conquistas (descrição, como desbloquear) clara para os usuários.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar um sistema de regras mais flexível para definir critérios de conquistas (ex: via DSL ou configuração JSON).
*   [ ] Adicionar conquistas \"secretas\" ou de múltiplos estágios.
*   [ ] Permitir que usuários compartilhem suas conquistas.
*   [ ] Interface de admin para gerenciar conquistas e visualizar progresso dos usuários.
*   [ ] Suporte para conquistas baseadas em tempo (ex: \"Logar por 7 dias seguidos\").

---

*Última atualização: YYYY-MM-DD*

---

Este é o README para `Deeper_Hub.Achievements`. O próximo da lista seria `Deeper_Hub.Challenges`. Quer seguir com ele?"""),
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
                types.Part.from_text(text="""Excelente! Vamos para o README do `Deeper_Hub.Challenges`.

---

