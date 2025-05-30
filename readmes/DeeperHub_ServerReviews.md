# Módulo: `DeeperHub.ServerReviews` ⭐

## 📜 1. Visão Geral do Módulo `DeeperHub.ServerReviews`

O módulo `DeeperHub.ServerReviews` é responsável por gerenciar as avaliações (reviews) e classificações que os usuários fornecem para os servidores listados na plataforma DeeperHub. Ele permite que os usuários compartilhem suas experiências, deem notas e escrevam comentários sobre os servidores, ajudando outros usuários a tomar decisões informadas e fornecendo feedback valioso aos proprietários dos servidores. O sistema também lida com o cálculo de médias de avaliação e pode incluir funcionalidades de moderação. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Criação de Avaliações:**
    *   Permitir que usuários autenticados submetam avaliações para servidores.
    *   Campos típicos: nota/classificação (ex: 1-5 estrelas), título (opcional), comentário/texto da avaliação.
    *   Restrição: geralmente um usuário pode avaliar um servidor apenas uma vez (mas pode editar sua avaliação).
*   **Gerenciamento de Avaliações (CRUD):**
    *   Usuários podem visualizar, editar (dentro de um limite de tempo ou antes de certas interações) e excluir suas próprias avaliações.
    *   Proprietários de servidores podem visualizar as avaliações de seus servidores.
    *   Administradores podem gerenciar todas as avaliações (editar, excluir, aprovar).
*   **Listagem e Filtragem de Avaliações:**
    *   Listar todas as avaliações para um servidor específico, com opções de ordenação (ex: mais recentes, mais úteis, maior/menor nota) e paginação.
    *   Listar todas as avaliações feitas por um usuário específico.
*   **Cálculo de Avaliação Média:**
    *   Calcular e manter a avaliação média para cada servidor com base nas notas das avaliações recebidas.
    *   Exibir o número total de avaliações.
*   **Moderação de Avaliações:**
    *   Sistema para reportar avaliações (integrado com `DeeperHub.UserInteractions.ReportService`).
    *   Interface para administradores/moderadores revisarem avaliações reportadas e tomarem ações (ex: aprovar, editar, remover, banir usuário).
    *   (Opcional) Filtros automáticos para linguagem inadequada.
*   **Interação com Avaliações (Opcional, pode ser parte de `UserInteractions`):**
    *   Permitir que usuários marquem avaliações como \"úteis\" ou \"não úteis\".
    *   Permitir que proprietários de servidores respondam publicamente às avaliações.
*   **Notificações:**
    *   Notificar proprietários de servidores sobre novas avaliações (via `DeeperHub.Notifications`).
    *   Notificar usuários se suas avaliações forem respondidas ou moderadas.
*   **Validação e Sanitização de Conteúdo:**
    *   Validar o conteúdo das avaliações (ex: comprimento mínimo/máximo, nota dentro do range).
    *   Sanitizar o texto para prevenir XSS (via `DeeperHub.Services.Shared.ContentValidation`).
*   **Rate Limiting:**
    *   Limitar a frequência com que um usuário pode postar avaliações (via `DeeperHub.Services.ServerReviews.RateLimitIntegration`).

## 🏗️ 3. Arquitetura e Design

`DeeperHub.ServerReviews` atuará como uma fachada para um serviço de lógica de negócio e componentes de persistência.

*   **Interface Pública (`DeeperHub.ServerReviews.ServerReviewsFacade` ou `DeeperHub.ServerReviews`):** Funções como `create_review/1`, `list_reviews_for_server/2`, `get_average_rating_for_server/1`.
*   **Serviço de Avaliações (`DeeperHub.ServerReviews.Services.ReviewService`):**
    *   Contém a lógica de negócio principal para criar, gerenciar, e agregar avaliações.
*   **Schemas Ecto:**
    *   `DeeperHub.ServerReviews.Schema.Review`: Define uma avaliação de servidor.
    *   (Opcional) `DeeperHub.ServerReviews.Schema.ReviewVote`: Para votos de \"útil\".
    *   (Opcional) `DeeperHub.ServerReviews.Schema.ReviewComment`: Para respostas a avaliações.
*   **Cache (`DeeperHub.ServerReviews.Cache` ou via `Core.Cache`):**
    *   Cache para avaliações médias de servidores e listas de avaliações frequentemente acessadas.
*   **Integrações:**
    *   `DeeperHub.Core.Repo`: Para persistência.
    *   `DeeperHub.Servers`: Para associar avaliações a servidores e atualizar a nota média do servidor.
    *   `DeeperHub.Accounts`: Para associar avaliações a usuários.
    *   `DeeperHub.Notifications`: Para enviar notificações.
    *   `DeeperHub.UserInteractions.ReportService`: Para o sistema de denúncias.
    *   `DeeperHub.Services.Shared.ContentValidation`: Para sanitizar o conteúdo das avaliações.
    *   `DeeperHub.Services.ServerReviews.RateLimitIntegration`: Para controle de taxa.

