# Módulo: `Deeper_Hub.Rewards` 🎁

## 📜 1. Visão Geral do Módulo `Deeper_Hub.Rewards`

O módulo `Deeper_Hub.Rewards` é responsável por gerenciar o sistema de recompensas da plataforma Deeper_Hub. Ele permite a definição de diferentes tipos de recompensas, sua associação a ações específicas do usuário (como completar desafios, alcançar conquistas, ou participação em eventos), e o processo de concessão e resgate dessas recompensas pelos usuários. O objetivo é incentivar o engajamento, fidelizar usuários e reconhecer suas contribuições e marcos. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Definição de Recompensas:**
    *   CRUD para Recompensas (`Reward`): nome, descrição, tipo de recompensa (ex: pontos de experiência, itens virtuais, badges, descontos, acesso a features premium temporárias), valor ou detalhes específicos da recompensa.
    *   Configuração de disponibilidade (ex: recompensa única, recompensa diária/semanal, limitada por estoque).
    *   Associação de recompensas a gatilhos (ex: ID de uma conquista, ID de um desafio, evento específico).
*   **Concessão de Recompensas:**
    *   Mecanismo para conceder recompensas automaticamente quando um gatilho é ativado (ex: usuário completa um desafio `Deeper_Hub.Challenges`).
    *   Capacidade para administradores concederem recompensas manualmente a usuários (com auditoria).
