# Módulo: `DeeperHub.ServerAdvertisements` 📢

## 📜 1. Visão Geral do Módulo `DeeperHub.ServerAdvertisements`

O módulo `DeeperHub.ServerAdvertisements` é responsável pelo sistema de anúncios de servidores dentro da plataforma DeeperHub. Ele permite que proprietários de servidores ou administradores criem e gerenciem campanhas de anúncios para promover seus servidores, aumentando sua visibilidade para os usuários. O sistema lida com a definição, agendamento, exibição e métricas básicas de anúncios. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Criação e Gerenciamento de Anúncios:**
    *   CRUD para Anúncios (`Advertisement`): título, descrição, imagem/banner, link de destino (servidor), período de veiculação (data de início e fim).
    *   Definição de tipo de anúncio (ex: banner destaque, listagem patrocinada).
    *   Associação do anúncio a um servidor (`server_id`).
*   **Agendamento de Anúncios:**
    *   Permitir que anúncios sejam agendados para exibição em datas futuras.
    *   Gerenciar o ciclo de vida de um anúncio (ex: pendente, ativo, expirado, cancelado).
*   **Exibição de Anúncios:**
    *   Fornecer uma API para que outras partes do sistema (ex: UI, sistema de busca) possam requisitar anúncios ativos para exibição.
    *   Lógica para selecionar quais anúncios exibir com base em critérios (ex: aleatório, rotativo, baseado em lances - se for um sistema mais complexo).
*   **Rastreamento de Métricas Básicas:**
    *   Contagem de impressões (quantas vezes um anúncio foi exibido).
    *   Contagem de cliques (quantas vezes um anúncio foi clicado).
*   **Controle de Ativação:**
    *   Habilitar ou desabilitar anúncios.
*   **Pagamentos/Orçamentos (Opcional, se for um sistema pago):**
    *   Integração com um sistema de pagamento para anúncios pagos.
    *   Gerenciamento de orçamento de campanha.
*   **Administração de Anúncios:**
    *   Interface para administradores da plataforma aprovarem/rejeitarem anúncios.
    *   Interface para proprietários de servidores gerenciarem seus próprios anúncios.

## 🏗️ 3. Arquitetura e Design

`DeeperHub.ServerAdvertisements` atuará como uma fachada para um serviço de lógica de negócio e componentes de persistência.

*   **Interface Pública (`DeeperHub.ServerAdvertisements.ServerAdvertisementsFacade` ou `DeeperHub.ServerAdvertisements`):** Funções como `create_advertisement/1`, `list_active_advertisements/1`, `record_impression/1`.
*   **Serviço de Anúncios (`DeeperHub.ServerAdvertisements.Services.AdvertisementService`):**
    *   Contém a lógica de negócio principal para gerenciar definições, agendamento, e métricas de anúncios.
*   **Schemas Ecto:**
    *   `DeeperHub.ServerAdvertisements.Schema.Advertisement`: Define um anúncio.
    *   (Opcional) `DeeperHub.ServerAdvertisements.Schema.AdvertisementImpressionLog`: Para logar impressões.
    *   (Opcional) `DeeperHub.ServerAdvertisements.Schema.AdvertisementClickLog`: Para logar cliques.
*   **Cache (`DeeperHub.ServerAdvertisements.Cache` ou via `Core.Cache`):**
    *   Cache para anúncios ativos frequentemente requisitados para exibição.
*   **Workers (via `Core.BackgroundTaskManager`):**
    *   Worker para atualizar o status de anúncios (ex: de pendente para ativo, de ativo para expirado).
    *   Worker para agregar métricas de impressões/cliques.
*   **Integrações:**
    *   `DeeperHub.Core.Repo`: Para persistência.
    *   `DeeperHub.Servers`: Para associar anúncios a servidores.
    *   `DeeperHub.Accounts`: Para associar anúncios a usuários proprietários.
    *   `DeeperHub.Notifications`: Para notificar sobre status de anúncios (ex: aprovado, expirando).
    *   `DeeperHub.Core.Payment` (Se aplicável): Para processar pagamentos de anúncios.

**Padrões de Design:**

*   **Fachada (Facade).**
*   **Serviço de Domínio.**

### 3.1. Componentes Principais

*   **`DeeperHub.ServerAdvertisements.ServerAdvertisementsFacade`:** Ponto de entrada.
*   **`DeeperHub.ServerAdvertisements.Services.AdvertisementService`:** Lógica de negócio.
*   **`DeeperHub.ServerAdvertisements.Schema.Advertisement`:** Schema do anúncio.
*   **`DeeperHub.ServerAdvertisements.Supervisor`:** Supervisiona processos.
*   **Workers (ex: `AdvertisementStatusWorker`, `AdMetricsAggregatorWorker`).**

### 3.3. Decisões de Design Importantes