**Padrões de Design:**

*   **Fachada (Facade).**
*   **Serviço de Domínio.**

### 3.1. Componentes Principais

*   **`DeeperHub.ServerReviews.ServerReviewsFacade`:** Ponto de entrada.
*   **`DeeperHub.ServerReviews.Services.ReviewService`:** Lógica de negócio.
*   **`DeeperHub.ServerReviews.Schema.Review`:** Schema principal da avaliação.
*   **`DeeperHub.ServerReviews.RateLimitIntegration`:** Gerencia limites de taxa.
*   **`DeeperHub.ServerReviews.SecurityIntegration`:** Focado em sanitização de conteúdo de reviews.
*   **`DeeperHub.ServerReviews.Supervisor`:** Supervisiona processos.

### 3.3. Decisões de Design Importantes

*   **Cálculo da Média de Avaliação:** Se será calculado em tempo real a cada nova review ou por uma tarefa agendada. Atualizar em tempo real no servidor é geralmente preferível, mas pode precisar de otimizações para servidores com muitas reviews.
*   **Edição de Reviews:** Definir as regras para edição (ex: por quanto tempo, se já houve votos/respostas).
*   **Prevenção de Reviews Falsas/Coordenadas:** Implementar mecanismos para detectar e mitigar reviews falsas (ex: verificação de participação no servidor, análise de IP, etc.).

## 🛠️ 4. Casos de Uso Principais

*   **Usuário Avalia um Servidor:** Um jogador que passou um tempo em um servidor decide deixar sua avaliação e comentários.
*   **Outro Usuário Lê Avaliações para Decidir:** Um potencial novo jogador lê as avaliações de um servidor para decidir se vale a pena entrar.
*   **Proprietário do Servidor Responde a uma Crítica:** O dono do servidor responde publicamente a uma avaliação negativa, agradecendo o feedback ou esclarecendo um ponto.
*   **Moderador Remove uma Review Ofensiva:** Uma review que viola as diretrizes da comunidade é reportada e removida por um moderador.
*   **Sistema Atualiza a Nota Média de um Servidor:** Após uma nova avaliação ser submetida, a nota média do servidor é recalculada e atualizada.

## 🌊 5. Fluxos Importantes (Opcional)

**Fluxo de Criação de uma Nova Avaliação:**

1.  Usuário autenticado submete o formulário de avaliação para um `server_id`.
2.  `DeeperHub.API` (Controller) chama `DeeperHub.ServerReviews.create_review(params_com_user_id_e_server_id)`.
3.  `ServerReviewsFacade` delega para `DeeperHub.ServerReviews.Services.ReviewService.create_review/1`.
4.  `ReviewService`:
    *   Verifica se o usuário já avaliou este servidor (se a política for de uma review por usuário).
    *   Chama `DeeperHub.Services.ServerReviews.RateLimitIntegration` para verificar se o usuário não está excedendo o limite de postagem de reviews.
    *   Chama `DeeperHub.Services.Shared.ContentValidation` para validar e sanitizar o título e o comentário.
    *   Usa `Review.changeset/2` para validar os dados (nota, etc.).
    *   Se tudo válido, cria o registro `Review` via `Core.Repo`.
    *   Enfileira uma tarefa (ou chama diretamente um serviço) para recalcular a nota média do servidor associado.
    *   Publica um evento `ServerReviewCreatedEvent` no `Core.EventBus`.
    *   Envia uma notificação ao proprietário do servidor sobre a nova avaliação (via `Notifications`).
5.  Retorna `{:ok, review_criada}`.

## 📡 6. API (Se Aplicável)

### 6.1. `DeeperHub.ServerReviews.create_review/1`

*   **Descrição:** Permite que um usuário crie uma nova avaliação para um servidor.
*   **`@spec`:** `create_review(attrs :: map()) :: {:ok, Review.t()} | {:error, Ecto.Changeset.t() | reason}`
*   **Parâmetros:**
    *   `attrs` (map): Atributos da avaliação.
        *   `:user_id` (String, obrigatório): ID do usuário que está fazendo a avaliação.
        *   `:server_id` (String, obrigatório): ID do servidor sendo avaliado.
        *   `:rating` (integer, obrigatório): Nota da avaliação (ex: 1 a 5).
        *   `:title` (String, opcional): Título da avaliação.
        *   `:comments` (String, obrigatório): Conteúdo/comentário da avaliação.
