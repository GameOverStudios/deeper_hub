# Módulo: `DeeperHub.UserInteractions` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.UserInteractions`

O módulo `DeeperHub.UserInteractions` gerencia as **interações sociais e engajamentos entre os usuários** da plataforma DeeperHub, bem como as interações dos usuários com entidades como servidores. Ele abrange funcionalidades como seguir servidores, adicionar servidores aos favoritos, enviar mensagens privadas, dar feedback, fazer recomendações e reportar conteúdo ou usuários.

O objetivo deste módulo é enriquecer a experiência social na plataforma, permitir que os usuários se conectem, compartilhem opiniões e ajudem a manter a comunidade segura e relevante. 😊

*(Nota: Na documentação original, este era `DeeperHub.Services.UserInteractions`. Estamos tratando-o como um contexto de domínio mais amplo.)*

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Favoritar Servidores (`add_favorite/2`, `remove_favorite/2`, `list_favorites/2`, `is_favorite?/2`):**
    *   Permitir que usuários marquem servidores como favoritos.
    *   Listar os servidores favoritos de um usuário.
    *   Verificar se um usuário favoritou um servidor específico.
*   **Seguir Servidores (Nova Sugestão, similar a favoritos mas com semântica de \"receber atualizações\"):**
    *   Permitir que usuários sigam servidores para receber notificações sobre suas atualizações ou eventos.
    *   Gerenciar a lista de seguidores de um servidor e servidores seguidos por um usuário.
*   **Mensagens Diretas entre Usuários (Chat) (`send_chat_message/1`, `list_chat_messages/3`):**
    *   Permitir que usuários enviem e recebam mensagens diretas uns dos outros.
    *   Manter o histórico de conversas.
    *   (Opcional) Indicação de status (online, offline, digitando).
    *   (Opcional) Notificações de novas mensagens.
*   **Recomendações de Servidores (`create_or_update_recommendation/1`, `list_recommendations_for_user/2`):**
    *   Permitir que usuários recomendem servidores para outros usuários ou para a comunidade.
    *   O sistema pode gerar recomendações automáticas com base no comportamento do usuário ou similaridade.
*   **Feedback sobre a Plataforma (`submit_feedback/1`, `list_feedback/1`):**
    *   Permitir que usuários enviem feedback geral sobre a plataforma DeeperHub (sugestões, bugs, usabilidade).
*   **Denúncias (Reports) de Conteúdo ou Usuários (`create_report/1`, `list_reports/1`):**
    *   Permitir que usuários denunciem servidores, reviews, mensagens de chat, ou outros usuários por comportamento inadequado ou violação das diretrizes.
    *   Gerenciar o fluxo de moderação dessas denúncias.
*   **Reações (Likes/Dislikes/Votos) em Conteúdo (Nova Sugestão, ou parte de cada módulo de conteúdo):**
    *   Permitir que usuários reajam (ex: curtir, dar um upvote/downvote) a reviews, mensagens de atualização de servidor, etc.
*   **Listas de Amigos/Conexões (Nova Sugestão):**
    *   Permitir que usuários adicionem outros como amigos ou conexões.
    *   Visualizar a atividade de amigos (com controle de privacidade).
*   **Observabilidade e Auditoria:**
    *   Logar e metrificar interações.
    *   Publicar eventos de domínio (ex: `user.favorited_server`, `chat.message_sent`).
    *   Auditar denúncias e ações de moderação.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.UserInteractions` (Fachada Pública):**
    *   Ponto de entrada para todas as operações de interação social.
    *   Delega para o `UserInteractionsService`.
2.  **`DeeperHub.UserInteractions.Services.UserInteractionsService` (ou `DefaultUserInteractionsService`):**
    *   **Responsabilidade:** Orquestra a lógica de negócio para as diferentes interações.
    *   **Interações:**
        *   `DeeperHub.Core.Repo`: Para CRUD com os schemas de interação (`FavoriteSchema`, `ChatMessageSchema`, `FeedbackSchema`, `RecommendationSchema`, `ReportSchema`, etc.).
        *   `DeeperHub.Accounts`: Para validar `user_id` e obter informações de usuário.
        *   `DeeperHub.Servers`: Para validar `server_id` ao favoritar/recomendar.
        *   `DeeperHub.Auth`/`RBAC`: Para verificar permissões (ex: se um usuário pode enviar mensagem para outro, se moderador pode ver denúncias).
        *   `DeeperHub.Notifications`: Para notificar usuários sobre novas mensagens, feedback respondido, etc.
        *   `DeeperHub.Core.EventBus`: Para publicar eventos de interação.
        *   `DeeperHub.Core.Cache`: Para cachear dados como listas de favoritos ou contagens de reações.
3.  **Schemas Ecto:**
    *   **`DeeperHub.UserInteractions.Schemas.FavoriteSchema`:** (`user_id`, `server_id`, `added_at`).
    *   **`DeeperHub.UserInteractions.Schemas.FollowSchema` (Nova):** (`follower_user_id`, `followed_entity_type` (ex: `:server`, `:user`), `followed_entity_id`, `followed_at`).
    *   **`DeeperHub.UserInteractions.Schemas.ChatMessageSchema`:** (`sender_id`, `receiver_id`, `content`, `sent_at`, `read_at`).
    *   **`DeeperHub.UserInteractions.Schemas.FeedbackSchema`:** (`user_id` (opcional), `type` (`:bug`, `:suggestion`, `:complaint`), `content`, `status` (`:new`, `:in_progress`, `:resolved`), `submitted_at`).
    *   **`DeeperHub.UserInteractions.Schemas.RecommendationSchema`:** (`recommender_user_id`, `recommended_server_id`, `target_user_id` (opcional, se for para um usuário específico), `reason`, `score` (opcional), `created_at`).
    *   **`DeeperHub.UserInteractions.Schemas.ReportSchema`:** (`reporter_user_id`, `reported_entity_type` (`:user`, `:server`, `:review`, `:chat_message`), `reported_entity_id`, `reason_category`, `details`, `status` (`:pending_review`, `:action_taken`, `:dismissed`), `submitted_at`).
    *   **`DeeperHub.UserInteractions.Schemas.ReactionSchema` (Nova):** (`user_id`, `target_entity_type`, `target_entity_id`, `reaction_type` (`:like`, `:dislike`, `:helpful`, etc.), `created_at`).
    *   **`DeeperHub.UserInteractions.Schemas.FriendshipSchema` (Nova):** (`user1_id`, `user2_id`, `status` (`:pending`, `:accepted`, `:blocked`), `requested_at`, `accepted_at`).
4.  **`DeeperHub.UserInteractions.Storage` (ou lógica no `UserInteractionsService`):**
    *   Encapsula as queries Ecto.
5.  **Workers (Opcional):**
    *   `NotificationDispatcherWorker`: Para enviar notificações de novas mensagens de chat ou outras interações de forma assíncrona.
    *   `ReportModerationQueueWorker`: Para processar denúncias e atribuí-las a moderadores.
    *   `RecommendationEngineWorker`: Para gerar recomendações automáticas em background.

### 3.2. Estrutura de Diretórios (Proposta)

```
lib/deeper_hub/user_interactions/
├── user_interactions.ex              # Fachada Pública
│
├── services/
│   └── user_interactions_service.ex  # Serviço principal
│   # Potencialmente, serviços mais específicos: ChatService, ReportService, etc.
│
├── schemas/
│   ├── favorite_schema.ex
│   ├── follow_schema.ex
│   ├── chat_message_schema.ex
│   ├── feedback_schema.ex
│   ├── recommendation_schema.ex
│   ├── report_schema.ex
│   ├── reaction_schema.ex
│   └── friendship_schema.ex
│
├── storage.ex                        # (Opcional)
│
├── workers/                          # Opcional
│   ├── notification_dispatcher_worker.ex
│   └── report_moderation_queue_worker.ex
│
├── supervisor.ex
└── telemetry.ex
```

### 3.3. Decisões de Design Importantes

*   **Privacidade:** As interações, especialmente mensagens diretas e denúncias, devem ser tratadas com alta consideração pela privacidade.
*   **Moderação:** Um sistema robusto de moderação é essencial para denúncias e, potencialmente, para outro conteúdo gerado pelo usuário que possa surgir de interações.
*   **Escalabilidade do Chat:** Se o chat for uma feature principal, pode precisar de uma arquitetura mais especializada (ex: usando Phoenix Channels, um backend de mensagens dedicado) em vez de simples armazenamento no DB.
*   **Notificações Granulares:** Os usuários devem poder controlar quais tipos de notificações de interação eles recebem.

## 🛠️ 4. Casos de Uso Principais

*   **Usuário Favorita um Servidor:**
    *   Na página do servidor, usuário clica em \"Favoritar\".
    *   API chama `UserInteractions.add_favorite(user_id, server_id)`.
*   **Usuário Envia uma Mensagem Direta para Outro Usuário:**
    *   Na interface de chat, usuário_A envia \"Olá!\" para usuário_B.
    *   API chama `UserInteractions.send_chat_message(%{sender_id: \"A\", receiver_id: \"B\", content: \"Olá!\"})`.
    *   O sistema envia uma notificação (push/in-app) para usuário_B.
*   **Usuário Denuncia uma Review de Servidor:**
    *   Usuário clica em \"Denunciar\" em uma review.
    *   Preenche motivo e detalhes.
    *   API chama `UserInteractions.create_report(%{reporter_user_id: \"uid\", reported_entity_type: :review, reported_entity_id: \"review_id\", ...})`.
    *   Uma notificação é enviada para a equipe de moderação.
*   **Sistema Sugere um Servidor para um Usuário:**
    *   `RecommendationEngineWorker` analisa o histórico do usuário.
    *   Chama `UserInteractions.create_or_update_recommendation(%{recommender_user_id: \"system\", recommended_server_id: \"server_xyz\", target_user_id: \"uid\", reason: \"Baseado em seus favoritos\"})`.

## 🌊 5. Fluxos Importantes

### Fluxo de Envio de Mensagem de Chat

1.  **Usuário A (UI):** Envia a mensagem \"Olá!\" para Usuário B.
2.  **Controller API:** Recebe a requisição. Chama `DeeperHub.UserInteractions.send_chat_message(%{sender_id: \"A\", receiver_id: \"B\", content: \"Olá!\"})`.
3.  **`UserInteractionsService.send_chat_message/1`:**
    *   Valida se o remetente pode enviar mensagem para o destinatário (ex: não bloqueado, ambos existem).
    *   Sanitiza o `content` (via `Shared.ContentValidation`).
    *   Cria um `ChatMessageSchema` changeset.
    *   Persiste a mensagem via `Core.Repo.insert(changeset)`.
    *   Se sucesso:
        *   Enfileira uma notificação para o `receiver_id` (via `DeeperHub.Notifications`, possivelmente por um `NotificationDispatcherWorker` para não bloquear).
        *   Publica evento `chat.message_sent` no `Core.EventBus`.
        *   Retorna `{:ok, chat_message_struct}`.
4.  **Usuário B:** Recebe a notificação (push ou in-app) e sua UI de chat é atualizada.

## 📡 6. API (Funções Públicas da Fachada `DeeperHub.UserInteractions`)

### 6.1. Favoritos e Seguir

*   `add_favorite(user_id, server_id)`
*   `remove_favorite(user_id, server_id)`
*   `list_user_favorites(user_id, opts)`
*   `is_favorite?(user_id, server_id)`
*   `follow_server(user_id, server_id)` (Nova)
*   `unfollow_server(user_id, server_id)` (Nova)
*   `list_user_followed_servers(user_id, opts)` (Nova)

### 6.2. Mensagens de Chat

*   `send_chat_message(attrs :: %{sender_id: String.t(), receiver_id: String.t(), content: String.t()})`
*   `list_chat_messages(user_id_A :: String.t(), user_id_B :: String.t(), opts :: keyword())`
*   `mark_chat_messages_as_read(user_id_viewer :: String.t(), other_user_id :: String.t(), up_to_message_id :: String.t() | nil)` (Nova)

### 6.3. Recomendações

*   `create_or_update_recommendation(attrs :: %{recommender_user_id: String.t(), recommended_server_id: String.t(), target_user_id: String.t() | nil, reason: String.t(), score: float() | nil})`
*   `list_recommendations_for_user(user_id, opts)`
*   `list_recommendations_from_user(user_id, opts)` (Nova)

### 6.4. Feedback da Plataforma

*   `submit_feedback(attrs :: %{user_id: String.t() | nil, type: atom(), content: String.t(), contact_email: String.t() | nil})`
*   `list_feedback(filters, opts)` (Admin)
*   `update_feedback_status(feedback_id, new_status, admin_id)` (Admin)

### 6.5. Denúncias (Reports)

*   `create_report(attrs :: %{reporter_user_id: String.t(), reported_entity_type: atom(), reported_entity_id: String.t(), reason_category: String.t(), details: String.t()})`
*   `list_reports(filters, opts)` (Admin/Moderador)
*   `update_report_status(report_id, new_status, moderator_id, action_taken_notes :: String.t() | nil)` (Admin/Moderador)

### 6.6. Reações (Nova API Sugerida)

*   `add_reaction(user_id, target_entity_type, target_entity_id, reaction_type)`
*   `remove_reaction(user_id, target_entity_type, target_entity_id, reaction_type)`
*   `get_reactions_for_entity(target_entity_type, target_entity_id)` (Retorna contagens por tipo de reação)

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager`:

*   **`[:user_interactions, :chat, :enabled]`** (Boolean).
*   **`[:user_interactions, :chat, :max_message_length]`** (Integer).
*   **`[:user_interactions, :favorites, :max_per_user]`** (Integer).
*   **`[:user_interactions, :reports, :categories]`** (List de Strings): Categorias de denúncia permitidas.
*   **`[:user_interactions, :reports, :notify_moderators_on_new_report]`** (Boolean).
*   **`[:user_interactions, :feedback, :allowed_types]`** (List de Atoms).
*   **`[:user_interactions, :recommendations, :max_user_recommendations]`** (Integer).
*   **`[:user_interactions, :rate_limit, <action>, :limit | :window_seconds]`**: Configs de rate limit para ações como `send_chat_message`, `create_report`.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.*`: Todos os módulos Core.
*   `DeeperHub.Accounts`: Para `user_id` e perfis de usuário.
*   `DeeperHub.Servers`: Para `server_id` em favoritos, recomendações, denúncias.
*   `DeeperHub.Auth`/`RBAC`: Para permissões (ex: quem pode ver/gerenciar denúncias).
*   `DeeperHub.Notifications`: Para notificar sobre novas mensagens, status de denúncias, etc.
*   `DeeperHub.Services.Shared.ContentValidation`: Para validar e sanitizar conteúdo de mensagens, feedback, denúncias.
*   `DeeperHub.Audit`.

### 8.2. Bibliotecas Externas

*   `Ecto`.
*   Se o chat for em tempo real, `Phoenix.PubSub` ou `Phoenix.Presence` podem ser usados internamente.

## 🤝 9. Como Usar / Integração

*   **UI do Usuário:** Várias seções da UI (perfil do servidor, perfil do usuário, chat, central de ajuda) chamarão endpoints da API que usam este módulo.
*   **Painel de Moderação/Administração:** Para visualizar e gerenciar denúncias e feedback.
*   **Sistema de Notificações:** O `UserInteractionsService` frequentemente chamará `DeeperHub.Notifications` para informar usuários sobre novas mensagens, respostas a feedback, status de denúncias, etc.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar cada funcionalidade principal: favoritos, chat (envio, listagem), feedback, recomendações, denúncias.
*   Testar a lógica de permissão (ex: usuário não pode ver chat de outros, apenas moderador vê todas as denúncias).
*   Testar validação e sanitização de conteúdo.
*   Testar a interação com notificações.
*   Localização: `test/deeper_hub/user_interactions/`.

### 10.2. Métricas

*   `deeper_hub.user_interactions.favorites.added.count`
*   `deeper_hub.user_interactions.chat_messages.sent.count`
*   `deeper_hub.user_interactions.feedback.submitted.count` (tags: `type`)
*   `deeper_hub.user_interactions.reports.created.count` (tags: `entity_type`, `reason_category`)
*   `deeper_hub.user_interactions.recommendations.created.count`
*   `deeper_hub.user_interactions.reactions.added.count` (tags: `entity_type`, `reaction_type`)

### 10.3. Logs

*   **Nível INFO:** Nova interação criada (favorito, mensagem, feedback, denúncia).
*   **Nível WARNING:** Tentativa de ação não permitida (ex: enviar mensagem para usuário bloqueado). Denúncia recebida para conteúdo/usuário.
*   **Nível ERROR:** Falha ao persistir uma interação.

### 10.4. Telemetria

*   `[:deeper_hub, :user_interactions, <interaction_type>, :created | :deleted]`
    *   Ex: `[:deeper_hub, :user_interactions, :favorite, :created]`
    *   Metadados: `%{user_id: id, target_id: id_if_applicable, details: ...}`
*   `[:deeper_hub, :user_interactions, :report, :status_changed]`
    *   Metadados: `%{report_id: id, new_status: status, moderator_id: id}`

## ❌ 11. Tratamento de Erros

*   Falhas de validação retornam `{:error, changeset}`.
*   Operações não autorizadas retornam `{:error, :unauthorized}`.
*   Erros ao enviar notificações são logados, mas a interação principal (ex: envio de mensagem) deve ser bem-sucedida se possível.

## 🛡️ 12. Considerações de Segurança

*   **Privacidade das Mensagens de Chat:** Mensagens diretas devem ser confidenciais e acessíveis apenas pelos participantes e, em casos específicos, por administradores/moderadores com justificativa (ex: investigação de denúncia). Criptografia de ponta-a-ponta é uma consideração avançada se a privacidade for extrema.
*   **Sanitização de TODO Conteúdo:** Todo conteúdo gerado pelo usuário (mensagens, feedback, detalhes de denúncia) deve ser rigorosamente sanitizado.
*   **Abuso de Denúncias:** O sistema de denúncias pode ser abusado. Implementar rate limiting e, potencialmente, um sistema de reputação para quem denuncia.
*   **Proteção contra Spam no Chat:** Limitar a frequência de mensagens ou o número de novas conversas que um usuário pode iniciar.

## 🧑‍💻 13. Contribuição

*   Mantenha a lógica de cada tipo de interação (favoritos, chat, etc.) o mais isolada possível dentro do `UserInteractionsService` ou em seus próprios submódulos de serviço se crescerem muito.
*   Garanta que os eventos e notificações apropriados sejam disparados.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar sistema de \"bloquear usuário\" para chat e outras interações.
*   [ ] Adicionar indicadores de \"digitando...\" e \"mensagem lida\" no chat.
*   [ ] Suporte para envio de mídias (imagens, vídeos curtos) em mensagens de chat.
*   [ ] \"Grupos de Amigos\" ou \"Comunidades de Servidor\" com chat em grupo.
*   [ ] Sistema de reputação para usuários baseado em suas interações e histórico de denúncias (feitas e recebidas).
*   [ ] Recomendações de servidores mais inteligentes usando ML com base no histórico de interações e favoritos de usuários similares.
*   [ ] Feed de atividades para o usuário (ex: \"Seu amigo X favoritou o servidor Y\", \"Nova review no seu servidor favorito Z\").

---

*Última atualização: 2025-05-12*

---

Este módulo de interações é bem rico e pode crescer bastante com funcionalidades sociais!

Onde vamos agora? Que tal `DeeperHub.Webhooks` para ver como o DeeperHub se comunica com sistemas externos, ou talvez `DeeperHub.Shared.Utils.ValidationUtils` para finalizar os utilitários?"""),
            ],
        ),
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(text="""continue
"""),
            ],
        ),
        types.Content(
            role="model",
            parts=[
                types.Part.from_text(text="""Ok, já detalhamos o `DeeperHub.Shared.Utils.ValidationUtils`.

Vamos agora finalizar os módulos de utilitários com o `DeeperHub.Shared.Utils.SecurityUtils`, que, embora já tenhamos tocado em alguns aspectos de segurança, este é focado em primitivas de segurança de baixo nível.

---

