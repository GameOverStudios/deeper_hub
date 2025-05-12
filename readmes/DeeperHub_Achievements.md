# Módulo: `DeeperHub.Achievements` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Achievements`

O módulo `DeeperHub.Achievements` é responsável por gerenciar o **sistema de conquistas (achievements)** dentro da plataforma DeeperHub. Ele permite a definição de várias conquistas que os usuários podem desbloquear ao realizar certas ações, atingir marcos ou participar de atividades específicas no sistema.

Este módulo lida com:
*   A definição e o gerenciamento das próprias conquistas (nome, descrição, critérios, ícone, pontos, etc.).
*   O rastreamento do progresso dos usuários em relação às conquistas.
*   A concessão de conquistas aos usuários quando os critérios são atendidos.
*   A consulta de conquistas desbloqueadas por um usuário e a listagem de todas as conquistas disponíveis.

O objetivo é engajar os usuários, recompensar a participação e fornecer um senso de progressão e reconhecimento dentro da plataforma. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Gerenciamento de Definições de Conquistas (`create_achievement_definition/1`, `update_achievement_definition/2`, etc.):**
    *   Permitir que administradores criem, visualizem, atualizem e excluam as definições das conquistas disponíveis no sistema.
    *   Cada definição inclui: nome, descrição, ícone, critérios para desbloqueio (podem ser complexos e baseados em eventos), pontos de recompensa (se houver), tipo de conquista (ex: marco, evento, exploração), raridade.
*   **Rastreamento de Progresso do Usuário:**
    *   Receber eventos do sistema (via `Core.EventBus` ou chamadas diretas) que indicam progresso do usuário em relação a uma conquista.
    *   Manter o estado do progresso para conquistas que exigem múltiplas etapas ou contadores.
*   **Concessão de Conquistas (`unlock_achievement_for_user/3`):**
    *   Verificar automaticamente se um usuário atendeu aos critérios para desbloquear uma conquista após um evento relevante.
    *   Registrar que um usuário desbloqueou uma conquista específica, incluindo a data.
    *   Garantir que uma conquista só possa ser desbloqueada uma vez por usuário (a menos que seja repetível).
*   **Consulta de Conquistas:**
    *   Listar todas as conquistas disponíveis no sistema, com filtros (ex: por tipo, por jogo/serviço associado, se aplicável) (`list_achievement_definitions/1`).
    *   Listar todas as conquistas desbloqueadas por um usuário específico (`list_user_unlocked_achievements/1`).
    *   Verificar o status de uma conquista específica para um usuário (bloqueada, em progresso, desbloqueada) (`get_user_achievement_status/2`).
*   **Notificações (Integração):**
    *   Notificar usuários quando eles desbloqueiam uma nova conquista (via `DeeperHub.Notifications`).
*   **Observabilidade e Auditoria:**
    *   Registrar logs e métricas sobre definições de conquistas e desbloqueios.
    *   Publicar eventos de domínio (ex: `achievement.unlocked`) no `Core.EventBus`.
    *   Auditar a criação/modificação de definições de conquistas por administradores.
