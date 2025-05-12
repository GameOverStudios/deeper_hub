# Módulo: `DeeperHub.ServerUpdateMessages` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.ServerUpdateMessages`

O módulo `DeeperHub.ServerUpdateMessages` gerencia as **mensagens de atualização, notas de patch e anúncios importantes** publicados pelos proprietários de servidores na plataforma DeeperHub. Ele serve como um canal de comunicação oficial do servidor para sua comunidade, permitindo informar sobre novas funcionalidades, correções de bugs, mudanças no jogo, ou qualquer outra notícia relevante.

Este módulo lida com:
*   A criação, edição e exclusão de mensagens de atualização por proprietários de servidores.
*   A listagem cronológica dessas mensagens para um servidor específico.
*   A notificação de jogadores (especialmente aqueles que seguem o servidor) sobre novas mensagens de atualização.

O objetivo é manter os jogadores informados sobre o desenvolvimento e as novidades de seus servidores favoritos. 😊

*(Nota: Na documentação original, este era `DeeperHub.Services.ServerUpdateMessages`. Será tratado como `DeeperHub.ServerUpdateMessages`.)*

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Gerenciamento CRUD de Mensagens de Atualização (`create_update_message/1`, `get_update_message/1`, `update_update_message/2`, `delete_update_message/1`):**
    *   Permitir que proprietários de servidores (ou administradores com permissão) criem novas mensagens de atualização.
    *   Cada mensagem inclui: título, conteúdo (corpo da mensagem, que pode suportar markdown ou HTML limitado e sanitizado), versão do servidor (opcional), data de publicação.
    *   Permitir a edição ou exclusão de mensagens publicadas (com restrições ou histórico de versões, opcional).
*   **Listagem de Mensagens de Atualização:**
    *   Listar todas as mensagens de atualização para um servidor específico, geralmente em ordem cronológica inversa (`list_update_messages_by_server/2`).
    *   Obter a última mensagem de atualização de um servidor (`get_latest_update_message/2`).
    *   Suportar paginação para o histórico de mensagens.
*   **Formatação de Conteúdo:**
    *   Suportar Markdown ou um subconjunto seguro de HTML para o corpo da mensagem, com sanitização rigorosa (via `DeeperHub.Security.XssProtection` e `Shared.ContentValidation`).
*   **Notificações (Integração com `DeeperHub.Notifications` e `UserInteractions`):**
    *   Notificar usuários que seguem um servidor (ou que optaram por receber essas notificações) quando uma nova mensagem de atualização é publicada.
*   **Visibilidade e Publicação:**
    *   Permitir que mensagens sejam salvas como rascunho antes de serem publicadas.
    *   Controle sobre a data de publicação.
*   **Observabilidade e Auditoria:**
    *   Logar e metrificar a criação e visualização de mensagens de atualização.
    *   Publicar eventos de domínio (ex: `server_update_message.published`) no `Core.EventBus`.
    *   Auditar a criação/modificação de mensagens.
