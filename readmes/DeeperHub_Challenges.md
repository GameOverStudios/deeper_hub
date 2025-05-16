# Módulo: `Deeper_Hub.Challenges` 🎯

## 📜 1. Visão Geral do Módulo `Deeper_Hub.Challenges`

O módulo `Deeper_Hub.Challenges` é responsável por gerenciar desafios e competições dentro da plataforma Deeper_Hub. Ele permite a criação de desafios com objetivos específicos, prazos, e recompensas, incentivando o engajamento e a participação ativa dos usuários. Os usuários podem participar dos desafios, submeter suas participações (quando aplicável) e serem reconhecidos por completá-los. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Definição de Desafios:**
    *   CRUD para Desafios (`Challenge`): nome, descrição, tipo de desafio (ex: individual, equipe, baseado em tempo, baseado em objetivo), critérios de conclusão, data de início e fim, recompensas associadas.
    *   Suporte para desafios recorrentes ou únicos.
    *   Configuração de regras de participação (ex: nível mínimo, conquistas pré-requisitadas).
*   **Participação do Usuário:**
    *   Permitir que usuários visualizem desafios ativos e futuros.
    *   Permitir que usuários se inscrevam ou participem de desafios.
    *   Rastrear o progresso do usuário em desafios ativos (via `UserChallenge`).
*   **Submissão e Avaliação (para certos tipos de desafios):**
    *   Permitir que usuários submetam suas participações/provas de conclusão (ex: link, texto, upload de arquivo).
    *   Interface para administradores ou um sistema automatizado avaliar as submissões.
*   **Conclusão de Desafios:**
    *   Verificar automaticamente (ou após avaliação manual) se um usuário completou um desafio.
    *   Marcar um desafio como concluído para um usuário e registrar a data de conclusão.
*   **Recompensas e Reconhecimento:**
    *   Integrar com `Deeper_Hub.Rewards` para conceder recompensas aos usuários que completam desafios.
    *   Potencialmente, desbloquear conquistas (`Deeper_Hub.Achievements`) pela participação ou conclusão de desafios.
    *   Exibição de \"hall da fama\" ou leaderboards para desafios competitivos.
*   **Notificações:**
    *   Notificar usuários sobre novos desafios, lembretes de prazo, status de participação e conclusão (via `Deeper_Hub.Notifications`).
*   **Administração de Desafios:**
    *   Interface para administradores criarem, modificarem, ativarem/desativarem e monitorarem desafios.

## 🏗️ 3. Arquitetura e Design

`Deeper_Hub.Challenges` será uma fachada que interage com um serviço de lógica de negócio e componentes de persistência.

*   **Interface Pública (`Deeper_Hub.Challenges.ChallengesFacade` ou `Deeper_Hub.Challenges`):** Funções como `list_active_challenges/1`, `join_challenge/2`, `complete_challenge/3`.
*   **Serviço de Desafios (`Deeper_Hub.Challenges.Services.ChallengesService`):**
    *   Contém a lógica de negócio principal para gerenciar definições de desafios, participação de usuários, avaliação de progresso/conclusão.
*   **Schemas Ecto:**
    *   `Deeper_Hub.Challenges.Schema.Challenge`: Define um desafio.
    *   `Deeper_Hub.Challenges.Schema.UserChallenge`: Rastreia a participação e o status de um usuário em um desafio.
    *   `Deeper_Hub.Challenges.Schema.ChallengeSubmission` (Opcional): Para desafios que requerem submissão.
*   **Processamento de Eventos/Tarefas Agendadas:**
    *   Workers (via `Core.BackgroundTaskManager`) para verificar prazos de desafios, processar conclusões em lote, ou atualizar leaderboards.
*   **Integrações:**
    *   `Deeper_Hub.Core.Repo`: Para persistência.
    *   `Deeper_Hub.Core.EventBus`: Para publicar eventos (ex: `ChallengeCompletedEvent`) e escutar eventos que podem influenciar o progresso de desafios.
    *   `Deeper_Hub.Notifications`: Para notificar usuários.
    *   `Deeper_Hub.Rewards`: Para conceder recompensas.
    *   `Deeper_Hub.Achievements`: Para desbloquear conquistas relacionadas a desafios.

**Padrões de Design:**

*   **Fachada (Facade).**
*   **Serviço de Domínio.**
*   **State Machine (Opcional):** Para gerenciar o ciclo de vida de um desafio (ex: Pendente, Ativo, Em Avaliação, Concluído, Arquivado).

### 3.1. Componentes Principais

*   **`Deeper_Hub.Challenges.ChallengesFacade`:** Ponto de entrada.
*   **`Deeper_Hub.Challenges.Services.ChallengesService`:** Lógica de negócio.
*   **`Deeper_Hub.Challenges.Schema.Challenge`:** Schema do desafio.
*   **`Deeper_Hub.Challenges.Schema.UserChallenge`:** Schema da participação do usuário.
*   **`Deeper_Hub.Challenges.Supervisor`:** Supervisiona processos.
*   **Workers (ex: `ChallengeDeadlineWorker`):** Para tarefas periódicas.

### 3.3. Decisões de Design Importantes