*   **Caching:**
    *   Cachear definições de conquistas e, potencialmente, listas de conquistas desbloqueadas por usuários ativos para performance.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.Achievements` (Fachada Pública):**
    *   Ponto de entrada para todas as operações relacionadas a conquistas.
    *   Delega para o `AchievementsService`.
2.  **`DeeperHub.Achievements.Services.AchievementsService` (ou `DefaultAchievementsService`):**
    *   **Responsabilidade:** Orquestra a lógica de negócio principal para o sistema de conquistas.
    *   **Interações:**
        *   `DeeperHub.Core.Repo`: Para CRUD com `AchievementDefinitionSchema` e `UserAchievementSchema`.
        *   `DeeperHub.Core.EventBus`: Para escutar eventos do sistema que podem acionar progresso ou desbloqueio de conquistas, e para publicar eventos de `achievement.unlocked`.
        *   `DeeperHub.Core.Cache`: Para cachear definições e conquistas de usuários.
        *   `DeeperHub.Core.ConfigManager`: Para configurações (ex: se o sistema de conquistas está habilitado globalmente).
        *   `DeeperHub.Notifications`: Para notificar usuários sobre desbloqueios.
        *   `DeeperHub.Audit`: Para auditar gerenciamento de definições.
3.  **Schemas Ecto:**
    *   **`DeeperHub.Achievements.Schemas.AchievementDefinitionSchema`:** Armazena os detalhes de cada conquista (nome, descrição, critérios como JSON ou DSL, ícone, pontos, tipo, etc.).
    *   **`DeeperHub.Achievements.Schemas.UserAchievementSchema`:** Tabela de junção que registra qual usuário (`user_id`) desbloqueou qual conquista (`achievement_definition_id`) e quando (`unlocked_at`). Pode também armazenar progresso para conquistas com múltiplas etapas.
4.  **`DeeperHub.Achievements.Storage` (ou lógica dentro do `AchievementsService`):**
    *   Encapsula as queries Ecto.
5.  **`DeeperHub.Achievements.CriterionEvaluator` (Módulo Funcional ou Serviço):**
    *   **Responsabilidade:** Avaliar se os critérios de uma `AchievementDefinition` foram atendidos por um usuário com base em seus dados, progresso ou eventos recebidos. A lógica dos critérios pode ser complexa (ex: \"fazer login 7 dias seguidos\", \"derrotar 100 inimigos do tipo X\", \"visitar todas as 5 regiões do mapa\").
6.  **`DeeperHub.Achievements.EventListener` (GenServer ou módulo que implementa callback do EventBus):**
    *   **Responsabilidade:** Escutar eventos relevantes do `Core.EventBus` (ex: `user.action_performed`, `server.review_posted`, `game.level_completed`) e chamar o `CriterionEvaluator` para verificar se alguma conquista foi desbloqueada.
7.  **Workers (Opcional):**
    *   `AchievementProgressWorker`: Para processar atualizações de progresso em lote ou de forma assíncrona.
    *   `RetroactiveAchievementWorker`: Para verificar e conceder conquistas retroativamente se novas definições forem adicionadas ou se houver uma correção de bug no rastreamento.

### 3.2. Estrutura de Diretórios (Proposta)

```
lib/deeper_hub/achievements/
├── achievements.ex                   # Fachada Pública
│
├── services/
│   └── achievements_service.ex       # Serviço principal
│
├── schemas/                          # (Ou schema/)
│   ├── achievement_definition_schema.ex
│   └── user_achievement_schema.ex
│
├── storage.ex                        # (Opcional) Módulo de queries Ecto
├── criterion_evaluator.ex            # Lógica para avaliar critérios de desbloqueio
├── event_listener.ex                 # Escuta eventos do sistema
│
├── workers/                          # Opcional
│   ├── achievement_progress_worker.ex
│   └── retroactive_achievement_worker.ex
│
├── cached_adapter.ex                 # (Opcional, para camada de cache dedicada)
├── supervisor.ex
└── telemetry.ex
```

### 3.3. Decisões de Design Importantes

*   **Definição de Critérios:** A forma como os critérios de desbloqueio são definidos e avaliados é a parte mais complexa.
    *   **Baseado em Eventos:** A maioria das conquistas será desbloqueada em resposta a eventos específicos do sistema.
    *   **Baseado em Estado:** Algumas podem exigir consultas ao estado atual do usuário ou de outras entidades.
    *   **DSL ou JSON para Critérios:** Armazenar os critérios em um formato flexível (como JSON ou uma DSL interna) na `AchievementDefinitionSchema` permite adicionar novas conquistas sem alterar o código do `CriterionEvaluator` extensivamente.
*   **Performance da Avaliação:** A avaliação de critérios não deve impactar significativamente a performance da ação que a desencadeou. Processamento assíncrono para avaliações complexas pode ser necessário.
*   **Retroatividade:** Considerar como lidar com conquistas adicionadas após o usuário já ter cumprido os critérios.

## 🛠️ 4. Casos de Uso Principais

*   **Administrador Cria uma Nova Conquista \"Explorador Mestre\":**
    *   Admin usa uma interface para definir a conquista: nome \"Explorador Mestre\", descrição \"Visite todas as 10 regiões secretas\", ícone, pontos. Critério: `%{type: \"counter_all\", events: [\"region.visited_secret\"], targets: [\"region1_id\", ..., \"region10_id\"]}`.
    *   API chama `Achievements.create_achievement_definition(attrs)`.
*   **Usuário Visita uma Região Secreta:**
    *   O módulo de jogo/mapa publica um evento: `Core.EventBus.publish(\"region.visited_secret\", %{user_id: \"u123\", region_id: \"region5_id\"})`.
    *   `Achievements.EventListener` recebe o evento.
    *   Atualiza o progresso do usuário para a conquista \"Explorador Mestre\".
    *   Chama `CriterionEvaluator` para verificar se todos os 10 alvos foram atingidos.
    *   Se sim, chama `Achievements.unlock_achievement_for_user(user_id, \"explorador_mestre_id\", %{source_event_id: ...})`.
*   **Usuário Visualiza suas Conquistas:**
    *   UI chama API que leva a `Achievements.list_user_unlocked_achievements(user_id)`.

## 🌊 5. Fluxos Importantes

### Fluxo de Desbloqueio de Conquista Baseada em Evento

1.  **Módulo de Domínio:** Uma ação ocorre (ex: usuário completa um desafio). O módulo publica um evento no `Core.EventBus` (ex: `challenge.completed`, payload: `%{user_id: \"u1\", challenge_id: \"c42\"}`).
2.  **`Achievements.EventListener`:**
    *   Está inscrito em eventos como `challenge.completed`.
    *   Recebe o evento.
3.  **`AchievementsService` (ou `CriterionEvaluator` diretamente chamado pelo Listener):**
    *   Para o `user_id` e o tipo de evento recebido (`challenge.completed` com `challenge_id: \"c42\"`):
        *   Busca todas as `AchievementDefinitionSchema`s cujos critérios podem ser afetados por este evento.
        *   Para cada definição de conquista candidata:
            *   Atualiza o progresso do usuário para aquela conquista (se for baseada em contador ou múltiplas etapas).
            *   Chama `CriterionEvaluator.evaluate(user_id, achievement_definition.criteria, current_progress)` para verificar se os critérios foram totalmente atendidos.
4.  **`CriterionEvaluator.evaluate/3`:**
    *   Interpreta a estrutura de `achievement_definition.criteria`.
    *   Pode precisar consultar dados adicionais do usuário ou seu progresso armazenado.
    *   Retorna `true` se os critérios foram atendidos, `false` caso contrário.
5.  **`AchievementsService` (continuação):**
    *   Se `CriterionEvaluator` retornar `true` e o usuário ainda não desbloqueou esta conquista:
        *   Cria um registro `UserAchievementSchema` associando `user_id` e `achievement_definition_id`.
        *   Publica um evento `achievement.unlocked` no `Core.EventBus` (com `user_id` e `achievement_id`).
        *   (Opcional) Enfileira uma notificação para o usuário via `DeeperHub.Notifications`.
        *   (Opcional) Concede pontos de recompensa ou outros benefícios.

## 📡 6. API (Funções Públicas da Fachada `DeeperHub.Achievements`)

### 6.1. Definições de Conquista (Admin)

*   **`DeeperHub.Achievements.create_achievement_definition(attrs :: map(), admin_user_id :: String.t()) :: {:ok, AchievementDefinition.t()} | {:error, Ecto.Changeset.t()}`**
    *   `attrs`: `%{name: String.t(), description: String.t(), icon_url: String.t(), criteria: map(), points: integer(), type: String.t(), ...}`.
*   **`DeeperHub.Achievements.update_achievement_definition(def_id :: String.t(), attrs :: map(), admin_user_id :: String.t()) :: {:ok, AchievementDefinition.t()} | {:error, Ecto.Changeset.t()}`**
*   **`DeeperHub.Achievements.delete_achievement_definition(def_id :: String.t(), admin_user_id :: String.t()) :: :ok | {:error, term()}`**
*   **`DeeperHub.Achievements.list_achievement_definitions(filters :: map(), opts :: keyword()) :: {:ok, list(AchievementDefinition.t()), Pagination.t()}`**
    *   `filters`: `:type`, `:is_active`.
    *   `opts`: `:page`, `:per_page`.

### 6.2. Interações do Usuário

*   **`DeeperHub.Achievements.list_user_unlocked_achievements(user_id :: String.t(), opts :: keyword()) :: {:ok, list(UserAchievementView.t()), Pagination.t()}`**
    *   `UserAchievementView.t()`: Um mapa/struct combinando dados da definição e a data de desbloqueio.
    *   `opts`: `:page`, `:per_page`, `:sort_by` (`:unlocked_at`, `:name`).
*   **`DeeperHub.Achievements.get_user_achievement_status(user_id :: String.t(), achievement_definition_id :: String.t()) :: {:ok, %{status: :locked | :in_progress | :unlocked, progress: map() | nil, unlocked_at: DateTime.t() | nil}}`**
    *   Retorna o status e o progresso atual (se aplicável) de um usuário para uma conquista.
*   **`DeeperHub.Achievements.get_achievement_details_for_user(user_id :: String.t() | nil, achievement_definition_id :: String.t()) :: {:ok, AchievementDetailsView.t()}` (Nova Sugestão)**
    *   `AchievementDetailsView.t()`: Detalhes da definição da conquista, mais o status/progresso específico do usuário (se `user_id` fornecido).

### 6.3. Processamento de Eventos (Chamado Internamente pelo `EventListener`)

*   **`DeeperHub.Achievements.process_system_event(user_id :: String.t(), event_name :: atom() | String.t(), event_payload :: map()) :: :ok`**
    *   Aciona a avaliação de critérios para o usuário com base no evento.

### 6.4. `DeeperHub.Achievements.unlock_achievement_for_user(user_id :: String.t(), achievement_definition_id :: String.t(), context :: map()) :: {:ok, UserAchievement.t()} | {:error, :already_unlocked | term()}`

*   **Descrição:** Força o desbloqueio de uma conquista para um usuário. Usado pelo `CriterionEvaluator` ou por lógicas de concessão direta.
*   **`context`:** `%{source: :event | :manual_grant, granted_by_admin_id: String.t() | nil}`.

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager`:

*   **`[:achievements, :enabled]`** (Boolean): Habilita/desabilita o sistema de conquistas. (Padrão: `true`)
*   **`[:achievements, :default_points_for_unlock]`** (Integer): Pontos padrão se não especificado na definição. (Padrão: `10`)
*   **`[:achievements, :notify_on_unlock]`** (Boolean): Se deve enviar uma notificação ao usuário quando uma conquista é desbloqueada. (Padrão: `true`)
*   **`[:achievements, :criteria_evaluator, :max_depth]`** (Integer): Limite de profundidade para avaliação de critérios complexos.
*   **`[:achievements, :cache, :definition_ttl_seconds]`** (Integer).
*   **`[:achievements, :cache, :user_unlocked_list_ttl_seconds]`** (Integer).
*   **`[:achievements, :retroactive_worker, :enabled]`** (Boolean).
*   **`[:achievements, :retroactive_worker, :batch_size]`** (Integer).

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.*`: Todos os módulos Core.
*   `DeeperHub.Accounts`: Para `user_id`.
*   `DeeperHub.Notifications`: Para notificar desbloqueios.
*   `DeeperHub.Audit`: Para auditar o gerenciamento de definições.

### 8.2. Bibliotecas Externas

*   `Ecto`.
*   Possivelmente uma biblioteca para parsing/avaliação de uma DSL de critérios, se for complexa.

## 🤝 9. Como Usar / Integração

*   **Administradores:** Usam uma interface (Web ou Console) que chama as funções `*_achievement_definition/*` para gerenciar as conquistas disponíveis.
*   **Módulos de Domínio:** Publicam eventos no `Core.EventBus` quando ações relevantes para conquistas ocorrem. Eles não precisam conhecer diretamente o módulo `Achievements` para o rastreamento de progresso.
    ```elixir
    # Em DeeperHub.Servers.Service
    def user_joins_server(user_id, server_id) do
      # ... lógica ...
      Core.EventBus.publish(\"server.user_joined\", %{user_id: user_id, server_id: server_id})
    end
    ```
*   **`Achievements.EventListener`:**
    ```elixir
    # Em Achievements.EventListener
    def handle_event(\"server.user_joined\", payload, _metadata) do
      Achievements.process_system_event(payload.user_id, \"server.user_joined\", payload)
    end
    ```
*   **Frontend/API:** Para exibir conquistas, chama os endpoints que usam `list_user_unlocked_achievements/1` ou `get_achievement_details_for_user/2`.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar CRUD para `AchievementDefinitionSchema`.
*   Testar a lógica do `CriterionEvaluator` com diferentes tipos de critérios e cenários de dados de usuário/evento.
*   Testar o desbloqueio de conquistas e a criação correta de `UserAchievementSchema`.
*   Testar que um usuário não pode desbloquear a mesma conquista (não repetível) duas vezes.
*   Testar o `EventListener` com eventos mockados.
*   Testar a lógica de atualização de progresso.
*   Localização: `test/deeper_hub/achievements/`.

### 10.2. Métricas

*   `deeper_hub.achievements.unlocked.count` (tags: `achievement_id`, `user_segment`)
*   `deeper_hub.achievements.definitions.total.gauge`
*   `deeper_hub.achievements.criteria_evaluation.duration_ms` (Histograma, tags: `achievement_id`)
*   `deeper_hub.achievements.event_listener.events_processed.count` (tags: `source_event_type`)
*   `deeper_hub.achievements.progress_updates.count` (tags: `achievement_id`)

### 10.3. Logs

*   **Nível INFO:** Conquista desbloqueada por usuário. Nova definição de conquista criada/atualizada.
*   **Nível DEBUG:** Evento recebido pelo `EventListener`. Avaliação de critério em andamento com detalhes.
*   **Nível WARNING:** Critério de conquista malformado ou impossível de avaliar.
*   **Nível ERROR:** Falha ao persistir desbloqueio de conquista.

### 10.4. Telemetria

*   `[:deeper_hub, :achievements, :definition, :created | :updated | :deleted]`
    *   Metadados: `%{definition_id: id, admin_id: id}`
*   `[:deeper_hub, :achievements, :user_achievement, :unlocked]`
    *   Metadados: `%{user_id: id, achievement_id: id, source: :event | :manual | :retroactive}`
*   `[:deeper_hub, :achievements, :criteria_evaluation, :evaluated]`
    *   Metadados: `%{user_id: id, achievement_id: id, criteria_met: boolean, details: ...}`

## ❌ 11. Tratamento de Erros

*   Falhas na avaliação de um critério não devem impedir o processamento de outros critérios ou eventos.
*   Se o `EventListener` falhar ao processar um evento, o evento pode ser reenfileirado (se o EventBus suportar) ou logado para investigação.
*   Erros ao persistir `UserAchievement` devem ser tratados (ex: retry, log).

## 🛡️ 12. Considerações de Segurança

*   **Critérios de Desbloqueio:** Garantir que os critérios não possam ser facilmente manipulados ou explorados pelos usuários para desbloquear conquistas indevidamente.
*   **Autorização de Gerenciamento:** Apenas administradores devem poder criar/modificar definições de conquistas.
*   **Dados de Progresso:** Se o progresso for armazenado, garantir sua integridade.

## 🧑‍💻 13. Contribuição

*   Ao definir novas conquistas, pense cuidadosamente nos critérios e como eles serão acionados por eventos do sistema.
*   Documente os critérios de cada conquista de forma clara.
*   Certifique-se de que o `EventListener` esteja inscrito nos eventos corretos para cada conquista.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar uma interface de UI para administradores gerenciarem as definições de conquistas.
*   [ ] Adicionar \"conquistas secretas\" que não são visíveis até serem desbloqueadas.
*   [ ] Permitir conquistas com múltiplos níveis (Bronze, Prata, Ouro).
*   [ ] Suporte para conquistas baseadas em tempo (ex: \"fazer login durante o evento de aniversário\").
*   [ ] Adicionar um feed de atividades para conquistas desbloqueadas (visível para amigos ou globalmente).
*   [ ] Permitir que usuários \"fixem\" suas conquistas favoritas em seus perfis.
*   [ ] Sistema de \"quase lá\" para mostrar aos usuários o quão perto estão de desbloquear certas conquistas.

---

*Última atualização: 2025-05-12*

---

Este README para `DeeperHub.Achievements` deve dar uma boa ideia de como documentar os módulos de domínio.

Qual módulo gostaria de abordar em seguida? Podemos pegar outro \"ex-Serviço\" como `DeeperHub.Challenges` ou `DeeperHub.Rewards`, ou algo diferente?"""),
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
                types.Part.from_text(text="""Ótimo! Vamos continuar com `DeeperHub.Challenges`, que complementa bem o `DeeperHub.Achievements` no contexto de engajamento e gamificação.

---

