# Módulo: `DeeperHub.ServerReviews` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.ServerReviews`

O módulo `DeeperHub.ServerReviews` é responsável por gerenciar as **avaliações e comentários (reviews)** feitos por usuários sobre os servidores listados na plataforma DeeperHub. Ele permite que os jogadores compartilhem suas experiências, atribuam classificações (ratings) e escrevam comentários detalhados, ajudando outros usuários a tomar decisões informadas sobre quais servidores experimentar.

Este módulo abrange a criação, visualização, atualização (pelo autor ou moderadores), exclusão e moderação de reviews, além do cálculo de classificações médias para os servidores. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Criação de Reviews (`create_review/1`):**
    *   Permitir que usuários autenticados submetam reviews para um servidor.
    *   Uma review normalmente inclui uma classificação numérica (ex: 1 a 5 estrelas), um título opcional e um corpo de texto para o comentário.
    *   Impedir que um usuário envie múltiplas reviews para o mesmo servidor (ou permitir apenas a atualização da review existente).
*   **Visualização de Reviews:**
    *   Listar todas as reviews para um servidor específico (`list_reviews_by_server/2`).
    *   Listar todas as reviews feitas por um usuário específico (`list_reviews_by_user/2`).
    *   Obter uma review específica pelo seu ID (`get_review/1`).
    *   Suportar paginação e ordenação (ex: por data, por classificação, por utilidade).
*   **Atualização de Reviews (`update_review/2`):**
    *   Permitir que o autor de uma review edite seu conteúdo ou classificação.
    *   Permitir que moderadores editem ou ocultem partes de uma review se violar as diretrizes.
*   **Exclusão de Reviews (`delete_review/1`):**
    *   Permitir que o autor de uma review a exclua.
    *   Permitir que moderadores/administradores excluam reviews inadequadas.
*   **Cálculo de Classificação Média (`get_server_rating_average/1`):**
    *   Calcular e manter a classificação média para cada servidor com base nas reviews recebidas.
    *   Atualizar a média quando novas reviews são adicionadas, atualizadas ou excluídas.
*   **Moderação de Reviews:**
    *   Sistema para sinalizar reviews (`report_review/2` - pode ser um submódulo de `UserInteractions` ou aqui).
    *   Interface para moderadores revisarem reviews sinalizadas e tomarem ações (aprovar, editar, excluir).
    *   (Opcional) Filtros automáticos para linguagem ofensiva.
*   **Reações a Reviews (Likes/Dislikes, Útil/Não Útil):**
    *   Permitir que usuários reajam a reviews para indicar sua utilidade ou concordância (via `react_to_review/3` - pode ser parte deste módulo ou `UserInteractions`).
*   **Validação e Sanitização de Conteúdo:**
    *   Validar o conteúdo da review (ex: comprimento mínimo/máximo, classificação dentro do range).
    *   Sanitizar o texto da review para prevenir XSS (integrando com `DeeperHub.Security.XssProtection` e `DeeperHub.Services.Shared.ContentValidation`).
*   **Observabilidade e Auditoria:**
    *   Registrar logs e métricas para operações de review.
    *   Publicar eventos de domínio (review criada, atualizada, excluída) no `Core.EventBus`.
    *   Auditar ações de moderação.