*   **Tipos de Desafios:** Definir claramente os diferentes tipos de desafios suportados e como seus critérios de conclusão são avaliados (automática vs. manual).
*   **Escopo de Participação:** Se os desafios são individuais, para equipes, ou abertos a todos.
*   **Flexibilidade dos Critérios:** Como os critérios de conclusão são definidos e verificados (ex: baseado em eventos específicos, contagem de ações, submissão de dados).

## 🛠️ 4. Casos de Uso Principais

*   **Administrador Cria um Desafio Semanal:** Um admin define um desafio \"Postar 5 Reviews de Qualidade esta Semana\" com recompensas em pontos.
*   **Usuário Aceita um Desafio:** Um usuário visualiza os desafios ativos e clica em \"Participar\" no desafio semanal.
*   **Sistema Verifica Conclusão Automática:** Após um usuário postar sua 5ª review na semana, o sistema automaticamente marca o desafio como concluído para ele.
*   **Usuário Submete Prova para um Desafio Criativo:** Para um desafio \"Crie o Melhor Avatar Temático\", usuários fazem upload de uma imagem. Administradores depois avaliam as submissões.
*   **Usuário Visualiza seus Desafios:** Um usuário acessa uma página para ver os desafios em que está participando e seu progresso.

## 🌊 5. Fluxos Importantes (Opcional)

**Fluxo de Conclusão de um Desafio Baseado em Ação:**

1.  Usuário realiza uma ação no sistema (ex: cria um post, completa uma tarefa).
2.  O módulo responsável pela ação emite um evento no `Core.EventBus` (ex: `PostCreatedEvent`).
3.  Um `EventHandler` no módulo `Challenges` (ou o `ChallengesService` diretamente, se síncrono) escuta este evento.
4.  O handler verifica se o `user_id` do evento está participando de algum desafio ativo que tenha esta ação como critério.
5.  Se sim, o `ChallengesService` atualiza o progresso no registro `UserChallenge` correspondente.
6.  O `ChallengesService` verifica se os critérios de conclusão do desafio foram atendidos com esta atualização.
7.  Se concluído:
    *   Marca `UserChallenge` como `status: :completed`, preenche `completed_at`.
    *   Emite um evento `ChallengeCompletedEvent`.
    *   (Opcional) Chama `Deeper_Hub.Rewards.grant_reward_for_challenge/2`.
    *   (Opcional) Enfileira uma notificação via `Deeper_Hub.Notifications`.
8.  O `EventHandler` confirma o processamento do evento.

## 📡 6. API (Se Aplicável)

### 6.1. `Deeper_Hub.Challenges.list_active_challenges/1`

*   **Descrição:** Lista todos os desafios atualmente ativos e disponíveis para participação.
*   **`@spec`:** `list_active_challenges(opts :: Keyword.t()) :: {:ok, list(Challenge.t())} | {:error, reason}`
*   **Parâmetros:**
    *   `opts` (Keyword.t()): Opções de filtragem (ex: `[category: \"social\", difficulty: :medium]`).
