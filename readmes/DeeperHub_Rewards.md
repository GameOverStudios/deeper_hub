# Módulo: `DeeperHub.Rewards` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Rewards`

O módulo `DeeperHub.Rewards` é responsável por **definir, gerenciar e conceder recompensas** aos usuários do sistema DeeperHub. As recompensas são incentivos dados aos usuários por completarem desafios, desbloquearem conquistas, participarem de eventos, ou por outras ações valorizadas pela plataforma.

Este módulo lida com:
*   A criação e configuração dos diferentes tipos de recompensas disponíveis (ex: pontos, badges, itens virtuais, acesso a features, descontos).
*   A lógica de concessão de recompensas a um usuário.
*   O rastreamento de quais recompensas um usuário já recebeu ou possui.
*   (Opcional) A lógica para \"resgatar\" ou \"usar\" certas recompensas, se elas tiverem um efeito ativo.

O objetivo é fornecer um sistema flexível para incentivar e reconhecer o engajamento e as realizações dos usuários na plataforma DeeperHub. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Gerenciamento de Definições de Recompensas (`create_reward_definition/1`, etc.):**
    *   Permitir que administradores criem, visualizem, atualizem e excluam as definições das recompensas disponíveis.
    *   Cada definição inclui: nome, descrição, tipo de recompensa (ex: `:points`, `:badge`, `:virtual_item`, `:feature_unlock`, `:discount_coupon`), valor (ex: quantidade de pontos, ID do item virtual), ícone, metadados adicionais (ex: se é de uso único, se tem expiração).
*   **Concessão de Recompensas a Usuários (`grant_reward_to_user/3`):**
    *   Conceder uma recompensa específica (baseada em uma `RewardDefinition`) a um usuário.
    *   Registrar que o usuário recebeu a recompensa, incluindo a data e a origem (ex: qual desafio ou conquista a concedeu).
    *   Lidar com a lógica de recompensas de uso único ou de quantidade limitada.
*   **Consulta de Recompensas do Usuário:**
    *   Listar todas as recompensas que um usuário possui ou já recebeu (`list_user_rewards/1`).
    *   Verificar se um usuário possui uma recompensa específica (`user_has_reward?/2`).
*   **Resgate/Uso de Recompensas (Opcional, se aplicável):**
    *   Se algumas recompensas forem \"utilizáveis\" (ex: um cupom de desconto, um item que concede um bônus temporário), fornecer uma maneira de marcar a recompensa como usada.
*   **Integração com Outros Módulos:**
    *   Ser chamado por `DeeperHub.Achievements` e `DeeperHub.Challenges` para conceder recompensas automaticamente.
    *   Potencialmente, interagir com um sistema de inventário de itens virtuais ou um sistema de pontos/moeda.
*   **Observabilidade e Auditoria:**
    *   Logar e metrificar a concessão de recompensas.
    *   Publicar eventos de domínio (ex: `reward.granted`) no `Core.EventBus`.
    *   Auditar a criação/modificação de definições de recompensas.