*   **Limitação de Taxa (`RateLimitIntegration`):**
    *   Aplicar rate limiting para submissão, edição e outras ações de review.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.ServerReviews` (Fachada Pública):**
    *   Ponto de entrada para todas as operações relacionadas a reviews de servidor.
    *   Delega para o `ServerReviewsService`.
2.  **`DeeperHub.ServerReviews.Services.ServerReviewsService` (ou `DefaultServerReviewsService`):**
    *   **Responsabilidade:** Orquestra a lógica de negócio para reviews.
    *   **Interações:**
        *   `DeeperHub.Core.Repo`: Para CRUD com `ReviewSchema`.
        *   `DeeperHub.Servers`: Para validar `server_id` e atualizar a classificação média do servidor.
        *   `DeeperHub.Accounts`: Para validar `user_id` e obter informações do autor.
        *   `DeeperHub.Auth`/`RBAC`: Para verificar permissões (ex: autor pode editar/excluir, moderador pode excluir).
        *   `DeeperHub.Security.XssProtection` / `Shared.ContentValidation`: Para sanitizar o conteúdo das reviews.
        *   `DeeperHub.Core.EventBus`: Para publicar eventos.
        *   `DeeperHub.Core.Cache`: Para cachear reviews de servidores populares ou classificações médias.
3.  **`DeeperHub.ServerReviews.Schema.Review`:**
    *   Schema Ecto para a entidade Review.
    *   Campos: `id`, `server_id`, `user_id`, `rating` (integer), `title` (string, opcional), `content` (text), `is_verified_purchase` (boolean, opcional), `is_recommended` (boolean, opcional), `status` (ex: `:approved`, `:pending_moderation`, `:rejected`), `edited_at`, `inserted_at`, `updated_at`.
4.  **(Opcional) `DeeperHub.ServerReviews.Schema.ReviewReaction`:**
    *   Schema para reações a reviews (`user_id`, `review_id`, `reaction_type` (`:like`, `:dislike`, `:helpful`)).
5.  **`DeeperHub.ServerReviews.Storage` (ou lógica dentro do `ServerReviewsService`):**
    *   Encapsula as consultas Ecto.
6.  **`DeeperHub.ServerReviews.CachedAdapter` (Opcional):**
    *   Camada de cache explícita para reviews e médias.
7.  **`DeeperHub.ServerReviews.RateLimitIntegration`:**
    *   Aplica rate limiting.
8.  **`DeeperHub.ServerReviews.SecurityIntegration`:**
    *   Lógica específica de segurança para reviews (sanitização).

### 3.2. Estrutura de Diretórios (Proposta)

```
lib/deeper_hub/server_reviews/
├── server_reviews.ex                 # Fachada Pública
│
├── services/
│   └── server_reviews_service.ex     # Serviço principal
│
├── schemas/                          # (Ou schema/)
│   ├── review.ex
│   └── review_reaction.ex            # Opcional
│
├── storage.ex                        # (Opcional) Módulo de queries Ecto
├── cached_adapter.ex                 # (Opcional) Camada de cache
├── rate_limit_integration.ex
├── security_integration.ex
├── supervisor.ex                     # (Se houver GenServers, ex: para moderação assíncrona)
└── telemetry.ex
```

### 3.3. Decisões de Design Importantes

*   **Relação com Servidores e Usuários:** Uma review sempre pertence a um servidor e a um usuário.
*   **Atualização da Média de Rating:** A classificação média de um servidor deve ser atualizada eficientemente sempre que uma review for adicionada, editada (se a classificação mudar) ou excluída. Isso pode ser feito via callbacks Ecto, eventos, ou um cálculo periódico. Um campo denormalizado no `ServerSchema` é comum.
*   **Moderação:** Implementar um fluxo de moderação (manual ou semi-automatizado) é importante para manter a qualidade das reviews.
*   **Evitar Abuso:** Rate limiting na submissão de reviews e detecção de padrões de reviews falsas.

## 🛠️ 4. Casos de Uso Principais

*   **Jogador Escreve uma Review para um Servidor:**
    *   Jogador está na página do servidor, clica em \"Escrever Review\".
    *   Preenche formulário (rating, título, comentário).
    *   API chama `DeeperHub.ServerReviews.create_review(user_id, server_id, review_attrs)`.
    *   Serviço valida, sanitiza, persiste, atualiza a média do servidor e publica evento.
*   **Outro Jogador Lê Reviews de um Servidor:**
    *   API chama `DeeperHub.ServerReviews.list_reviews_by_server(server_id, %{sort_by: :helpful, page: 1})`.
    *   Serviço busca as reviews (possivelmente do cache), incluindo contagem de reações.
*   **Moderador Remove uma Review Inapropriada:**
    *   Moderador identifica uma review que viola as diretrizes.
    *   Chama `DeeperHub.ServerReviews.delete_review(review_id, admin_user_id, %{reason: \"Conteúdo ofensivo\"})`.
    *   Serviço verifica permissões, exclui a review, atualiza a média do servidor e audita a ação.

## 🌊 5. Fluxos Importantes

### Fluxo de Criação de Review

1.  **Requisição API/UI:** Usuário submete o formulário de review.
2.  **Controller API:** Valida autenticação. Chama `DeeperHub.ServerReviews.create_review(current_user.id, server_id, params[\"review\"])`.
3.  **`ServerReviews` (Fachada):** Delega para `ServerReviewsService.create_review/3`.
4.  **`ServerReviewsService.create_review/3`:**
    *   Verifica se o usuário já fez uma review para este servidor (política: uma por usuário).
    *   Chama `DeeperHub.Security.XssProtection` / `Shared.ContentValidation` para validar e sanitizar `title` e `content`.
    *   Cria um changeset para `DeeperHub.ServerReviews.Schema.Review`.
    *   Se o changeset for válido:
        *   Inicia uma transação `Core.Repo.transaction/2`.
        *   Dentro da transação:
            *   `Core.Repo.insert(changeset)`.
            *   Chama `DeeperHub.Servers.Services.DefaultServersService.recalculate_average_rating(server_id)` (ou uma função similar).
        *   Se a transação for bem-sucedida:
            *   Publica evento `server_review_created` via `Core.EventBus`.
            *   Invalida caches relevantes (reviews do servidor, lista de reviews do usuário).
            *   Retorna `{:ok, review_struct}`.
        *   Se a transação falhar, retorna erro.
    *   Se o changeset for inválido, retorna `{:error, changeset}`.

## 📡 6. API (Funções Públicas da Fachada `DeeperHub.ServerReviews`)

### 6.1. `DeeperHub.ServerReviews.create_review(user_id :: String.t(), server_id :: String.t(), attrs :: map()) :: {:ok, Review.t()} | {:error, Ecto.Changeset.t() | term()}`

*   **Descrição:** Cria uma nova review para um servidor.
*   **`attrs`:** `%{rating: 1..5, title: String.t() | nil, content: String.t()}`.

### 6.2. `DeeperHub.ServerReviews.get_review(review_id :: String.t()) :: {:ok, Review.t() | nil}`

*   **Descrição:** Obtém uma review pelo seu ID.

### 6.3. `DeeperHub.ServerReviews.list_reviews_by_server(server_id :: String.t(), opts :: keyword()) :: {:ok, list(Review.t()), Pagination.t()}`

*   **Descrição:** Lista reviews para um servidor.
*   **`opts`:** `:page`, `:per_page`, `:sort_by` (`:rating_desc`, `:rating_asc`, `:newest`, `:oldest`, `:most_helpful`), `:filter_rating` (integer).

### 6.4. `DeeperHub.ServerReviews.list_reviews_by_user(user_id :: String.t(), opts :: keyword()) :: {:ok, list(Review.t()), Pagination.t()}`

*   **Descrição:** Lista reviews feitas por um usuário.

### 6.5. `DeeperHub.ServerReviews.update_review(review_id :: String.t(), attrs :: map(), current_user_id :: String.t()) :: {:ok, Review.t()} | {:error, Ecto.Changeset.t() | :unauthorized}`

*   **Descrição:** Atualiza uma review existente. Requer que `current_user_id` seja o autor ou moderador.

### 6.6. `DeeperHub.ServerReviews.delete_review(review_id :: String.t(), current_user_id :: String.t(), opts :: keyword()) :: :ok | {:error, :unauthorized | :not_found}`

*   **Descrição:** Exclui uma review. Requer autor ou moderador.
*   **`opts`:** `:reason` (String.t) para auditoria de moderação.

### 6.7. `DeeperHub.ServerReviews.get_server_rating_average(server_id :: String.t()) :: {:ok, %{average_rating: float() | nil, review_count: integer()}}`

*   **Descrição:** Retorna a classificação média e o número de reviews de um servidor.

### 6.8. `DeeperHub.ServerReviews.react_to_review(user_id :: String.t(), review_id :: String.t(), reaction_type :: :like | :dislike | :helpful) :: {:ok, Review.t()} | {:error, term()}` (Nova Sugestão)

*   **Descrição:** Permite que um usuário reaja a uma review.

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager`:

*   **`[:server_reviews, :enabled]`** (Boolean): Habilita/desabilita o sistema de reviews. (Padrão: `true`)
*   **`[:server_reviews, :min_rating_value]`** (Integer): Valor mínimo para rating. (Padrão: `1`)
*   **`[:server_reviews, :max_rating_value]`** (Integer): Valor máximo. (Padrão: `5`)
*   **`[:server_reviews, :max_content_length]`** (Integer): Comprimento máximo do texto da review. (Padrão: `5000`)
*   **`[:server_reviews, :allow_editing_after_minutes]`** (Integer): Por quantos minutos após a postagem uma review pode ser editada pelo autor. `0` para sempre, `nil` para nunca. (Padrão: `60`)
*   **`[:server_reviews, :reviews_per_server_per_user]`** (Integer): Quantas reviews um usuário pode fazer por servidor (geralmente `1`).
*   **`[:server_reviews, :default_sort_order]`** (Atom): Ordem padrão para listagem de reviews (ex: `:newest`).
*   **`[:server_reviews, :cache, :reviews_by_server_ttl_seconds]`** (Integer).
*   **`[:server_reviews, :cache, :average_rating_ttl_seconds]`** (Integer).
*   **`[:server_reviews, :moderation, :auto_flag_keywords]`** (List de Strings): Palavras-chave que auto-sinalizam uma review para moderação.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.Repo`, `Core.ConfigManager`, `Core.EventBus`, `Core.Logger`, `Core.Metrics`, `Core.Cache`.
*   `DeeperHub.Servers`: Para associar reviews a servidores e obter/atualizar `average_rating`.
*   `DeeperHub.Accounts`: Para associar reviews a usuários.
*   `DeeperHub.Auth` / `DeeperHub.RBAC`: Para verificar permissões de edição/exclusão.
*   `DeeperHub.Security.XssProtection` e `DeeperHub.Services.Shared.ContentValidation`: Para sanitizar conteúdo.
*   `DeeperHub.ServerReviews.RateLimitIntegration`.

### 8.2. Bibliotecas Externas

*   `Ecto`.

## 🤝 9. Como Usar / Integração

*   **Módulo `DeeperHub.Servers`:**
    *   Ao exibir detalhes de um servidor, pode chamar `ServerReviews.list_reviews_by_server/2` e `ServerReviews.get_server_rating_average/1`.
*   **Interface do Usuário (Frontend/API):**
    *   Fornecer formulários para `create_review` e `update_review`.
    *   Exibir listas de reviews e a média de rating.
    *   Permitir que usuários reajam a reviews.
*   **Painel de Moderação:**
    *   Listar reviews sinalizadas ou todas as reviews com opções de filtro.
    *   Permitir que moderadores editem/ocultem/excluam reviews.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar CRUD de reviews, incluindo validações.
*   Testar a lógica de permissão (autor vs. outros usuários vs. moderadores).
*   Testar o cálculo e atualização da média de rating do servidor.
*   Testar a sanitização de conteúdo.
*   Testar a paginação e ordenação da listagem de reviews.
*   Testar a funcionalidade de reações.
*   Localização: `test/deeper_hub/server_reviews/`.

### 10.2. Métricas

*   `deeper_hub.server_reviews.created.count` (tags: `server_id`, `rating_value`)
*   `deeper_hub.server_reviews.updated.count`
*   `deeper_hub.server_reviews.deleted.count` (tags: `deleted_by_role` (`author`, `moderator`))
*   `deeper_hub.server_reviews.reactions.count` (tags: `review_id`, `reaction_type`)
*   `deeper_hub.server_reviews.average_rating.updated.count` (tags: `server_id`)
*   `deeper_hub.server_reviews.content_sanitized.count`

### 10.3. Logs

*   **Nível INFO:** Nova review criada/atualizada/excluída. Média de rating recalculada.
*   **Nível WARNING:** Tentativa não autorizada de editar/excluir review. Conteúdo de review sinalizado para moderação.
*   **Nível ERROR:** Falha ao persistir review ou atualizar média de rating.

### 10.4. Telemetria

*   `[:deeper_hub, :server_reviews, :review, :created | :updated | :deleted]`
    *   Metadados: `%{review_id: id, server_id: id, user_id: id, rating: val}`
*   `[:deeper_hub, :server_reviews, :server, :rating_recalculated]`
    *   Metadados: `%{server_id: id, new_average_rating: avg, review_count: count}`
*   `[:deeper_hub, :server_reviews, :reaction, :added]`
    *   Metadados: `%{review_id: id, user_id: id, type: type}`

## ❌ 11. Tratamento de Erros

*   Falhas de validação ao criar/atualizar review retornam `{:error, changeset}`.
*   Operações não autorizadas retornam `{:error, :unauthorized}`.
*   Tentativas de operar em reviews/servidores não existentes retornam `{:error, :not_found}`.

## 🛡️ 12. Considerações de Segurança

*   **Sanitização de Conteúdo:** Essencial para prevenir XSS em títulos e comentários de reviews.
*   **Prevenção de Spam/Abuso:** Rate limiting para submissão de reviews. Captcha pode ser necessário se o abuso for alto.
*   **Manipulação de Rating:** Detectar e mitigar tentativas de manipulação de classificação (ex: múltiplas contas falsas avaliando o mesmo servidor). `FraudDetection` pode ajudar.
*   **Privacidade do Autor:** Considerar se as reviews devem ser anônimas ou vinculadas ao perfil do usuário, e como isso afeta a privacidade.

## 🧑‍💻 13. Contribuição

*   Mantenha a lógica de cálculo da média de rating eficiente e correta.
*   Garanta que as verificações de permissão sejam robustas.
*   Considere o impacto na performance ao adicionar novos filtros ou ordenações na listagem de reviews.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar um sistema de \"review mais útil\" baseado em votos da comunidade.
*   [ ] Permitir que proprietários de servidores respondam publicamente às reviews.
*   [ ] Adicionar análise de sentimento às reviews para extrair insights.
*   [ ] Permitir que usuários filtrem reviews por idioma.
*   [ ] Implementar um sistema de \"review verificada\" para jogadores que comprovadamente jogaram no servidor (ex: através de integração com o jogo ou tempo de jogo).
*   [ ] Opção para usuários reportarem reviews como úteis, spam, ou abusivas. (Já mencionado, mas reforçar).

---

*Última atualização: 2025-05-12*

---

Este README do `ServerReviews` cobre os aspectos centrais.

O que gostaria de detalhar em seguida? Poderíamos continuar com os \"submódulos de serviço\" como `ServerPackages`, `ServerEvents`, ou mudar para um módulo Core diferente como `DeeperHub.Core.BackgroundTaskManager` (que já começamos)?"""),
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
                types.Part.from_text(text="""Ok, já documentamos o `DeeperHub.Core.BackgroundTaskManager`.

Vamos então para outro módulo Core que é fundamental para a interação da aplicação com o mundo externo e para a consistência interna: `DeeperHub.Core.APIResponder`. Ele garante que todas as respostas da API sigam um padrão, facilitando a vida dos desenvolvedores de frontend e de integrações.

---