*   **Retorno:** Lista de structs `Challenge.t()`.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    {:ok, active_challenges} = Deeper_Hub.Challenges.list_active_challenges(category: \"community\")
    ```

### 6.2. `Deeper_Hub.Challenges.join_challenge/2`

*   **Descrição:** Permite que um usuário se inscreva para participar de um desafio.
*   **`@spec`:** `join_challenge(user_id :: String.t(), challenge_id :: String.t()) :: {:ok, UserChallenge.t()} | {:error, reason}`
*   **Parâmetros:**
    *   `user_id` (String): O ID do usuário.
    *   `challenge_id` (String): O ID do desafio.
*   **Retorno:**
    *   `{:ok, user_challenge_struct}`: Se a inscrição for bem-sucedida.
    *   `{:error, :already_joined | :not_eligible | :challenge_not_active | :not_found | reason}`.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    case Deeper_Hub.Challenges.join_challenge(current_user.id, \"challenge_xyz\") do
      {:ok, participation} -> Logger.info(\"Usuário #{current_user.id} juntou-se ao desafio #{participation.challenge_id}\")
      {:error, reason} -> Logger.warning(\"Falha ao entrar no desafio: #{reason}\")
    end
    ```

### 6.3. `Deeper_Hub.Challenges.get_user_challenge_status/2`

*   **Descrição:** Obtém o status e progresso de um usuário em um desafio específico.
*   **`@spec`:** `get_user_challenge_status(user_id :: String.t(), challenge_id :: String.t()) :: {:ok, UserChallenge.t()} | {:error, :not_joined | :not_found | reason}`
*   **Parâmetros:**
    *   `user_id` (String): O ID do usuário.
    *   `challenge_id` (String): O ID do desafio.
*   **Retorno:** A struct `UserChallenge.t()` com o status e progresso, ou erro.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    {:ok, status} = Deeper_Hub.Challenges.get_user_challenge_status(current_user.id, \"challenge_xyz\")
    ```

*(Outras funções como `submit_for_challenge/3`, `list_user_challenges/1` seriam documentadas aqui).*

## ⚙️ 7. Configuração

*   **ConfigManager (`Deeper_Hub.Core.ConfigManager`):**
    *   `[:challenges, :default_reward_type]`: Tipo de recompensa padrão para desafios (ex: `:points`).
    *   `[:challenges, :max_active_challenges_per_user]`: Número máximo de desafios que um usuário pode participar simultaneamente. (Padrão: `5`)
    *   `[:challenges, :worker, :deadline_check_interval_hours]`: Intervalo para o worker verificar desafios expirados. (Padrão: `1`)
    *   `[:challenges, :notification_on_completion]`: (Boolean) Se envia notificação ao completar desafio. (Padrão: `true`)

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `Deeper_Hub.Core.Repo`
*   `Deeper_Hub.Core.ConfigManager`
*   `Deeper_Hub.Core.EventBus`
*   `Deeper_Hub.Core.BackgroundTaskManager`
*   `Deeper_Hub.Notifications`
*   `Deeper_Hub.Rewards`
*   `Deeper_Hub.Achievements` (Potencial)
*   `Deeper_Hub.Core.Logger`, `Deeper_Hub.Core.Metrics`

### 8.2. Bibliotecas Externas

*   `Ecto`

## 🤝 9. Como Usar / Integração

*   **UI/Frontend:** Apresenta desafios aos usuários, permite participação e visualização de progresso.
*   **Módulos de Domínio:** Emitem eventos que são consumidos pelo `Challenges.EventHandler` para atualizar o progresso.
*   **Administração:** Admins usam uma interface (console ou UI) para criar e gerenciar desafios.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar a criação e listagem de desafios.
*   Testar a lógica de participação e elegibilidade.
*   Testar a verificação de critérios de conclusão para diferentes tipos de desafios.
*   Testar o fluxo de submissão e avaliação (se aplicável).
*   Testar a concessão de recompensas ao completar.
*   Localização: `test/deeper_hub/challenges/`

### 10.2. Métricas

*   `deeper_hub.challenges.created.count` (Contador): Número de desafios criados. Tags: `challenge_type`.
*   `deeper_hub.challenges.joined.count` (Contador): Número de participações em desafios. Tags: `challenge_id`.
*   `deeper_hub.challenges.completed.count` (Contador): Número de desafios concluídos. Tags: `challenge_id`.
*   `deeper_hub.challenges.submission.received.count` (Contador): Número de submissões recebidas. Tags: `challenge_id`.
*   `deeper_hub.challenges.active.gauge` (Gauge): Número de desafios ativos no momento.

### 10.3. Logs

*   `Logger.info(\"Desafio '#{name}' criado.\", module: Deeper_Hub.Challenges.Services.ChallengesService)`
*   `Logger.info(\"Usuário #{user_id} participou do desafio '#{challenge_id}'.\", module: Deeper_Hub.Challenges.Services.ChallengesService)`
*   `Logger.info(\"Usuário #{user_id} completou o desafio '#{challenge_id}'.\", module: Deeper_Hub.Challenges.Services.ChallengesService)`

### 10.4. Telemetria

*   `[:deeper_hub, :challenges, :joined]`: Payload: `%{user_id: id, challenge_id: cid}`.
*   `[:deeper_hub, :challenges, :progress_updated]`: Payload: `%{user_id: id, challenge_id: cid, progress: p}`.
*   `[:deeper_hub, :challenges, :completed]`: Payload: `%{user_id: id, challenge_id: cid, completed_at: ts}`.

## ❌ 11. Tratamento de Erros

*   `{:error, :challenge_not_found}`
*   `{:error, :not_eligible_for_challenge}`
*   `{:error, :challenge_not_active_for_participation}`
*   `{:error, :already_participating}`
*   `{:error, :submission_failed}`
*   Erros de persistência devem ser logados e, se possível, tratados para não quebrar o fluxo principal do usuário.

## 🛡️ 12. Considerações de Segurança

*   **Validação de Submissões:** Se desafios envolvem submissões de usuários, estas devem ser validadas e sanitizadas para prevenir XSS ou outros ataques.
*   **Critérios Justos:** Garantir que os critérios dos desafios não possam ser facilmente explorados ou \"farmados\".
*   **Administração Segura:** A criação e gerenciamento de desafios deve ser restrita a administradores.

## 🧑‍💻 13. Contribuição

*   Ao adicionar novos tipos de desafios, defina claramente seus critérios e como o progresso/conclusão será avaliado.
*   Considere a performance ao verificar critérios de conclusão, especialmente para desafios com muitos participantes ou que dependem de muitos eventos.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar desafios baseados em equipe.
*   [ ] Adicionar leaderboards visuais para desafios competitivos.
*   [ ] Suporte para desafios com múltiplos estágios ou objetivos.
*   [ ] Melhorar a interface de administração de desafios.
*   [ ] Permitir que usuários criem seus próprios desafios (com moderação).

---

*Última atualização: YYYY-MM-DD*

---

Próximo da lista de \"Services\" é `Deeper_Hub.Rewards`. Vamos a ele?"""),
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
                types.Part.from_text(text="""Ótimo! Seguimos com o README para `Deeper_Hub.Rewards`.

---