*   **Modelo de Monetização:** Se os anúncios são pagos, gratuitos, ou um misto. Isso impacta a complexidade.
*   **Algoritmo de Exibição:** Como os anúncios ativos são selecionados para exibição (simples rotação, baseado em performance, lances, etc.).
*   **Rastreamento de Métricas:** Nível de detalhe para rastreamento de impressões e cliques.

## 🛠️ 4. Casos de Uso Principais

*   **Proprietário de Servidor Cria um Anúncio:** Um usuário dono de um servidor cria uma campanha para promover seu servidor por uma semana.
*   **Sistema Exibe Anúncios na Home Page:** A página inicial do DeeperHub busca e exibe alguns anúncios de servidores ativos.
*   **Usuário Clica em um Anúncio:** Um usuário clica em um anúncio e é redirecionado para a página do servidor; o clique é registrado.
*   **Administrador Aprova um Novo Anúncio:** Um administrador da plataforma revisa e aprova um anúncio submetido por um proprietário de servidor.
*   **Anúncio Expira Automaticamente:** Um worker verifica e muda o status de anúncios cujo período de veiculação terminou.

## 🌊 5. Fluxos Importantes (Opcional)

**Fluxo de Criação e Ativação de um Anúncio:**

1.  Proprietário do servidor submete dados do anúncio via API/UI.
2.  `DeeperHub.API` (Controller) chama `DeeperHub.ServerAdvertisements.create_advertisement(params)`.
3.  `AdvertisementService` valida os dados e cria um registro `Advertisement` com status `pending_approval` (ou `active` se não houver aprovação).
4.  (Se aprovação necessária) Notificação é enviada para administradores.
5.  Administrador aprova o anúncio. `AdvertisementService.approve_advertisement(ad_id)` é chamado.
6.  O status do anúncio muda para `scheduled` (se `start_date` for no futuro) ou `active` (se `start_date` for agora/passado e `end_date` no futuro).
7.  Um evento `AdvertisementActivatedEvent` é publicado.
8.  O `AdvertisementStatusWorker` periodicamente verifica anúncios `scheduled` e os ativa quando `start_date` é alcançada. Também desativa anúncios quando `end_date` é alcançada.

## 📡 6. API (Se Aplicável)

### 6.1. `DeeperHub.ServerAdvertisements.create_advertisement/1`

*   **Descrição:** Cria um novo anúncio de servidor.
*   **`@spec`:** `create_advertisement(attrs :: map()) :: {:ok, Advertisement.t()} | {:error, Ecto.Changeset.t() | reason}`
*   **Parâmetros:**
    *   `attrs` (map): Atributos do anúncio.
        *   `:user_id` (String, obrigatório): ID do usuário criando o anúncio.
        *   `:server_id` (String, obrigatório): ID do servidor sendo anunciado.
        *   `:ad_title` (String, obrigatório): Título do anúncio.
        *   `:ad_description` (String, opcional): Descrição do anúncio.
        *   `:image_url` (String, opcional): URL da imagem/banner.
        *   `:start_date` (Date.t() | DateTime.t(), obrigatório): Data de início da veiculação.
        *   `:end_date` (Date.t() | DateTime.t(), obrigatório): Data de término da veiculação.
        *   `:type` (atom, opcional): Tipo de anúncio (ex: `:banner`, `:sponsored_listing`).