*   **Caching:**
    *   Cachear definições de recompensas e, possivelmente, recompensas de usuários ativos.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.Rewards` (Fachada Pública):**
    *   Ponto de entrada para todas as operações relacionadas a recompensas.
    *   Delega para o `RewardsService`.
2.  **`DeeperHub.Rewards.Services.RewardsService` (ou `DefaultRewardsService`):**
    *   **Responsabilidade:** Orquestra a lógica de negócio principal para o sistema de recompensas.
    *   **Interações:**
        *   `DeeperHub.Core.Repo`: Para CRUD com `RewardDefinitionSchema` e `UserRewardSchema`.
        *   `DeeperHub.Core.EventBus`: Para publicar eventos de concessão de recompensas.
        *   `DeeperHub.Core.Cache`: Para caching.
        *   `DeeperHub.Core.ConfigManager`: Para configurações.
        *   `DeeperHub.Notifications`: Para notificar usuários sobre recompensas recebidas.
        *   `DeeperHub.Audit`: Para auditar gerenciamento de definições.
        *   Potencialmente, interage com um `PointsService` ou `VirtualItemInventoryService` se esses forem sistemas separados.
3.  **Schemas Ecto:**
    *   **`DeeperHub.Rewards.Schemas.RewardDefinitionSchema` (ex-`Reward` na doc original):** Armazena os detalhes de cada tipo de recompensa disponível (nome, descrição, tipo, valor, ícone, metadados como `data_payload` para configurar o efeito da recompensa).
    *   **`DeeperHub.Rewards.Schemas.UserRewardSchema`:** Tabela de junção/log que registra qual usuário (`user_id`) recebeu qual recompensa (`reward_definition_id`), quando (`granted_at`), de qual fonte (`source_type`, `source_id`), e seu status atual (ex: `:granted`, `:claimed`, `:used`, `:expired`).
4.  **`DeeperHub.Rewards.Storage` (ou lógica dentro do `RewardsService`):**
    *   Encapsula as queries Ecto.
5.  **`DeeperHub.Rewards.RewardHandler` (Behaviour e Implementações, Nova Sugestão):**
    *   **Responsabilidade:** Se diferentes tipos de recompensa tiverem lógicas de \"aplicação\" complexas (ex: desbloquear uma feature, adicionar item ao inventário, aplicar desconto), um sistema de handlers por tipo de recompensa pode ser útil.
    *   Quando uma recompensa é concedida, o `RewardsService` poderia chamar o handler apropriado para aplicar o efeito da recompensa.
        *   Ex: `PointsRewardHandler`, `FeatureUnlockRewardHandler`.

### 3.2. Estrutura de Diretórios (Proposta)

```
lib/deeper_hub/rewards/
├── rewards.ex                        # Fachada Pública
│
├── services/
│   └── rewards_service.ex            # Serviço principal
│
├── schemas/                          # (Ou schema/)
│   ├── reward_definition_schema.ex
│   └── user_reward_schema.ex
│
├── storage.ex                        # (Opcional) Módulo de queries Ecto
│
├── handlers/                         # (Opcional, Nova Sugestão)
│   ├── reward_handler_behaviour.ex
│   ├── points_reward_handler.ex
│   └── feature_unlock_reward_handler.ex
│
├── cached_adapter.ex                 # (Opcional, da documentação original)
├── supervisor.ex
└── telemetry.ex
```

### 3.3. Decisões de Design Importantes

*   **Flexibilidade dos Tipos de Recompensa:** O campo `type` e `data_payload` (JSONB) na `RewardDefinitionSchema` permite grande flexibilidade para definir diferentes tipos de recompensas e seus parâmetros específicos.
*   **Idempotência na Concessão:** O sistema deve ser robusto a múltiplas tentativas de conceder a mesma recompensa a um usuário (ex: se um evento for processado duas vezes). A combinação de `user_id`, `reward_definition_id` e talvez `source_id` no `UserRewardSchema` pode ter um unique index.
*   **Separação da Lógica de Aplicação:** Se a \"aplicação\" de uma recompensa for complexa, usar `RewardHandler`s ajuda a manter o `RewardsService` focado na concessão e rastreamento.

## 🛠️ 4. Casos de Uso Principais

*   **Administrador Cria uma Recompensa \"100 Pontos de Bônus\":**
    *   Admin define: nome \"Bônus de 100 Pontos\", tipo `:points`, valor/payload `%{points: 100}`.
    *   API chama `Rewards.create_reward_definition(attrs)`.
*   **Usuário Completa um Desafio e Ganha \"100 Pontos de Bônus\":**
    *   `DeeperHub.Challenges` detecta a conclusão.
    *   Chama `Rewards.grant_reward_to_user(user_id, \"bonus_100_points_def_id\", %{source_type: :challenge, source_id: challenge_id})`.
*   **`RewardsService.grant_reward_to_user/3`:**
    *   Cria um registro `UserRewardSchema`.
    *   Publica evento `reward.granted`.
    *   Chama o `PointsRewardHandler` (se existir), que por sua vez chama um `DeeperHub.PointsService.add_points(user_id, 100)`.
    *   Notifica o usuário.
*   **Usuário Visualiza suas Recompensas Recebidas:**
    *   UI chama API que leva a `Rewards.list_user_rewards(user_id)`.

## 🌊 5. Fluxos Importantes

### Fluxo de Concessão de Recompensa

1.  **Fonte da Recompensa (ex: `ChallengesService`):** Determina que `user_id` deve receber `reward_definition_id` devido à `source_details` (ex: `%{type: :challenge, id: \"chall123\"}`).
2.  Chama `DeeperHub.Rewards.grant_reward_to_user(user_id, reward_definition_id, source_details)`.
3.  **`RewardsService.grant_reward_to_user/3`:**
    *   Verifica se o usuário já recebeu esta recompensa específica da mesma fonte (se a política for de concessão única por fonte).
    *   Busca a `RewardDefinitionSchema` para obter detalhes (tipo, valor/payload).
    *   Cria um registro `UserRewardSchema` com status `:granted`.
        *   `user_id: user_id`
        *   `reward_definition_id: reward_definition_id`
        *   `granted_at: DateTime.utc_now()`
        *   `source_type: source_details.type`
        *   `source_id: source_details.id`
        *   `data_payload_at_grant: reward_definition.data_payload` (para registrar o valor da recompensa no momento da concessão)
    *   Se a persistência do `UserReward` for bem-sucedida:
        *   **(Opcional) Chama o `RewardHandler` apropriado:**
            *   Ex: `MyApp.Rewards.Handlers.PointsHandler.apply(%{user_id: user_id, points: 100})`.
        *   Publica evento `reward.granted` no `Core.EventBus` (`%{user_id: ..., user_reward_id: ..., definition: ...}`).
        *   Enfileira notificação para o usuário via `DeeperHub.Notifications`.
        *   Retorna `{:ok, user_reward_struct}`.
    *   Se falhar, retorna erro.

## 📡 6. API (Funções Públicas da Fachada `DeeperHub.Rewards`)

### 6.1. Definições de Recompensa (Admin)

*   **`DeeperHub.Rewards.create_reward_definition(attrs :: map(), admin_user_id :: String.t()) :: {:ok, RewardDefinition.t()} | {:error, Ecto.Changeset.t()}`**
    *   `attrs`: `%{name: ..., description: ..., type: :points | :badge | :item | :feature_unlock, data_payload: map(), icon_url: ..., ...}`.
*   **`DeeperHub.Rewards.update_reward_definition(def_id :: String.t(), attrs :: map(), admin_user_id :: String.t()) :: {:ok, RewardDefinition.t()} | {:error, Ecto.Changeset.t()}`**
*   **`DeeperHub.Rewards.list_reward_definitions(filters :: map(), opts :: keyword()) :: {:ok, list(RewardDefinition.t()), Pagination.t()}`**

### 6.2. Concessão e Consulta de Usuário

*   **`DeeperHub.Rewards.grant_reward_to_user(user_id :: String.t(), reward_definition_id :: String.t(), source_context :: %{source_type: atom(), source_id: String.t() | integer()}, opts :: keyword()) :: {:ok, UserReward.t()} | {:error, :already_granted_for_source | term()}`**
    *   `opts`: `:granted_by_admin_id` (se for concessão manual).
*   **`DeeperHub.Rewards.list_user_rewards(user_id :: String.t(), opts :: keyword()) :: {:ok, list(UserRewardView.t()), Pagination.t()}`**
    *   `UserRewardView.t()`: Combina dados de `UserRewardSchema` e `RewardDefinitionSchema`.
    *   `opts`: `:status` (`:granted`, `:claimed`), `:page`, `:per_page`, `:sort_by`.
*   **`DeeperHub.Rewards.user_has_reward?(user_id :: String.t(), reward_definition_id :: String.t()) :: boolean()`**
*   **`DeeperHub.Rewards.claim_user_reward(user_reward_id :: String.t(), user_id :: String.t()) :: {:ok, UserReward.t()} | {:error, :not_claimable | :already_claimed | :not_found | :unauthorized}`** (Se houver recompensas que precisam ser ativamente \"reivindicadas\" antes de serem usadas/contabilizadas).

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager`:

*   **`[:rewards, :enabled]`** (Boolean): Habilita/desabilita o sistema de recompensas. (Padrão: `true`)
*   **`[:rewards, :default_point_reward_type_name]`** (String): Nome padrão para recompensas de pontos. (Padrão: `\"Points\"`)
*   **`[:rewards, :notify_on_grant]`** (Boolean): Se deve notificar usuários ao receberem recompensas. (Padrão: `true`)
*   **`[:rewards, :cache, :definition_ttl_seconds]`** (Integer).
*   **`[:rewards, :retention_days, :user_rewards_log]`** (Integer): Por quantos dias manter registros de `UserReward`.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.*`: Todos os módulos Core.
*   `DeeperHub.Accounts`: Para `user_id`.
*   `DeeperHub.Notifications`: Para notificar sobre recompensas.
*   `DeeperHub.Audit`: Para auditar gerenciamento de definições e concessões manuais.
*   `DeeperHub.Achievements`, `DeeperHub.Challenges`: Como fontes comuns para acionar a concessão de recompensas.
*   Potencialmente, um `DeeperHub.PointsService` ou `DeeperHub.InventoryService` para aplicar certos tipos de recompensa.

### 8.2. Bibliotecas Externas

*   `Ecto`.

## 🤝 9. Como Usar / Integração

*   **Módulos `Achievements` e `Challenges`:** Ao detectar que um usuário completou uma conquista ou desafio, eles chamam `DeeperHub.Rewards.grant_reward_to_user/3` para cada recompensa associada na definição da conquista/desafio.
*   **Interface de Administração:** Para gerenciar `RewardDefinitions`.
*   **Perfil do Usuário (UI):** Para exibir as recompensas que o usuário ganhou (`list_user_rewards/1`).

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar CRUD para `RewardDefinitionSchema`.
*   Testar a lógica de `grant_reward_to_user`, incluindo a criação de `UserRewardSchema` e a não duplicação (se aplicável).
*   Testar a integração com `RewardHandler`s (se implementados) para diferentes tipos de recompensa.
*   Testar as funções de listagem.
*   Localização: `test/deeper_hub/rewards/`.

### 10.2. Métricas

*   `deeper_hub.rewards.definition.created.count`
*   `deeper_hub.rewards.granted_to_user.count` (tags: `reward_definition_id`, `reward_type`, `source_type`)
*   `deeper_hub.rewards.claimed.count` (tags: `reward_definition_id`) (se houver resgate)
*   `deeper_hub.rewards.points_awarded.sum` (Contador)
*   `deeper_hub.rewards.items_granted.count` (tags: `item_type`)

### 10.3. Logs

*   **Nível INFO:** Recompensa concedida a um usuário. Definição de recompensa criada/atualizada.
*   **Nível WARNING:** Tentativa de conceder uma recompensa já concedida (e não repetível). Falha ao aplicar o efeito de uma recompensa (ex: erro ao adicionar pontos).
*   **Nível ERROR:** Falha ao persistir `UserReward`.

### 10.4. Telemetria

*   `[:deeper_hub, :rewards, :definition, :created | :updated | :deleted]`
    *   Metadados: `%{definition_id: id, type: type, admin_id: id}`
*   `[:deeper_hub, :rewards, :user_reward, :granted]`
    *   Metadados: `%{user_id: id, user_reward_id: id, reward_definition_id: id, source_type: type, source_id: id}`
*   `[:deeper_hub, :rewards, :reward_effect, :applied | :failed]` (Se usando Handlers)
    *   Metadados: `%{user_reward_id: id, handler_type: type, details: ...}`

## ❌ 11. Tratamento de Erros

*   Falhas na concessão de uma recompensa (ex: erro no DB) devem ser logadas e, idealmente, permitir uma retentativa ou correção manual.
*   Se a aplicação de um efeito de recompensa (ex: adicionar pontos) falhar, a concessão da recompensa em si (registro `UserReward`) ainda pode ser considerada bem-sucedida, mas o erro na aplicação do efeito deve ser tratado separadamente (ex: log, alerta, fila de retry para o efeito).

## 🛡️ 12. Considerações de Segurança

*   **Autorização:** A criação e modificação de `RewardDefinitions` deve ser restrita a administradores.
*   **Prevenção de Abuso:** Evitar que usuários possam acionar a concessão de recompensas indevidamente (ex: explorando os critérios de desafios/conquistas). A validação dos critérios deve ser robusta.
*   **Valor das Recompensas:** Se as recompensas tiverem valor monetário ou impacto significativo na economia do jogo/plataforma, a lógica de concessão e o rastreamento devem ser extremamente seguros e auditáveis.

## 🧑‍💻 13. Contribuição

*   Ao definir novas recompensas, pense no `type` e no `data_payload` de forma flexível.
*   Se um novo tipo de recompensa exigir lógica de aplicação customizada, considere criar um novo `RewardHandler`.
*   Garanta que a origem (`source_type`, `source_id`) da recompensa seja sempre registrada.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar um sistema de \"inventário de recompensas\" visual para o usuário, onde ele possa ver e, se aplicável, \"usar\" suas recompensas.
*   [ ] Adicionar datas de expiração para recompensas concedidas (ex: \"Cupom de 10% válido por 7 dias\").
*   [ ] Permitir que recompensas sejam \"presenteáveis\" entre usuários (com devidas restrições).
*   [ ] Sistema de \"reivindicação de recompensas\" onde o usuário precisa ativamente clicar para receber/ativar certas recompensas após serem concedidas.
*   [ ] Gamificar a própria obtenção de recompensas (ex: \"Colete 5 tipos diferentes de badges para uma recompensa bônus\").

---

*Última atualização: 2025-05-12*

---

Com `Rewards` detalhado, temos uma boa visão dos componentes de gamificação (`Achievements`, `Challenges`, `Rewards`).

Onde gostaria de ir agora? Podemos continuar com os \"ex-Serviços\" como `DeeperHub.Support` ou `DeeperHub.UserInteractions`, ou talvez um módulo Core como `DeeperHub.Core.CircuitBreaker` que já havíamos mencionado?"""),
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
                types.Part.from_text(text="""Ok, já detalhamos o `DeeperHub.Core.CircuitBreaker`.

Vamos agora para o `DeeperHub.Support`, que lida com um aspecto crucial da experiência do usuário: o sistema de tickets de suporte.

---