*   **Resgate/Uso de Recompensas (se aplicável):**
    *   Para certos tipos de recompensas (ex: itens que podem ser \"usados\" ou descontos), gerenciar o processo de resgate.
    *   Manter um histórico de recompensas concedidas e resgatadas por usuário (`UserReward`).
*   **Inventário de Recompensas do Usuário:**
    *   Permitir que usuários visualizem as recompensas que receberam e seu status (ex: disponível, resgatada, expirada).
*   **Integração com Outros Módulos:**
    *   Receber solicitações de concessão de recompensas de `Deeper_Hub.Achievements`, `Deeper_Hub.Challenges`, etc.
    *   Potencialmente, interagir com um sistema de \"loja\" ou \"inventário virtual\" se as recompensas forem itens.
*   **Notificações:**
    *   Notificar usuários quando recebem uma nova recompensa (via `Deeper_Hub.Notifications`).
*   **Administração de Recompensas:**
    *   Interface para administradores criarem, editarem e gerenciarem o catálogo de recompensas.
    *   Monitorar a distribuição e o resgate de recompensas.

## 🏗️ 3. Arquitetura e Design

`Deeper_Hub.Rewards` funcionará como uma fachada para um serviço de lógica de negócio e componentes de persistência.

*   **Interface Pública (`Deeper_Hub.Rewards.RewardsFacade` ou `Deeper_Hub.Rewards`):** Funções como `list_available_rewards/1`, `grant_reward_to_user/3`, `get_user_rewards/1`.
*   **Serviço de Recompensas (`Deeper_Hub.Rewards.Services.RewardsService`):**
    *   Contém a lógica de negócio principal para definir, conceder e gerenciar recompensas.
*   **Schemas Ecto:**
    *   `Deeper_Hub.Rewards.Schema.Reward`: Define uma recompensa.
    *   `Deeper_Hub.Rewards.Schema.UserReward`: Rastreia as recompensas concedidas a um usuário, seu status e data de resgate/expiração.
*   **Cache (`Deeper_Hub.Rewards.Cache` ou via `Core.Cache`):**
    *   Cache para definições de recompensas frequentemente acessadas.
*   **Integrações:**
    *   `Deeper_Hub.Core.Repo`: Para persistência.
    *   `Deeper_Hub.Core.EventBus`: Para escutar eventos que podem conceder recompensas ou publicar eventos de recompensa concedida.
    *   `Deeper_Hub.Notifications`: Para notificar usuários.
    *   `Deeper_Hub.Achievements`, `Deeper_Hub.Challenges`: Para acionar a concessão de recompensas.

**Padrões de Design:**

*   **Fachada (Facade).**
*   **Serviço de Domínio.**
*   **Observer (via EventBus):** Para conceder recompensas em resposta a eventos de outros módulos.

### 3.1. Componentes Principais

*   **`Deeper_Hub.Rewards.RewardsFacade`:** Ponto de entrada.
*   **`Deeper_Hub.Rewards.Services.RewardsService`:** Lógica de negócio.
*   **`Deeper_Hub.Rewards.Schema.Reward`:** Schema da recompensa.
*   **`Deeper_Hub.Rewards.Schema.UserReward`:** Schema da recompensa do usuário.
*   **`Deeper_Hub.Rewards.EventHandler` (Novo Sugerido):** Para processar eventos que concedem recompensas.
*   **`Deeper_Hub.Rewards.Supervisor`:** Supervisiona processos.

### 3.3. Decisões de Design Importantes

*   **Tipos de Recompensa:** Definir uma forma flexível de representar diferentes tipos de recompensas e como elas são aplicadas/resgatadas.
*   **Lógica de Concessão:** Como as recompensas são acionadas – via chamadas diretas de outros serviços ou de forma reativa a eventos.
*   **Exclusividade e Limites:** Como lidar com recompensas que só podem ser obtidas uma vez, ou que têm um estoque limitado.

## 🛠️ 4. Casos de Uso Principais

*   **Usuário Completa Desafio:** O módulo `Deeper_Hub.Challenges` notifica o `Deeper_Hub.Rewards` (ou emite um evento) para conceder a recompensa associada ao desafio.
*   **Administrador Cria Nova Recompensa:** Um admin define uma nova recompensa \"100 Pontos de Bônus\" que pode ser concedida por várias atividades.
*   **Usuário Resgata Cupom de Desconto:** Um usuário que recebeu um cupom de desconto (recompensa) o utiliza em um sistema de e-commerce integrado.
*   **Usuário Visualiza suas Recompensas:** Um usuário acessa seu inventário para ver quais recompensas ele possui.

## 🌊 5. Fluxos Importantes (Opcional)

**Fluxo de Concessão de Recompensa ao Completar uma Conquista:**

1.  O módulo `Deeper_Hub.Achievements` detecta que um usuário desbloqueou uma conquista.
2.  `Achievements` emite um evento `AchievementUnlockedEvent(%{user_id: \"123\", achievement_id: \"ach_abc\"})` no `Core.EventBus`.
3.  `Deeper_Hub.Rewards.EventHandler` (inscrito neste evento) recebe o evento.
4.  O `EventHandler` consulta o `RewardsService` para verificar se a `achievement_id: \"ach_abc\"` tem uma recompensa associada.
5.  Se houver uma recompensa definida (ex: `Reward` com `trigger_type: :achievement`, `trigger_id: \"ach_abc\"`):
    *   `RewardsService` verifica se o usuário já recebeu esta recompensa (se for única).
    *   Se elegível, cria um registro `UserReward` para `user_id: \"123\"` e o ID da recompensa.
    *   Persiste o `UserReward`.
    *   Emite um evento `RewardGrantedEvent`.
    *   Enfileira uma notificação para o usuário via `Deeper_Hub.Notifications`.
6.  O `EventHandler` confirma o processamento do evento.

## 📡 6. API (Se Aplicável)

### 6.1. `Deeper_Hub.Rewards.grant_reward_to_user/3`

*   **Descrição:** Concede uma recompensa específica a um usuário.
*   **`@spec`:** `grant_reward_to_user(user_id :: String.t(), reward_id :: String.t(), opts :: Keyword.t()) :: {:ok, UserReward.t()} | {:error, reason}`
*   **Parâmetros:**
    *   `user_id` (String): O ID do usuário que receberá a recompensa.
    *   `reward_id` (String): O ID da recompensa a ser concedida.
    *   `opts` (Keyword.t()): Opções adicionais.
        *   `:granted_by` (String): ID do sistema/usuário que está concedendo a recompensa (para auditoria).
        *   `:reason` (String): Motivo da concessão (ex: \"completed_challenge_xyz\").
*   **Retorno:**
    *   `{:ok, user_reward_struct}`: Se a recompensa for concedida com sucesso.
    *   `{:error, :reward_not_found | :user_not_found | :already_granted | :not_eligible | reason}`.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    case Deeper_Hub.Rewards.grant_reward_to_user(current_user.id, \"reward_points_100\", reason: \"daily_login_bonus\") do
      {:ok, granted_reward} -> Logger.info(\"Recompensa concedida: #{granted_reward.id}\")
      {:error, reason} -> Logger.error(\"Falha ao conceder recompensa: #{reason}\")
    end
    ```

### 6.2. `Deeper_Hub.Rewards.get_user_rewards/2`

*   **Descrição:** Lista todas as recompensas concedidas a um usuário.
*   **`@spec`:** `get_user_rewards(user_id :: String.t(), opts :: Keyword.t()) :: {:ok, list(UserReward.t())} | {:error, reason}`
*   **Parâmetros:**
    *   `user_id` (String): O ID do usuário.
    *   `opts` (Keyword.t()): Opções de filtragem (ex: `[status: :available, type: :item]`).
*   **Retorno:** Lista de structs `UserReward.t()`.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    {:ok, my_rewards} = Deeper_Hub.Rewards.get_user_rewards(current_user.id, status: :available)
    ```

### 6.3. `Deeper_Hub.Rewards.list_definitions/1`

*   **Descrição:** Lista todas as definições de recompensas disponíveis no sistema.
*   **`@spec`:** `list_definitions(opts :: Keyword.t()) :: {:ok, list(Reward.t())} | {:error, reason}`
*   **Parâmetros:**
    *   `opts` (Keyword.t()): Opções de filtragem (ex: `[type: :badge, is_active: true]`).
*   **Retorno:** Lista de structs `Reward.t()`.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    {:ok, all_reward_definitions} = Deeper_Hub.Rewards.list_definitions()
    ```

*(Funções como `claim_reward/2` (se aplicável), `create_reward_definition/1` (admin) seriam documentadas aqui).*

## ⚙️ 7. Configuração

*   **ConfigManager (`Deeper_Hub.Core.ConfigManager`):**
    *   `[:rewards, :default_notification_on_grant]`: (Boolean) Se notifica por padrão ao conceder uma recompensa. (Padrão: `true`)
    *   `[:rewards, :point_system_name]`: Nome do sistema de pontos (ex: \"XP\", \"HubCoins\"). (Padrão: `\"Points\"`)
    *   `[:rewards, :cache, :definitions_ttl_seconds]`: TTL para cache de definições de recompensas.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `Deeper_Hub.Core.Repo`
*   `Deeper_Hub.Core.ConfigManager`
*   `Deeper_Hub.Core.EventBus`
*   `Deeper_Hub.Notifications`
*   `Deeper_Hub.Achievements` (Consumidor de recompensas)
*   `Deeper_Hub.Challenges` (Consumidor de recompensas)
*   `Deeper_Hub.Core.Logger`, `Deeper_Hub.Core.Metrics`

### 8.2. Bibliotecas Externas

*   `Ecto`

## 🤝 9. Como Usar / Integração

*   Módulos como `Achievements` e `Challenges` chamam `Rewards.grant_reward_to_user/3` ao detectar que um usuário se qualificou para uma recompensa.
*   A UI do usuário chama `Rewards.get_user_rewards/2` para exibir o inventário de recompensas.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar a lógica de concessão de recompensas para diferentes gatilhos.
*   Testar o resgate de recompensas (se aplicável).
*   Testar a listagem e visualização de recompensas.
*   Testar a interação com o sistema de notificações.
*   Localização: `test/deeper_hub/rewards/`

### 10.2. Métricas

*   `deeper_hub.rewards.granted.count` (Contador): Número de recompensas concedidas. Tags: `reward_id`, `reward_type`, `trigger_source` (achievement, challenge, manual).
*   `deeper_hub.rewards.claimed.count` (Contador): Número de recompensas resgatadas (se aplicável). Tags: `reward_id`.
*   `deeper_hub.rewards.points_distributed.total` (Contador): Total de pontos distribuídos (se houver recompensas em pontos).

### 10.3. Logs

*   `Logger.info(\"Recompensa '#{reward_name}' concedida ao user_id: #{id} (Motivo: #{reason})\", module: Deeper_Hub.Rewards.Services.RewardsService)`
*   `Logger.info(\"Usuário #{user_id} resgatou a recompensa '#{reward_name}'\", module: Deeper_Hub.Rewards.Services.RewardsService)`

### 10.4. Telemetria

*   `[:deeper_hub, :rewards, :granted]`: Payload: `%{user_id: id, reward_id: rid, user_reward_id: urid, source: src}`.
*   `[:deeper_hub, :rewards, :claimed]`: Payload: `%{user_id: id, user_reward_id: urid}`.

## ❌ 11. Tratamento de Erros

*   `{:error, :reward_not_found}`
*   `{:error, :insufficient_stock}` (se recompensas tiverem estoque limitado)
*   `{:error, :already_claimed}` (para recompensas de uso único)
*   Falhas na concessão devem ser robustas, possivelmente com retentativas se a causa for transitória.

## 🛡️ 12. Considerações de Segurança

*   **Prevenção de Abuso:** Garantir que os mecanismos de concessão de recompensas não possam ser explorados para obter recompensas indevidamente.
*   **Auditoria:** Todas as concessões de recompensas, especialmente manuais, devem ser auditadas.
*   **Valor das Recompensas:** Se as recompensas tiverem valor real ou puderem ser trocadas, considerações adicionais de segurança e prevenção de fraude são necessárias.

## 🧑‍💻 13. Contribuição

*   Ao adicionar novos tipos de recompensas, defina claramente como elas são concedidas, armazenadas e (se aplicável) resgatadas.
*   Garanta que a integração com os módulos que disparam recompensas seja clara e robusta.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar um sistema de \"loja\" onde usuários podem gastar pontos/moedas para obter recompensas.
*   [ ] Suporte para recompensas com tempo de expiração.
*   [ ] Adicionar \"caixas de loot\" ou recompensas aleatórias.
*   [ ] Interface de admin para gerenciar o catálogo de recompensas e conceder/revogar recompensas.
*   [ ] Histórico visual de recompensas para o usuário.

---

*Última atualização: YYYY-MM-DD*

---

Próximo: `Deeper_Hub.Support`?"""),
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
                types.Part.from_text(text="""Beleza! Vamos ao README do `Deeper_Hub.Support`.

---

