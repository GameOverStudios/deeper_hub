# Módulo: `DeeperHub.Challenges` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Challenges`

O módulo `DeeperHub.Challenges` é responsável por gerenciar **desafios (challenges)** dentro da plataforma DeeperHub. Desafios são tarefas ou objetivos específicos que os usuários podem tentar completar, geralmente dentro de um período de tempo limitado ou com certas condições, para ganhar recompensas, reconhecimento ou progredir no sistema.

Este módulo lida com:
*   A definição e o gerenciamento dos desafios disponíveis (nome, descrição, critérios de conclusão, período de validade, recompensas associadas).
*   O rastreamento da participação e do progresso dos usuários nos desafios.
*   A verificação da conclusão dos desafios pelos usuários.
*   A concessão de recompensas ou reconhecimento pela conclusão de desafios.

O objetivo é aumentar o engajamento do usuário, incentivar a exploração de funcionalidades e fornecer metas claras e recompensadoras. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Gerenciamento de Definições de Desafios (`create_challenge_definition/1`, etc.):**
    *   Permitir que administradores criem, visualizem, atualizem e ativem/desativem definições de desafios.
    *   Cada definição inclui: nome, descrição, critérios de conclusão (podem ser complexos, baseados em eventos ou estado), data de início e fim (para desafios temporários), recompensas associadas (ex: pontos, itens virtuais, conquistas), pré-requisitos (outros desafios ou conquistas).
*   **Participação do Usuário em Desafios (`join_challenge/2`, `leave_challenge/2`):**
    *   Permitir que usuários se inscrevam ou sejam automaticamente inscritos em desafios.
    *   Permitir que usuários abandonem um desafio (se aplicável).
