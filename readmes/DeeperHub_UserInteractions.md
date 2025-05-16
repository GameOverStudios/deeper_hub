# Módulo: `Deeper_Hub.UserInteractions` 💬

## 📜 1. Visão Geral do Módulo `Deeper_Hub.UserInteractions`

O módulo `Deeper_Hub.UserInteractions` é responsável por gerenciar as diversas formas de interação social e engajamento entre usuários e com entidades (como servidores) dentro da plataforma Deeper_Hub. Ele engloba funcionalidades como seguir entidades, favoritar, enviar mensagens diretas, dar feedback, fazer recomendações e reportar conteúdo ou usuários. O objetivo é fomentar uma comunidade ativa e fornecer mecanismos para interações positivas e gerenciamento de interações negativas. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Favoritos (Ex: Usuário favoritando um Servidor):**
    *   Permitir que usuários marquem entidades (ex: Servidores) como favoritas.
    *   Listar os favoritos de um usuário.
    *   Remover um item dos favoritos.
*   **Seguir (Ex: Usuário seguindo um Servidor, Usuário seguindo outro Usuário):**
    *   Permitir que usuários sigam outras entidades para receber atualizações.
    *   Listar quem um usuário segue e quem segue um usuário/entidade.
    *   Deixar de seguir.
*   **Mensagens Diretas/Chat (Usuário para Usuário):**
    *   Permitir que usuários troquem mensagens privadas.
    *   Listar conversas e mensagens.
    *   MarInteractions.Schema.Favorite`: Para favoritos.
    *   `Deeper_Hub.UserInteractions.Schema.Follow`: Para seguidores.
    *   `Deeper_Hub.UserInteractions.Schema.ChatMessage`: Para mensagens de chat.
    *   `Deeper_Hub.UserInteractions.Schema.Recommendation`: Para recomendações.
    *   `Deeper_Hub.UserInteractions.Schema.Feedback`: Para feedback.
    *   `Deeper_Hub.UserInteractions.Schema.Report`: Para denúncias.
*   **Integrações:**
    *   `Deeper_Hub.Core.Repo`: Para persistência.
    *   `Deeper_Hub.Core.EventBus`: Para publicar eventos de interação.
    *   `Deeper_Hub.Notifications`: Para notificar usuários sobre interações.
    *   `Deeper_Hub.Accounts`: Para obter informações de usuários.
    *   `Deeper_Hub.Servers` (ou outros módulos de conteúdo): Para associar interações a entidades específicas.

**Padrões de Design:**

*   **Fachada (Facade).**
*   **Serviço de Domínio para cada tipo de interação.**

### 3.1. Componentes Principais

*   **`Deeper_Hub.UserInteractions.UserInteractionsFacade`:** Ponto de entrada.
*   **Serviços dedicados para cada tipo de interação** (ex: `FavoriteService`, `ChatMessageService`).
*   **Schemas Ecto correspondentes** (ex: `Favorite`, `ChatMessage`).
*   **`Deeper_Hub.UserInteractions.Supervisor`:** Supervisiona processos.

### 3.3. Decisões de Design Importantes

*   **Escalabilidade do Chat:** Se o chat tiver alto volume, pode precisar de uma arquitetura mais robusta, possivelmente com WebSockets e um backend de mensagens dedicado (ex: RabbitMQ, Kafka), e o `ChatMessageService` se tornaria mais complexo.
*   **Moderação de Denúncias:** Definir o fluxo de trabalho para revisão e ação sobre denúncias.
*   **Privacidade de Mensagens:** Garantir que mensagens diretas sejam acessíveis apenas pelos participantes da conversa.

## 🛠️ 4. Casos de Uso Principais

*   **Usuário Favorita um Servidor:** Um usuário encontra um servidor que gosta e o adiciona aos seus favoritos.
*   **Usuário Envia Mensagem para Outro Usuário:** Um usuário inicia uma conversa privada com outro membro da plataforma.
*   **Usuário Denuncia uma Review Inapropriada:** Um usuário lê uma review que viola as diretrizes e a denuncia para moderação.
*   **Usuário Recomenda um Servidor a um Amigo:** Um usuário envia uma recomendação de servidor para outro usuário.
*   **Usuário Envia Feedback sobre uma Feature:** Um usuário utiliza um formulário para enviar sugestões sobre uma nova funcionalidade.

## 🌊 5. Fluxos Importantes (Opcional)

**Fluxo de Envio de uma Mensagem de Chat:**

1.  Usuário A (remetente) envia uma mensagem para o Usuário B (destinatário) através da UI/API.
2.  `Deeper_Hub.API` (Controller) chama `Deeper_Hub.UserInteractions.send_chat_message(sender_id, receiver_id, content)`.
3.  A fachada delega para `Deeper_Hub.UserInteractions.Services.ChatMessageService.send_message/3`.
4.  `ChatMessageService`:car mensagens como lidas/não lidas.
    *   (Opcional) Notificações de novas mensagens.
*   **Feedback sobre Entidades/Sistema:**
    *   Permitir que usuários submetam feedback (ex: sugestões, bugs) sobre o sistema ou entidades específicas.
    *   Gerenciamento e categorização de feedback pela equipe.
*   **Recomendações (Ex: Usuário recomendando um Servidor):**
    *   Permitir que usuários recomendem entidades para outros ou para a comunidade.
    *   Listar recomendações feitas por um usuário ou para uma entidade.
*   **Denúncias (Reportar Conteúdo/Usuário):**
    *   Permitir que usuários reportem conteúdo (ex: reviews, mensagens) ou outros usuários por comportamento inadequado, spam, etc.
    *   Gerenciamento da fila de denúncias para moderação.
*   **Reações (Ex: Likes/Dislikes em Reviews, Posts):**
    *   Permitir que usuários reajam a diferentes tipos de conteúdo.
    *   Contabilizar e exibir reações.
*   **Notificações:**
    *   Notificar usuários sobre novas mensagens, quando alguém começa a segui-los, quando um favorito é atualizado, etc. (via `Deeper_Hub.Notifications`).
*   **Controle de Privacidade (Potencial):**
    *   Permitir que usuários configurem quem pode enviar mensagens diretas, ver seus seguidores/seguindo, etc.

## 🏗️ 3. Arquitetura e Design

`Deeper_Hub.UserInteractions` atuará como uma fachada para diversos serviços especializados, cada um lidando com um tipo específico de interação.

*   **Interface Pública (`Deeper_Hub.UserInteractions.UserInteractionsFacade` ou `Deeper_Hub.UserInteractions`):** Funções como `add_favorite/2`, `send_message/3`, `report_user/3`.
*   **Serviços Especializados:**
    *   `Deeper_Hub.UserInteractions.Services.FavoriteService`: Gerencia lógica de favoritos.
    *   `Deeper_Hub.UserInteractions.Services.FollowService`: Gerencia lógica de seguir.
    *   `Deeper_Hub.UserInteractions.Services.MessagingService`: Gerencia mensagens diretas.
    *   `Deeper_Hub.UserInteractions.Services.FeedbackService`: Gerencia feedback.
    *   `Deeper_Hub.UserInteractions.Services.RecommendationService`: Gerencia recomendações.
    *   `Deeper_Hub.UserInteractions.Services.ReportService`: Gerencia denúncias.
    *   `Deeper_Hub.UserInteractions.Services.ReactionService`: Gerencia reações.
*   **Schemas Ecto:**
    *   `Deeper_Hub.UserInteractions.Schema.Favorite`: Relação de favorito.
    *   `Deeper_Hub.UserInteractions.Schema.Follow`: Relação de seguir.
    *   `Deeper_Hub.UserInteractions.Schema.ChatMessage`: Mensagem de chat.
    *   `Deeper_Hub.UserInteractions.Schema.Feedback`: Registro de feedback.
    *   `Deeper_Hub.UserInteractions.Schema.Recommendation`: Registro de recomendação.
    *   `Deeper_Hub.UserInteractions.Schema.Report`: Registro de denúncia.
    *   `Deeper_Hub.UserInteractions.Schema.Reaction`: Registro de reação.
*   **Integrações:**
    *   `Deeper_Hub.Core.Repo`: Para persistência.
    *   `Deeper_Hub.Core.EventBus`: Para publicar eventos de interação.
    *   `Deeper_Hub.Notifications`: Para enviar notificações.
    *   `Deeper_Hub.Accounts`: Para obter informações de usuários.
    *   `Deeper_Hub.Servers` (ou outras entidades): Para associar interações a entidades específicas.
    *   `Deeper_Hub.Services.Shared.ContentValidation`: Para validar conteúdo de mensagens, reports, etc.

**Padrões de Design:**

*   **Fachada (Facade).**
*   **Serviços de Domínio Dedicados.**

### 3.1. Componentes Principais

*   **`Deeper_Hub.UserInteractions.UserInteractionsFacade`:** Ponto de entrada.
*   **Serviços:** `FavoriteService`, `FollowService`, `MessagingService`, etc.
*   **Schemas:** `Favorite`, `Follow`, `ChatMessage`, etc.
*   **`Deeper_Hub.UserInteractions.Supervisor`:** Supervisiona os processos dos serviços.
*   **`Deeper_Hub.UserInteractions.EventHandler` (Opcional):** Para processar eventos que possam desencadear interações ou notificações de forma assíncrona.

### 3.3. Decisões de Design Importantes

*   **Escalabilidade do Chat:** Para mensagens diretas, considerar uma solução de backend que escale bem para tempo real (ex: Phoenix Channels, ou um backend de mensagens dedicado se o volume for muito alto).
*   **Moderação de Conteúdo:** Definir fluxos para moderação de denúncias e conteúdo reportado.
*   **Privacidade:** Implementar configurações de privacidade para interações (ex: quem pode me enviar mensagens).

## 🛠️ 4. Casos de Uso Principais

*   **Usuário Favorita um Servidor:** Um usuário encontra um servidor interessante e o adiciona à sua lista de favoritos.
*   **Usuário Envia Mensagem para Outro Usuário:** Dois usuários iniciam uma conversa privada.
*   **Usuário Reporta um Comentário Abusivo:** Um usuário denuncia um comentário em uma review de servidor.
*   **Usuário Dá Feedback sobre uma Feature:** Um usuário envia uma sugestão de melhoria para a plataforma.
*   **Sistema Recomenda um Servidor:** Baseado nas interações e perfil de um usuário, o sistema (ou outro usuário) recomenda um servidor.

## 🌊 5. Fluxos Importantes (Opcional)

**Fluxo de Envio de Mensagem Direta:**

1.  Usuário A (remetente) envia uma mensagem para Usuário B (destinatário) através da UI/API.
2.  `Deeper_Hub.API` (Controller) chama `Deeper_Hub.UserInteractions.send_message(remetente_id, destinatario_id, conteudo_mensagem)`.
3.  A fachada delega para `Deeper_Hub.UserInteractions.Services.MessagingService.send_message/3`.
4.  `MessagingService`:
    *   Valida o conteúdo da mensagem (`Shared.ContentValidation`).
    *   Verifica se o destinatário permite mensagens do remetente (políticas de privacidade).
    *   Cria um registro `ChatMessage` e o persiste via `Core.Repo`.
    *   Publica um evento `NewChatMessageEvent` no `Core.EventBus`.
5.  `Deeper_Hub.Notifications` (ou um handler de evento específico) escuta o `NewChatMessageEvent` e envia uma notificação (push, in-app, email) para o Usu
    *   Valida a mensagem (ex: comprimento, conteúdo permitido).
    *   Cria um registro `ChatMessage` com `sender_id`, `receiver_id`, `content`, `timestamp`.
    *   Persiste a mensagem via `Core.Repo`.
    *   Publica um evento `ChatMessageSentEvent` no `Core.EventBus`.
5.  Um listener de eventos (possivelmente no `Deeper_Hub.Notifications` ou um `NotificationService` específico para chat):
    *   Detecta o `ChatMessageSentEvent`.
    *   Envia uma notificação (push, in-app) para o Usuário B sobre a nova mensagem, se ele não estiver online/ativo na conversa.
6.  Retorna `{:ok, message_struct}`.

## 📡 6. API (Se Aplicável)

### 6.1. `Deeper_Hub.UserInteractions.add_favorite/2`

*   **Descrição:** Adiciona um item (ex: servidor) aos favoritos de um usuário.
*   **`@spec`:** `add_favorite(user_id :: String.t(), target :: %{type: atom(), id: String.t()}) :: {:ok, Favorite.t()} | {:error, reason}`
*   **Parâmetros:**
    *   `user_id` (String): ID do usuário.
    *   `target` (map): Mapa identificando o item a ser favoritado, ex: `%{type: :server, id: \"server_abc\"}`.
*   **Retorno:** O registro de favorito criado ou um erro.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    Deeper_Hub.UserInteractions.add_favorite(current_user.id, %{type: :server, id: \"server_xyz\"})
    ```

### 6.2. `Deeper_Hub.UserInteractions.send_chat_message/3`

*   **Descrição:** Envia uma mensagem de chat de um usuário para outro.
*   **`@spec`:** `send_chat_message(sender_id :: String.t(), receiver_id :: String.t(), content :: String.t()) :: {:ok, ChatMessage.t()} | {:error, reason}`
*   **Parâmetros:**
    *   `sender_id` (String): ID do remetente.
    *   `receiver_id` (String): ID do destinatário.
    *   `content` (String): Conteúdo da mensagem.
*   **Retorno:** A mensagem de chat criada ou um erro.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    Deeper_Hub.UserInteractions.send_chat_message(current_user.id, \"other_user_id\", \"Olá, tudo bem?\")
    ```

### 6.3. `Deeper_Hub.UserInteractions.create_report/1`

*   **Descrição:** Permite que um usuário crie uma denúncia sobre um conteúdo ou outro usuário.
*   **`@spec`:** `create_report(attrs :: map()) :: {:ok, Report.t()} | {:error, Ecto.Changeset.t() | reason}`
*   **Parâmetros:**
    *   `attrs` (map): Atributos da denúncia.
        *   `:reporter_id` (String): ID do usuário que está denunciando.
        *   `:target_type` (atom): Tipo do alvo da denúncia (ex: `:user`, `:server`, `:review`).
        *   `:target_id` (String): ID do alvo da denúncia.
        *   `:reason_category` (String): Categoria da razão da denúncia (ex: \"spam\", \"harassment\", \"inappropriate_content\").
        *   `:description` (String): Descrição detalhada da denúncia.
*   **Retorno:** O registro da denúncia criado ou um erro.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    report_attrs = %{
      reporter_id: current_user.id,
      target_type: :review,
      target_id: \"review_abc\",
      reason_category: \"spam\",
      description: \"Esta review é claramente spam promocional.\"
    }
    Deeper_Hub.UserInteractions.create_report(report_attrs)
    ```

*(Outras funções como `list_user_favorites/1`, `list_chat_conversations/1`, `get_reports_for_moderation/1` seriam documentadas aqui).*

## ⚙️ 7. Configuração

*   **ConfigManager (`Deeper_Hub.Core.ConfigManager`):**
    *   `[:user_interactions, :chat, :max_message_length]`: Comprimento máximo para mensagens de chat. (Padrão: `1000`)
    *   `[:user_interactions, :chat, :history_retention_days]`: Por quanto tempo o histórico de chat é mantido. (Padrão: `365`)
    *   `[:user_interactions, :reports, :default_status]`: Status padrão para novas denúncias. (Padrão: `:pending_review`)
    *   `[:user_interactions, :feedback, :categories]`: Lista de categorias de feedback disponíveis.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `Deeper_Hub.Core.Repo`
*   `Deeper_Hub.Core.ConfigManager`
*   `Deeper_Hub.Core.EventBus`
*   `Deeper_Hub.Notifications`
*   `Deeper_Hub.Accounts`
*   `Deeper_Hub.Servers` (e outros módulos de conteúdo, como alvos de favoritos/denúncias)
*   `Deeper_Hub.Core.InputValidator`, `Deeper_Hub.Services.Shared.ContentValidation`
*   `Deeper_Hub.Core.Logger`, `Deeper_Hub.Core.Metrics`

### 8.2. Bibliotecas Externas

*   `Ecto`

## 🤝 9. Como Usar / Integração

*   **UI/Frontend:** A interface do usuário permitirá favoritar, enviar mensagens, denunciar, etc., chamando os endpoints da API que, por sua vez, utilizam esta fachada.
*   **Moderação:** Uma interface de administração usará este módulo para visualizar e gerenciar denúncias e feedback.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar cada funcionalidade de interação (favoritos, chat, denúncias, etc.) individualmente.
*   Testar as permissões (ex: um usuário não pode deletar o favorito de outro).
*   Testar a lógica de notificação para interações.
*   Localização: `test/deeper_hub/user_interactions/`

### 10.2. Métricas

*   `deeper_hub.user_interactions.favorite.added.count` (Contador): Tags: `target_type`.
*   `deeper_hub.user_interactions.chat_message.sent.count` (Contador).
*   `deeper_hub.user_interactions.report.created.count` (Contador): Tags: `target_type`, `reason_category`.
*   `deeper_hub.user_interactions.feedback.submitted.count` (Contador): Tags: `feedback_category`.

### 10.3. Logs

*   `Logger.info(\"Usuário #{uid} favoritou #{target_type}:#{tid}\", module: Deeper_Hub.UserInteractions.Services.FavoriteService)`
*   `Logger.info(\"Mensagem enviada de #{sid} para #{rid}\", module: Deeper_Hub.UserInteractions.Services.ChatMessageService)`
*   `Logger.info(\"Denúncia #{rid} criada por #{reporter_id} contra #{target_type}:#{target_id}\", module: Deeper_Hub.UserInteractions.Services.ReportService)`

### 10.4. Telemetria

*   `[:deeper_hub, :user_interactions, :favorite, :added | :removed]`
*   `[:deeper_hub, :user_interactions, :chat_message, :sent]`
*   `[:deeper_hub, :user_interactions, :report, :created | :status_changed]`
*   `[:deeper_hub, :user_interactions, :feedback, :submitted]`

## ❌ 11. Tratamento de Erros

*   `{:error, :target_not_found}`
*   `{:error, :already_favorited}`
*   `{:error, :cannot_message_self}`
*   `{:error, :report_target_invalid}`
*   Falhas de validação de conteúdo para mensagens ou descrições de denúncias.

## 🛡️ 12. Considerações de Segurança

*   **Privacidade do Chat:** Mensagens diretas devem ser estritamente privadas entre os participantes.
*   **Moderação de Conteúdo:** É crucial ter um sistema eficaz para lidar com denúncias de conteúdo e comportamento inadequado.
*   **Sanitização de Entrada:** Todo o texto fornecido pelo usuário (mensagens, descrições de denúncia, feedback) deve ser sanitizado para prevenir XSS.
*   **Prevenção de Spam/Abuso:** Rate limiting na criação de mensagens, denúncias ou feedback.

## 🧑‍💻 13. Contribuição

*   Novos tipos de interação devem ser implementados em seus próprios módulos de serviço.
*   Considere o impacto na privacidade e segurança ao adicionar novas funcionalidades sociais.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar sistema de \"seguir\" usuários ou servidores.
*   [ ] Adicionar reações (likes/dislikes) a mais tipos de conteúdo.
*   [ ] Bloqueio de usuários no chat.
*   [ ] Grupos de chat.
*   [ ] Indicação de \"digitando...\" e status de leitura no chat.
*   [ ] Histórico de moderação para denúncias.
*   [ ] Análise de sentimento para feedback.

---

*Última atualização: YYYY-MM-DD*

---

O próximo módulo da sua lista de \"Services\" seria `Elixir.Deeper_Hub.Services.Lists`. Como ele parece ser um módulo genérico para diferentes tipos de listas (`AchievementType`, `Category`, `ContentType`, etc.), o README dele seria um pouco diferente, focando na sua capacidade de gerenciar coleções de dados simples.

Podemos prosseguir com `Deeper_Hub.Lists`?"""),
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
                types.Part.from_text(text="""Ok, vamos ao README do `Deeper_Hub.Lists`. Este é um módulo um pouco mais abstrato, então o foco será em sua funcionalidade genérica.

---