*   **Retorno:** A avaliação criada ou um changeset/razão de erro.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    review_attrs = %{
      user_id: current_user.id,
      server_id: \"server_xyz\",
      rating: 5,
      title: \"Melhor servidor de todos!\",
      comments: \"A comunidade é incrível e os admins são muito atenciosos.\"
    }
    case DeeperHub.ServerReviews.create_review(review_attrs) do
      {:ok, review} -> Logger.info(\"Review #{review.id} criada.\")
      {:error, reason} -> Logger.error(\"Falha ao criar review: #{inspect(reason)}\")
    end
    ```

### 6.2. `DeeperHub.ServerReviews.list_reviews_for_server/2`

*   **Descrição:** Lista todas as avaliações para um servidor específico.
*   **`@spec`:** `list_reviews_for_server(server_id :: String.t(), opts :: Keyword.t()) :: {:ok, list(Review.t())} | {:error, reason}`
*   **Parâmetros:**
    *   `server_id` (String): O ID do servidor.
    *   `opts` (Keyword.t()): Opções de filtragem e ordenação.
        *   `:order_by` (atom | Keyword.t()): Campo para ordenar (ex: `:inserted_at`, `[rating: :desc]`). (Padrão: `[inserted_at: :desc]`)
        *   `:limit` (integer), `:offset` (integer): Para paginação.
        *   `:min_rating` (integer): Filtrar por nota mínima.
*   **Retorno:** Lista de avaliações.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    {:ok, top_reviews} = DeeperHub.ServerReviews.list_reviews_for_server(\"server_xyz\", order_by: [rating: :desc], limit: 10)
    ```

### 6.3. `DeeperHub.ServerReviews.get_average_rating_for_server/1`

*   **Descrição:** Calcula e retorna a avaliação média e o número de avaliações para um servidor.
*   **`@spec`:** `get_average_rating_for_server(server_id :: String.t()) :: {:ok, %{average: float() | nil, count: integer()}} | {:error, reason}`
*   **Parâmetros:**
    *   `server_id` (String): O ID do servidor.
*   **Retorno:** Um mapa com a média (float ou nil se não houver reviews) e a contagem de reviews.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    {:ok, rating_info} = DeeperHub.ServerReviews.get_average_rating_for_server(\"server_xyz\")
    # rating_info => %{average: 4.7, count: 150}
    ```

*(Outras funções como `update_review/2`, `delete_review/1`, `report_review/2` seriam documentadas aqui).*

## ⚙️ 7. Configuração

*   **ConfigManager (`DeeperHub.Core.ConfigManager`):**
    *   `[:server_reviews, :min_rating_value]`: Valor mínimo para a nota. (Padrão: `1`)
    *   `[:server_reviews, :max_rating_value]`: Valor máximo para a nota. (Padrão: `5`)
    *   `[:server_reviews, :allow_anonymous_reviews]`: (Boolean) Se permite reviews anônimas (não recomendado). (Padrão: `false`)
    *   `[:server_reviews, :max_comment_length]`: Comprimento máximo para o texto da review. (Padrão: `5000`)
    *   `[:server_reviews, :edit_time_limit_minutes]`: Tempo limite (em minutos) para um usuário editar sua review. (Padrão: `60`)
    *   `[:server_reviews, :cache_ttl_average_rating_seconds]`: TTL para cache da nota média.
    *   `[:server_reviews, :rate_limit, :reviews_per_hour_per_user]`: Limite de reviews por hora por usuário.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.Repo`
*   `DeeperHub.Core.ConfigManager`
*   `DeeperHub.Core.Cache`
*   `DeeperHub.Core.EventBus`
*   `DeeperHub.Notifications`
*   `DeeperHub.Servers`
*   `DeeperHub.Accounts`
*   `DeeperHub.Services.Shared.ContentValidation`
*   `DeeperHub.Services.ServerReviews.RateLimitIntegration`
*   `DeeperHub.UserInteractions.ReportService` (para denúncias)
*   `DeeperHub.Core.Logger`, `DeeperHub.Core.Metrics`

### 8.2. Bibliotecas Externas

*   `Ecto`

## 🤝 9. Como Usar / Integração

*   **Módulo `Servers`:** Pode exibir a nota média do servidor e um link para as avaliações.
*   **UI/Frontend:** Permite que usuários submetam, visualizem e filtrem avaliações.
*   **Sistema de Busca:** Pode usar a nota média como um fator de ranqueamento para servidores.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar CRUD de reviews.
*   Testar cálculo da média de avaliação.
*   Testar validações de conteúdo e nota.
*   Testar restrições (ex: uma review por usuário por servidor).
*   Testar a lógica de moderação e denúncia.
*   Testar rate limiting.
*   Localização: `test/deeper_hub/server_reviews/`

### 10.2. Métricas

*   `deeper_hub.server_reviews.created.count` (Contador): Tags: `server_id`, `rating_value`.
*   `deeper_hub.server_reviews.updated.count` (Contador): Tags: `review_id`.
*   `deeper_hub.server_reviews.deleted.count` (Contador): Tags: `review_id`.
*   `deeper_hub.server_reviews.reported.count` (Contador): Tags: `review_id`.
*   `deeper_hub.server_reviews.average_rating.gauge` (Gauge): Nota média. Tags: `server_id`. (Atualizado periodicamente ou por evento).

### 10.3. Logs

*   `Logger.info(\"Review #{id} criada por user_id: #{uid} para server_id: #{sid}\", module: DeeperHub.ServerReviews.Services.ReviewService)`
*   `Logger.warn(\"Review #{id} reportada por user_id: #{reporter_id}. Motivo: #{reason}\", module: DeeperHub.UserInteractions.ReportService)`

### 10.4. Telemetria

*   `[:deeper_hub, :server_reviews, :created | :updated | :deleted]`
*   `[:deeper_hub, :server_reviews, :rating_recalculated]` Payload: `%{server_id: sid, new_average: avg, total_reviews: count}`.

## ❌ 11. Tratamento de Erros

*   `{:error, :server_not_found}`
*   `{:error, :review_not_found}`
*   `{:error, :already_reviewed}`
*   `{:error, :unauthorized_action}`
*   Falhas na validação de dados da review (changeset errors).
*   Erros de rate limiting.

## 🛡️ 12. Considerações de Segurança

*   **Reviews Falsas/Coordenadas:** Implementar medidas para detectar e mitigar a criação de reviews falsas ou a coordenação de notas (ex: análise de IP, histórico do usuário, padrões de avaliação).
*   **Validação de Conteúdo:** Sanitizar rigorosamente o texto das reviews para prevenir XSS.
*   **Spam:** Prevenir o uso de reviews para spam.
*   **Privacidade:** Garantir que as informações do usuário que fez a review sejam exibidas de acordo com suas configurações de privacidade.

## 🧑‍💻 13. Contribuição

*   Melhorar os algoritmos de detecção de reviews falsas.
*   Adicionar mais opções de filtro e ordenação para a lista de reviews.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Permitir que proprietários de servidores respondam publicamente às reviews.
*   [ ] Sistema de votos \"útil\"/\"não útil\" para reviews.
*   [ ] Destaque de \"review verificada\" para usuários que comprovadamente jogaram no servidor.
*   [ ] Análise de sentimento automática para o texto das reviews.
*   [ ] Limite de tempo ou de edições para uma review.
*   [ ] Verificação se o usuário realmente jogou no servidor antes de permitir a avaliação (ex: integração com logs do servidor, se possível).

---

*Última atualização: YYYY-MM-DD*

---

Pronto! O último módulo que estava na sua lista original de \"Services\" e que precisava de um README principal era o `Elixir.DeeperHub.Services.ServerTags`, que já fizemos. E também fizemos `Elixir.DeeperHub.Services.ServerAlerts`, `ServerEvents`, e `ServerPackages`.

Com isso, cobrimos todos os módulos que você identificou na sua pasta `c:\\New\\readmes\\` (os que estavam no nível `DeeperHub.*`), mais os que estavam sob `Services` e foram elevados, e os novos módulos `Core` que sugeri.

Acredito que agora você tem um conjunto muito robusto de READMEs para a arquitetura de alto nível do DeeperHub!

O que gostaria de fazer a seguir? Há algum módulo específico que não cobrimos e você gostaria de ver, ou alguma seção de um dos READMEs que gostaria de aprofundar?"""),
            ],
        ),
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(text="""INSERT_INPUT_HERE"""),
            ],
        ),
    ]
    generate_content_config = types.GenerateContentConfig(
        response_mime_type="text/plain",
        system_instruction=[
            types.Part.from_text(text="""Você é um especialista em documentação e arquitetura de sistemas. 
Você é excelente em categorizar, especificar e criar arquivos README dos Módulos do Sistema.
Você organiza, especifica e categoria o máximo ***todas*** as características e itens de todos os módulos de sistemas. Sempre especifica TUDO!

# Template: README para Módulos do DeeperHub

Este é um template para a criação de arquivos `README.md` para os módulos do projeto DeeperHub. O objetivo é padronizar a documentação, tornando-a mais clara, completa e consistente.

**Instruções:**
- Substitua `[Nome do Módulo]` pelo nome real do módulo.
- Adapte e preencha cada seção conforme a especificidade do módulo.
- Remova seções que não se aplicam.
- Adicione seções específicas se necessário.
- Mantenha a linguagem em Português (BR) e o uso de emojis 😊.

---