*   **Retorno:** O anúncio criado ou um changeset com erros.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    ad_attrs = %{
      user_id: \"user_abc\",
      server_id: \"server_xyz\",
      ad_title: \"Super Servidor de RPG!\",
      start_date: ~D[2025-07-01],
      end_date: ~D[2025-07-07]
    }
    case DeeperHub.ServerAdvertisements.create_advertisement(ad_attrs) do
      {:ok, ad} -> Logger.info(\"Anúncio #{ad.id} criado.\")
      {:error, reason} -> Logger.error(\"Falha ao criar anúncio: #{inspect(reason)}\")
    end
    ```

### 6.2. `DeeperHub.ServerAdvertisements.list_active_advertisements/1`

*   **Descrição:** Lista anúncios que estão atualmente ativos e dentro de seu período de veiculação.
*   **`@spec`:** `list_active_advertisements(opts :: Keyword.t()) :: {:ok, list(Advertisement.t())} | {:error, reason}`
*   **Parâmetros:**
    *   `opts` (Keyword.t()): Opções de filtragem.
        *   `:limit` (integer): Número máximo de anúncios a retornar.
        *   `:type` (atom): Filtrar por tipo de anúncio.
        *   `:placement_location` (atom): Filtrar por local de exibição (ex: `:homepage`, `:search_results`).
*   **Retorno:** Lista de anúncios ativos.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    {:ok, banner_ads} = DeeperHub.ServerAdvertisements.list_active_advertisements(type: :banner, limit: 3)
    ```

*(Outras funções como `get_advertisement/1`, `update_advertisement/2`, `record_impression/1`, `record_click/1` seriam documentadas aqui).*

## ⚙️ 7. Configuração

*   **ConfigManager (`DeeperHub.Core.ConfigManager`):**
    *   `[:server_advertisements, :max_active_ads_per_server]`: Número máximo de anúncios ativos simultaneamente para um único servidor.
    *   `[:server_advertisements, :default_duration_days]`: Duração padrão de um anúncio se não especificado.
    *   `[:server_advertisements, :approval_required]`: (Boolean) Se novos anúncios requerem aprovação de um administrador. (Padrão: `true`)
    *   `[:server_advertisements, :worker, :status_check_interval_hours]`: Intervalo para o worker verificar e atualizar status de anúncios. (Padrão: `1`)
    *   `[:server_advertisements, :cache_ttl_active_ads_seconds]`: TTL para o cache de anúncios ativos.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.Repo`
*   `DeeperHub.Core.ConfigManager`
*   `DeeperHub.Core.EventBus`
*   `DeeperHub.Core.BackgroundTaskManager`
*   `DeeperHub.Notifications`
*   `DeeperHub.Servers`
*   `DeeperHub.Accounts`
*   `DeeperHub.Core.Logger`, `DeeperHub.Core.Metrics`

### 8.2. Bibliotecas Externas

*   `Ecto`

## 🤝 9. Como Usar / Integração

*   **Frontend/UI:** Exibe anúncios retornados por `list_active_advertisements/1` em locais designados.
*   **API de Gerenciamento:** Proprietários de servidor e administradores interagem com a API para criar e gerenciar anúncios.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar criação, atualização e exclusão de anúncios.
*   Testar a lógica de ativação e expiração de anúncios pelo worker.
*   Testar a listagem de anúncios ativos e a lógica de seleção (se complexa).
*   Testar o registro de impressões e cliques.
*   Localização: `test/deeper_hub/server_advertisements/`

### 10.2. Métricas

*   `deeper_hub.server_advertisements.created.count` (Contador): Tags: `type`.
*   `deeper_hub.server_advertisements.impression.count` (Contador): Tags: `advertisement_id`, `placement_location`.
*   `deeper_hub.server_advertisements.click.count` (Contador): Tags: `advertisement_id`, `placement_location`.
*   `deeper_hub.server_advertisements.active.gauge` (Gauge): Número de anúncios ativos.
*   `deeper_hub.server_advertisements.budget_spent.total` (Contador, se aplicável): Tags: `advertisement_id`.

### 10.3. Logs

*   `Logger.info(\"Anúncio #{id} criado para o servidor #{server_id}\", module: DeeperHub.ServerAdvertisements.Services.AdvertisementService)`
*   `Logger.info(\"Anúncio #{id} ativado/expirado.\", module: DeeperHub.ServerAdvertisements.Workers.AdvertisementStatusWorker)`

### 10.4. Telemetria

*   `[:deeper_hub, :server_advertisements, :created | :updated | :deleted]`
*   `[:deeper_hub, :server_advertisements, :impression]`
*   `[:deeper_hub, :server_advertisements, :click]`

## ❌ 11. Tratamento de Erros

*   `{:error, :max_ads_limit_reached}`
*   `{:error, :invalid_date_range}`
*   `{:error, :insufficient_budget}` (se aplicável)
*   Falhas na validação dos dados do anúncio.

## 🛡️ 12. Considerações de Segurança

*   **Conteúdo dos Anúncios:** Validar e, se necessário, moderar o conteúdo dos anúncios para prevenir links maliciosos, texto inadequado ou imagens impróprias.
*   **Redirecionamentos:** Garantir que os links de destino dos anúncios sejam seguros.
*   **Cliques Fraudulentos:** Se o sistema de anúncios for pago por clique, implementar mecanismos para detectar e mitigar cliques fraudulentos.

## 🧑‍💻 13. Contribuição

*   Novos tipos de anúncios ou estratégias de exibição podem ser adicionados estendendo o `AdvertisementService`.
*   A integração com sistemas de pagamento deve ser feita de forma segura e robusta.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar um sistema de lances (bidding) para posições de destaque de anúncios.
*   [ ] Adicionar segmentação de público para anúncios (ex: exibir para usuários interessados em \"RPG\").
*   [ ] Relatórios de performance detalhados para anunciantes.
*   [ ] Testes A/B para diferentes criativos de anúncio.
*   [ ] Limitar a frequência de exibição de um mesmo anúncio para um usuário.

---

*Última atualização: YYYY-MM-DD*

---

Próximo da lista é `DeeperHub.ServerEvents`. Vamos nessa?"""),
            ],
        ),
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(text="""vamos!!!! pode enviar/mostrar!!!!"""),
            ],
        ),
        types.Content(
            role="model",
            parts=[
                types.Part.from_text(text="""Com certeza! Vamos ao README do `DeeperHub.ServerEvents`.

---