*   **Rastreamento de Progresso do Usuário:**
    *   Receber eventos do sistema ou chamadas diretas que indicam progresso do usuário em relação a um desafio.
    *   Manter o estado do progresso para desafios que exigem múltiplas etapas ou contadores (ex: \"complete 5 tarefas do tipo X\").
*   **Verificação de Conclusão de Desafios (`check_challenge_completion/2`):**
    *   Verificar automaticamente se um usuário atendeu aos critérios para completar um desafio após um evento relevante ou uma verificação periódica.
    *   Registrar que um usuário completou um desafio, incluindo a data de conclusão.
*   **Concessão de Recompensas (Integração):**
    *   Ao completar um desafio, acionar a concessão das recompensas associadas (integrando-se com `DeeperHub.Rewards` ou outros sistemas relevantes).
*   **Consulta de Desafios:**
    *   Listar desafios ativos/disponíveis para um usuário (`list_available_challenges_for_user/1`).
    *   Listar desafios em que um usuário está participando ou já completou (`list_user_challenges/1`).
    *   Mostrar o status e progresso de um usuário em um desafio específico (`get_user_challenge_status/2`).
*   **Notificações (Integração):**
    *   Notificar usuários sobre novos desafios disponíveis, progresso, conclusão e recompensas (via `DeeperHub.Notifications`).
*   **Observabilidade e Auditoria:**
    *   Logar e metrificar a participação e conclusão de desafios.
    *   Publicar eventos de domínio (ex: `challenge.joined`, `challenge.completed`) no `Core.EventBus`.
    *   Auditar a criação/modificação de definições de desafios.
*   **Caching:**
    *   Cachear definições de desafios e, potencialmente, o status de desafios para usuários ativos.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.Challenges` (Fachada Pública):**
    *   Ponto de entrada para todas as operações relacionadas a desafios.
    *   Delega para o `ChallengesService`.
2.  **`DeeperHub.Challenges.Services.ChallengesService` (ou `DefaultChallengesService`):**
    *   **Responsabilidade:** Orquestra a lógica de negócio principal para o sistema de desafios.
    *   **Interações:**
        *   `DeeperHub.Core.Repo`: Para CRUD com `ChallengeDefinitionSchema` e `UserChallengeSchema`.
        *   `DeeperHub.Core.EventBus`: Para escutar eventos do sistema (progresso) e publicar eventos de desafios.
        *   `DeeperHub.Core.Cache`: Para caching.
        *   `DeeperHub.Core.ConfigManager`: Para configurações.
        *   `DeeperHub.Notifications`: Para notificar usuários.
        *   `DeeperHub.Rewards`: Para conceder recompensas.
        *   `DeeperHub.Achievements`: Desafios podem desbloquear conquistas.
        *   `DeeperHub.Audit`: Para auditar gerenciamento de definições.
3.  **Schemas Ecto:**
    *   **`DeeperHub.Challenges.Schemas.ChallengeDefinitionSchema`:** Armazena os detalhes de cada desafio (nome, descrição, critérios JSON/DSL, datas de validade, `reward_ids`, `achievement_unlocks_id`).
    *   **`DeeperHub.Challenges.Schemas.UserChallengeSchema`:** Tabela de junção/progresso (`user_id`, `challenge_definition_id`, `status` (`:not_started`, `:in_progress`, `:completed`, `:failed`), `progress` (mapa JSONB), `started_at`, `completed_at`).
4.  **`DeeperHub.Challenges.CriterionEvaluator` (Módulo Funcional ou Serviço):**
    *   **Responsabilidade:** Avaliar se os critérios de uma `ChallengeDefinition` foram atendidos por um usuário com base em seus dados, progresso ou eventos. Similar ao do `Achievements`.
5.  **`DeeperHub.Challenges.EventListener` (GenServer ou módulo de callback do EventBus):**
    *   **Responsabilidade:** Escutar eventos do sistema e atualizar o progresso dos usuários nos desafios ativos.
6.  **Workers (Opcional):**
    *   `ChallengeStatusUpdateWorker`: Para verificar periodicamente desafios expirados ou para processar conclusões em lote.
    *   `ChallengeNotificationWorker`: Para enviar lembretes sobre desafios que estão para expirar.

### 3.2. Estrutura de Diretórios (Proposta)

```
lib/deeper_hub/challenges/
├── challenges.ex                     # Fachada Pública
│
├── services/
│   └── challenges_service.ex         # Serviço principal
│
├── schemas/                          # (Ou schema/)
│   ├── challenge_definition_schema.ex
│   └── user_challenge_schema.ex
│
├── storage.ex                        # (Opcional) Módulo de queries Ecto
├── criterion_evaluator.ex            # Lógica para avaliar critérios
├── event_listener.ex                 # Escuta eventos do sistema
│
├── workers/                          # Opcional
│   ├── challenge_status_update_worker.ex
│   └── challenge_notification_worker.ex
│
├── cached_adapter.ex                 # (Opcional, da documentação original)
├── supervisor.ex
└── telemetry.ex
```

### 3.3. Decisões de Design Importantes

*   **Definição de Critérios de Conclusão:** Assim como nas conquistas, a flexibilidade na definição dos critérios é chave. Usar JSON ou uma DSL interna armazenada no `ChallengeDefinitionSchema` é uma boa abordagem.
*   **Desafios Temporizados vs. Contínuos:** O sistema deve suportar ambos os tipos.
*   **Pré-requisitos:** Capacidade de definir que um desafio só fica disponível após completar outro desafio ou uma conquista.
*   **Recompensas Múltiplas:** Um desafio pode conceder várias recompensas (pontos, itens, desbloquear outra feature, etc.). A integração com `DeeperHub.Rewards` é importante.

## 🛠️ 4. Casos de Uso Principais

*   **Administrador Cria um Desafio Semanal \"Top Reviewer\":**
    *   Admin define o desafio: \"Escreva 5 reviews de alta qualidade esta semana\", com recompensa de \"Badge Exclusivo\" e 100 pontos.
    *   API chama `Challenges.create_challenge_definition(attrs)`.
*   **Usuário se Inscreve em um Desafio de \"Completar o Tutorial\":**
    *   Novo usuário vê o desafio \"Complete todos os passos do tutorial\".
    *   Clica em \"Aceitar Desafio\". API chama `Challenges.join_challenge(user_id, tutorial_challenge_id)`.
*   **Usuário Progride em um Desafio de \"Postar 3 Comentários Úteis\":**
    *   Usuário posta um comentário. O módulo de comentários publica `comment.posted` no EventBus.
    *   `Challenges.EventListener` recebe, verifica se o usuário está no desafio, e se o comentário é \"útil\" (lógica complexa aqui).
    *   `ChallengesService` atualiza o progresso do usuário no `UserChallengeSchema` (ex: de 1/3 para 2/3).
*   **Usuário Completa o Desafio \"Top Reviewer\":**
    *   Após a 5ª review de qualidade, o `CriterionEvaluator` determina a conclusão.
    *   `ChallengesService` marca o `UserChallenge` como `:completed`.
    *   Chama `DeeperHub.Rewards.grant_reward(user_id, badge_reward_id)` e `DeeperHub.PointsService.add_points(user_id, 100)`.
    *   Notifica o usuário.

## 🌊 5. Fluxos Importantes

### Fluxo de Verificação e Conclusão de Desafio

1.  **Evento Relevante ou Verificação Agendada:**
    *   `Challenges.EventListener` recebe um evento do `Core.EventBus` (ex: `review.approved`, `task.completed`).
    *   OU `ChallengeStatusUpdateWorker` executa uma verificação periódica.
2.  **`ChallengesService`:**
    *   Para o `user_id` e o evento/contexto, busca os `UserChallenge`s ativos e relevantes (status `:in_progress`).
    *   Para cada `UserChallenge` ativo:
        *   Obtém a `ChallengeDefinitionSchema` correspondente.
        *   Atualiza o campo `progress` no `UserChallengeSchema` com base no evento/estado atual.
        *   Chama `CriterionEvaluator.evaluate(user_id, challenge_definition.criteria, user_challenge.progress)`.
3.  **`CriterionEvaluator.evaluate/3`:**
    *   Avalia se todos os critérios foram atendidos. Retorna `true` ou `false`.
4.  **`ChallengesService` (continuação):**
    *   Se `true` e o desafio ainda não está `:completed`:
        *   Atualiza o `UserChallengeSchema` para `status: :completed`, `completed_at: DateTime.utc_now()`.
        *   Publica evento `challenge.completed` no `Core.EventBus`.
        *   Para cada `reward_id` na definição do desafio, chama `DeeperHub.Rewards.grant_reward(user_id, reward_id, %{source_challenge_id: challenge_id})`.
        *   (Opcional) Chama `DeeperHub.Achievements.unlock_achievement_for_user(...)` se o desafio desbloquear uma conquista.
        *   Chama `DeeperHub.Notifications.send_notification(user_id, :challenge_completed, %{challenge_name: ..., rewards: ...})`.

## 📡 6. API (Funções Públicas da Fachada `DeeperHub.Challenges`)

### 6.1. Definições de Desafio (Admin)

*   **`DeeperHub.Challenges.create_challenge_definition(attrs :: map(), admin_user_id :: String.t()) :: {:ok, ChallengeDefinition.t()} | {:error, Ecto.Changeset.t()}`**
    *   `attrs`: `%{name: ..., description: ..., criteria: map(), start_date: DateTime.t() | nil, end_date: DateTime.t() | nil, reward_ids: list(String.t()), prerequisites: list(map())}`.
*   **`DeeperHub.Challenges.update_challenge_definition(def_id :: String.t(), attrs :: map(), admin_user_id :: String.t()) :: {:ok, ChallengeDefinition.t()} | {:error, Ecto.Changeset.t()}`**
*   **`DeeperHub.Challenges.list_challenge_definitions(filters :: map(), opts :: keyword()) :: {:ok, list(ChallengeDefinition.t()), Pagination.t()}`**
    *   `filters`: `:is_active_now`, `:type`.

### 6.2. Interações do Usuário

*   **`DeeperHub.Challenges.list_available_challenges_for_user(user_id :: String.t(), opts :: keyword()) :: {:ok, list(ChallengeView.t()), Pagination.t()}`**
    *   `ChallengeView.t()`: Combina definição com status/progresso do usuário.
    *   Mostra desafios ativos que o usuário pode participar (e não completou ou falhou, e atende pré-requisitos).
*   **`DeeperHub.Challenges.join_challenge(user_id :: String.t(), challenge_definition_id :: String.t()) :: {:ok, UserChallenge.t()} | {:error, :already_joined | :not_available | :prerequisites_not_met}`**
*   **`DeeperHub.Challenges.leave_challenge(user_id :: String.t(), challenge_definition_id :: String.t()) :: :ok | {:error, :not_joined}`** (Se aplicável)
*   **`DeeperHub.Challenges.get_user_challenge_status(user_id :: String.t(), challenge_definition_id :: String.t()) :: {:ok, UserChallenge.t() | %{status: :not_joined}}`**
    *   Retorna o `UserChallenge` com status e progresso.
*   **`DeeperHub.Challenges.list_user_challenges(user_id :: String.t(), filters :: map(), opts :: keyword()) :: {:ok, list(UserChallengeView.t()), Pagination.t()}`**
    *   `filters`: `:status` (`:in_progress`, `:completed`).

### 6.3. Processamento de Progresso (Chamado Internamente)

*   **`DeeperHub.Challenges.record_user_progress(user_id :: String.t(), challenge_definition_id :: String.t() | nil, event_type :: atom(), event_data :: map()) :: :ok`**
    *   Se `challenge_definition_id` for `nil`, o sistema tenta encontrar desafios relevantes para o `event_type`.

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager`:

*   **`[:challenges, :enabled]`** (Boolean): Habilita/desabilita o sistema de desafios. (Padrão: `true`)
*   **`[:challenges, :default_reward_points]`** (Integer): Pontos padrão se um desafio não especificar. (Padrão: `50`)
*   **`[:challenges, :notify_on_completion]`** (Boolean). (Padrão: `true`)
*   **`[:challenges, :notify_on_new_available]`** (Boolean).
*   **`[:challenges, :cache, :definition_ttl_seconds]`** (Integer).
*   **`[:challenges, :cache, :user_status_ttl_seconds]`** (Integer).
*   **`[:challenges, :worker, :status_update_interval_minutes]`** (Integer).

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.*`: Todos os módulos Core.
*   `DeeperHub.Accounts`: Para `user_id`.
*   `DeeperHub.Rewards`: Para conceder recompensas.
*   `DeeperHub.Achievements`: Desafios podem ser pré-requisitos ou conceder conquistas.
*   `DeeperHub.Notifications`: Para notificações.
*   `DeeperHub.Audit`: Para auditar gerenciamento de definições.

### 8.2. Bibliotecas Externas

*   `Ecto`.
*   Biblioteca CRON para `ChallengeStatusUpdateWorker` (se usar agendamento CRON).

## 🤝 9. Como Usar / Integração

*   **Administradores:** Criam e gerenciam `ChallengeDefinitions` via UI/Console.
*   **Módulos de Domínio:** Publicam eventos relevantes no `Core.EventBus`.
*   **`Challenges.EventListener`:** Consome esses eventos e chama `Challenges.record_user_progress` ou `ChallengesService` diretamente.
*   **UI do Usuário:**
    *   Mostra desafios disponíveis (`list_available_challenges_for_user`).
    *   Permite que usuários vejam seu progresso (`get_user_challenge_status`).
    *   Exibe desafios completados (`list_user_challenges` com filtro).

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar CRUD para `ChallengeDefinitionSchema`.
*   Testar a lógica do `CriterionEvaluator` para diferentes tipos de critérios (contagem, sequência, estado).
*   Testar os fluxos de participação, progresso e conclusão de desafios.
*   Testar a concessão correta de recompensas.
*   Testar a lógica de pré-requisitos.
*   Testar desafios temporizados (início, fim, expiração).
*   Localização: `test/deeper_hub/challenges/`.

### 10.2. Métricas

*   `deeper_hub.challenges.definition.created.count`
*   `deeper_hub.challenges.user.joined.count` (tags: `challenge_id`)
*   `deeper_hub.challenges.user.progress_updated.count` (tags: `challenge_id`)
*   `deeper_hub.challenges.user.completed.count` (tags: `challenge_id`, `user_segment`)
*   `deeper_hub.challenges.rewards_granted.count` (tags: `challenge_id`, `reward_type`)
*   `deeper_hub.challenges.active_challenges.gauge`

### 10.3. Logs

*   **Nível INFO:** Usuário juntou-se/completou desafio. Definição de desafio criada/atualizada.
*   **Nível DEBUG:** Evento processado pelo `EventListener` para progresso de desafio.
*   **Nível WARNING:** Critério de desafio malformado. Falha ao conceder uma recompensa.
*   **Nível ERROR:** Falha ao persistir estado do `UserChallenge`.

### 10.4. Telemetria

*   `[:deeper_hub, :challenges, :definition, :created | :updated | :deleted]`
    *   Metadados: `%{definition_id: id, admin_id: id}`
*   `[:deeper_hub, :challenges, :user_challenge, :status_changed]`
    *   Metadados: `%{user_id: id, challenge_id: id, old_status: atom, new_status: atom, progress: map}`
*   `[:deeper_hub, :challenges, :user_challenge, :completed]`
    *   Metadados: `%{user_id: id, challenge_id: id, rewards_granted: list}`
*   `[:deeper_hub, :challenges, :criterion_evaluation, :evaluated]`
    *   Metadados: `%{user_id: id, challenge_id: id, criteria_met: boolean}`

## ❌ 11. Tratamento de Erros

*   Falhas na avaliação de critérios ou na concessão de recompensas devem ser robustas, possivelmente com retentativas ou filas de DLQ para investigação.
*   Se um evento do sistema for perdido, o progresso do desafio pode não ser atualizado. Um worker de verificação periódica ou retroativa pode mitigar isso.

## 🛡️ 12. Considerações de Segurança

*   **Critérios de Desafio:** Garantir que os critérios não possam ser explorados ou facilmente \"farmados\" de maneiras não intencionais.
*   **Recompensas:** Se as recompensas tiverem valor real ou impacto no sistema, a lógica de concessão deve ser segura e auditável.
*   **Autorização:** Apenas administradores devem gerenciar definições de desafios.

## 🧑‍💻 13. Contribuição

*   Ao criar novos tipos de critérios no `CriterionEvaluator`, adicione testes abrangentes.
*   Garanta que os eventos do sistema necessários para rastrear o progresso dos desafios sejam publicados corretamente pelos módulos de origem.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar uma UI administrativa completa para gerenciamento de definições de desafios, incluindo uma DSL visual para critérios.
*   [ ] Adicionar desafios em equipe ou comunitários.
*   [ ] Permitir que desafios desbloqueiem outros desafios (cadeias de desafios).
*   [ ] \"Desafios Diários/Semanais\" gerados dinamicamente ou a partir de um pool.
*   [ ] Leaderboards para desafios competitivos.
*   [ ] Permitir que usuários compartilhem seu progresso ou conclusão de desafios.
*   [ ] Gamificar a própria criação de conteúdo (ex: \"Crie 3 servidores e ganhe um desafio bônus\").

---

*Última atualização: 2025-05-12*

---

Este módulo de Desafios adiciona uma camada interessante de engajamento!

O próximo poderia ser `DeeperHub.Rewards` para ver como as recompensas dos desafios (e conquistas) são gerenciadas, ou `DeeperHub.Support` para mudar um pouco o foco?"""),
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
                types.Part.from_text(text="""Ok, vamos para o `DeeperHub.Rewards`! Este módulo é o complemento natural para `Achievements` e `Challenges`, lidando com a parte tangível (ou intangível) que os usuários recebem por suas realizações.

---