*   **Caching:**
    *   Cachear as últimas mensagens de atualização de servidores populares ou frequentemente acessados.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.ServerUpdateMessages` (Fachada Pública):**
    *   Ponto de entrada para todas as operações relacionadas a mensagens de atualização.
    *   Delega para o `ServerUpdateMessagesService`.
2.  **`DeeperHub.ServerUpdateMessages.Services.ServerUpdateMessagesService` (ou `DefaultServerUpdateMessagesService`):**
    *   **Responsabilidade:** Orquestra a lógica de negócio para as mensagens de atualização.
    *   **Interações:**
        *   `DeeperHub.Core.Repo`: Para CRUD com `UpdateMessageSchema`.
        *   `DeeperHub.Servers`: Para validar `server_id` e associar mensagens.
        *   `DeeperHub.Accounts`: Para `user_id` do autor (proprietário/admin).
        *   `DeeperHub.Auth`/`RBAC`: Para permissões de gerenciamento de mensagens.
        *   `DeeperHub.Security.XssProtection` / `Shared.ContentValidation`: Para sanitizar o conteúdo das mensagens.
        *   `DeeperHub.Core.EventBus`: Para publicar eventos.
        *   `DeeperHub.Core.Cache`: Para cachear mensagens.
        *   `DeeperHub.Notifications`: Para enviar notificações sobre novas mensagens.
3.  **`DeeperHub.ServerUpdateMessages.Schemas.UpdateMessageSchema` (ex-`UpdateMessage`):**
    *   Campos: `id`, `server_id`, `author_user_id`, `title` (string), `content` (text, armazena o markdown/html sanitizado), `published_at` (DateTime UTC), `version_tag` (string, opcional, ex: \"v1.2.3\"), `status` (`:draft`, `:published`, `:archived`), `inserted_at`, `updated_at`.
4.  **`DeeperHub.ServerUpdateMessages.Storage` (ou lógica no `ServerUpdateMessagesService`):**
    *   Encapsula as queries Ecto.
5.  **`DeeperHub.ServerUpdateMessages.CachedAdapter` (Opcional):**
    *   Camada de cache explícita.

### 3.2. Estrutura de Diretórios (Proposta)

```
lib/deeper_hub/server_update_messages/
├── server_update_messages.ex         # Fachada Pública
│
├── services/
│   └── server_update_messages_service.ex # Serviço principal
│
├── schemas/
│   └── update_message_schema.ex
│
├── storage.ex                        # (Opcional)
├── cached_adapter.ex                 # (Opcional)
├── supervisor.ex                     # (Se houver GenServers)
└── telemetry.ex
```

### 3.3. Decisões de Design Importantes

*   **Formato do Conteúdo:** Decidir sobre o formato do conteúdo (Markdown é uma boa escolha por ser seguro e flexível) e implementar a sanitização e renderização apropriadas.
*   **Histórico de Edições:** Para mensagens importantes, considerar manter um histórico de edições.
*   **Fluxo de Publicação:** Ter um status `:draft` permite que os proprietários preparem as mensagens antes de torná-las públicas.

## 🛠️ 4. Casos de Uso Principais

*   **Proprietário de Servidor Escreve Notas de Patch:**
    *   No painel do servidor, proprietário cria uma nova mensagem de atualização, detalhando as mudanças da versão \"v1.5.2\".
    *   Define o status como `:draft` inicialmente.
    *   Após revisar, publica a mensagem. API chama `ServerUpdateMessages.create_update_message(user_id, server_id, %{title: \"Patch v1.5.2\", content: \"...\", version_tag: \"v1.5.2\", status: :published})`.
    *   Usuários que seguem o servidor são notificados.
*   **Jogador Visualiza as Últimas Atualizações de um Servidor:**
    *   Na página do servidor, a UI busca e exibe as últimas mensagens via `ServerUpdateMessages.list_update_messages_by_server(server_id, %{limit: 5})`.
*   **Proprietário Edita uma Mensagem Publicada para Corrigir um Erro de Digitação:**
    *   API chama `ServerUpdateMessages.update_update_message(message_id, %{content: \"Conteúdo corrigido\"}, user_id)`.

## 🌊 5. Fluxos Importantes

### Fluxo de Publicação de Nova Mensagem de Atualização

1.  **Proprietário (UI):** Submete o formulário da nova mensagem de atualização, marcando para \"Publicar Agora\".
2.  **Controller API:** Valida autenticação e autorização. Chama `DeeperHub.ServerUpdateMessages.create_update_message(current_user.id, server_id, params[\"message_attrs\"])`.
3.  **`ServerUpdateMessagesService.create_update_message/3`:**
    *   Valida se `current_user.id` pode postar no `server_id`.
    *   Chama `DeeperHub.Services.Shared.ContentValidation.validate_user_content(attrs.content, :update_message_content)` para sanitizar o corpo da mensagem.
    *   Cria um `UpdateMessageSchema` changeset com `status: :published` e `published_at: DateTime.utc_now()`.
    *   Se válido, `Core.Repo.insert(changeset)`.
    *   Se sucesso:
        *   Publica evento `server_update_message.published` no `Core.EventBus` (`%{message_id: msg.id, server_id: ..., title: ...}`).
        *   (Assíncrono) Enfileira notificações para seguidores do servidor via `DeeperHub.Notifications`.
        *   Invalida caches relevantes.
        *   Retorna `{:ok, message_struct}`.
    *   Se falha, retorna erro.

## 📡 6. API (Funções Públicas da Fachada `DeeperHub.ServerUpdateMessages`)

### 6.1. Gerenciamento de Mensagens (Proprietário/Admin)

*   **`DeeperHub.ServerUpdateMessages.create_update_message(author_user_id :: String.t(), server_id :: String.t(), attrs :: map()) :: {:ok, UpdateMessage.t()} | {:error, Ecto.Changeset.t()}`**
    *   `attrs`: `%{title: String.t(), content: String.t(), version_tag: String.t() | nil, status: :draft | :published, publish_at: DateTime.t() | nil}`.
*   **`DeeperHub.ServerUpdateMessages.update_update_message(message_id :: String.t(), attrs :: map(), current_user_id :: String.t()) :: {:ok, UpdateMessage.t()} | {:error, Ecto.Changeset.t() | :unauthorized}`**
*   **`DeeperHub.ServerUpdateMessages.delete_update_message(message_id :: String.t(), current_user_id :: String.t()) :: :ok | {:error, :unauthorized | :not_found}`**

### 6.2. Consulta de Mensagens

*   **`DeeperHub.ServerUpdateMessages.get_update_message(message_id :: String.t()) :: {:ok, UpdateMessage.t() | nil}`**
*   **`DeeperHub.ServerUpdateMessages.list_update_messages_by_server(server_id :: String.t(), opts :: keyword()) :: {:ok, list(UpdateMessage.t()), Pagination.t()}`**
    *   `opts`: `:status` (`:published`, `:draft`), `:page`, `:per_page`, `:sort_by` (`:published_at_desc`, `:updated_at_desc`).
*   **`DeeperHub.ServerUpdateMessages.get_latest_update_message(server_id :: String.t(), opts :: keyword()) :: {:ok, UpdateMessage.t() | nil}`**
    *   Retorna a última mensagem com status `:published`.

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager`:

*   **`[:server_update_messages, :enabled]`** (Boolean).
*   **`[:server_update_messages, :max_title_length]`** (Integer). (Padrão: `150`)
*   **`[:server_update_messages, :max_content_length]`** (Integer). (Padrão: `10000`)
*   **`[:server_update_messages, :content_format]`** (Atom): `:markdown` ou `:html_subset`. (Padrão: `:markdown`)
*   **`[:server_update_messages, :notify_followers_on_publish]`** (Boolean). (Padrão: `true`)
*   **`[:server_update_messages, :cache, :latest_message_ttl_seconds]`** (Integer).
*   **`[:server_update_messages, :cache, :message_list_ttl_seconds]`** (Integer).

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.*`.
*   `DeeperHub.Servers`: Para `server_id`.
*   `DeeperHub.Accounts`: Para `author_user_id`.
*   `DeeperHub.Auth`/`RBAC`: Para permissões.
*   `DeeperHub.Notifications`: Para notificar sobre novas mensagens.
*   `DeeperHub.Security.XssProtection` e `DeeperHub.Services.Shared.ContentValidation`: Para sanitizar conteúdo.
*   `DeeperHub.UserInteractions` (especificamente a funcionalidade de \"seguir servidor\" para notificações).

### 8.2. Bibliotecas Externas

*   `Ecto`.
*   Uma biblioteca Markdown para Elixir (ex: `Earmark`) se o formato for Markdown.
*   Uma biblioteca de sanitização HTML (ex: `HtmlSanitizeEx`) se HTML limitado for permitido.

## 🤝 9. Como Usar / Integração

*   **UI do Proprietário do Servidor:** Formulários para criar/editar/publicar mensagens de atualização.
*   **Página do Servidor (UI do Jogador):** Seção para exibir as últimas mensagens de atualização (`list_update_messages_by_server` ou `get_latest_update_message`).
*   **Sistema de Notificações:** Notificar usuários que seguem o servidor quando uma nova mensagem com status `:published` é criada.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar CRUD para `UpdateMessageSchema`.
*   Testar a lógica de `status` (`:draft` vs `:published`).
*   Testar a sanitização do conteúdo da mensagem.
*   Testar a lógica de notificação.
*   Testar a listagem e paginação.
*   Localização: `test/deeper_hub/server_update_messages/`.

### 10.2. Métricas

*   `deeper_hub.server_update_messages.published.count` (tags: `server_id`)
*   `deeper_hub.server_update_messages.views.count` (tags: `message_id`, `server_id`) (Se o rastreamento de visualização for implementado).
*   `deeper_hub.server_update_messages.content_sanitized.count`

### 10.3. Logs

*   **Nível INFO:** Nova mensagem publicada/atualizada/excluída.
*   **Nível WARNING:** Tentativa não autorizada de gerenciar uma mensagem. Falha na sanitização de conteúdo (se crítico).

### 10.4. Telemetria

*   `[:deeper_hub, :server_update_messages, :message, :created | :updated | :deleted | :published]`
    *   Metadados: `%{message_id: id, server_id: id, author_id: id}`

## ❌ 11. Tratamento de Erros

*   Falhas de validação ao criar/atualizar retornam `{:error, changeset}`.
*   Operações não autorizadas retornam `{:error, :unauthorized}`.

## 🛡️ 12. Considerações de Segurança

*   **Sanitização de Conteúdo:** Absolutamente CRUCIAL para `title` e `content` para prevenir XSS e outras injeções de HTML/script.
*   **Autorização:** Apenas o proprietário do servidor ou administradores com permissão devem poder criar/gerenciar estas mensagens.
*   **Abuso:** Limitar a frequência de postagem ou o tamanho das mensagens para evitar spam ou sobrecarga.

## 🧑‍💻 13. Contribuição

*   Garanta que a sanitização de conteúdo seja robusta.
*   Considere a experiência do usuário ao exibir mensagens longas ou com formatação complexa.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Permitir \"fixar\" mensagens importantes no topo.
*   [ ] Adicionar contagem de visualizações para mensagens.
*   [ ] Suporte para agendar a publicação de mensagens (definir `published_at` no futuro e um worker para mudar o status).
*   [ ] Permitir comentários de usuários nas mensagens de atualização (com moderação).
*   [ ] Histórico de versões para mensagens editadas.
*   [ ] Templates para tipos comuns de mensagens de atualização.

---

*Última atualização: 2025-05-12*

---

Este módulo ajuda os proprietários de servidores a manterem suas comunidades informadas!

O próximo poderia ser `DeeperHub.ServerPackages` (para itens/VIPs de servidor) ou `DeeperHub.ServerAlerts` (para anúncios mais urgentes), ou podemos mudar para `DeeperHub.Lists` que parece ser um módulo de listagem genérico?"""),
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
                types.Part.from_text(text="""Ok, vamos continuar com os módulos relacionados a `Servers` e detalhar o `DeeperHub.ServerPackages`. Este módulo lida com pacotes ou itens que podem ser oferecidos pelos servidores, como passes VIP, itens virtuais, etc.

---

