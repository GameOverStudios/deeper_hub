# Módulo: `DeeperHub.ServerAdvertisements` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.ServerAdvertisements`

O módulo `DeeperHub.ServerAdvertisements` é responsável por gerenciar **anúncios de servidores** dentro da plataforma DeeperHub. Ele permite que proprietários de servidores criem e paguem (se aplicável) por anúncios para destacar seus servidores, aumentando sua visibilidade para os jogadores.

Este módulo lida com:
*   A criação e configuração de campanhas de anúncios.
*   A exibição de anúncios em locais designados da plataforma.
*   O rastreamento de desempenho dos anúncios (visualizações, cliques).
*   A gestão do ciclo de vida dos anúncios (agendamento, expiração).

O objetivo é fornecer uma ferramenta para proprietários de servidores promoverem suas comunidades e, potencialmente, gerar receita para a plataforma. 😊

*(Nota: Na documentação original, este era `DeeperHub.Services.ServerAdvertisements`. Será tratado como `DeeperHub.ServerAdvertisements`.)*

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Gerenciamento de Definições de Anúncios (`create_advertisement_campaign/1`, `update_advertisement_campaign/2`):**
    *   Permitir que proprietários de servidores (ou administradores) criem campanhas de anúncios.
    *   Definição inclui: servidor a ser anunciado, título/texto do anúncio, imagem/banner, URL de destino (página do servidor), segmentação (opcional: tipo de jogo, região), orçamento/duração da campanha.
*   **Agendamento e Exibição de Anúncios:**
    *   Agendar o início e o fim da exibição de um anúncio.
    *   Lógica para selecionar quais anúncios exibir em um determinado momento/local (ex: rotação, leilão de lances se for um sistema mais complexo).
    *   Garantir que apenas anúncios ativos e aprovados (se houver moderação) sejam exibidos.
*   **Rastreamento de Performance (`track_advertisement_impression/1`, `track_advertisement_click/1`):**
    *   Registrar o número de vezes que um anúncio foi visualizado (impressões).
    *   Registrar o número de vezes que um anúncio foi clicado.
*   **Relatórios de Performance:**
    *   Fornecer aos anunciantes estatísticas sobre o desempenho de suas campanhas (impressões, cliques, CTR).
*   **Moderação de Anúncios (Opcional):**
    *   Fluxo para aprovação de novos anúncios por administradores para garantir conformidade com as diretrizes da plataforma.
*   **Integração com Pagamentos (Se anúncios forem pagos):**
    *   Integrar com um sistema de pagamento para cobrar pelas campanhas de anúncio.
*   **Listagem de Anúncios:**
    *   `list_active_advertisements/1`: Para a plataforma buscar anúncios a serem exibidos.
    *   `list_advertisements_by_server/2`: Para proprietários verem seus anúncios.
*   **Observabilidade e Auditoria:**
    *   Logar e metrificar a criação e o desempenho dos anúncios.
    *   Auditar a criação e modificação de campanhas.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.ServerAdvertisements` (Fachada Pública):**
    *   Ponto de entrada para gerenciamento e consulta de anúncios.
    *   Delega para o `ServerAdvertisementsService`.
2.  **`DeeperHub.ServerAdvertisements.Services.ServerAdvertisementsService` (ou `DefaultServerAdvertisementsService`):**
    *   **Responsabilidade:** Orquestra a lógica de negócio.
    *   **Interações:**
        *   `DeeperHub.Core.Repo`: Para CRUD com `AdvertisementSchema`.
        *   `DeeperHub.Servers`: Para validar `server_id`.
        *   `DeeperHub.Accounts`: Para `user_id` do criador.
        *   `DeeperHub.Auth`/`RBAC`: Para permissões de gerenciamento.
        *   `DeeperHub.Core.EventBus`: Para eventos.
        *   `DeeperHub.Core.Cache`: Para cachear anúncios ativos.
        *   (Opcional) `DeeperHub.Payments`: Se as campanhas forem pagas.
3.  **`DeeperHub.ServerAdvertisements.Schemas.AdvertisementSchema` (ex-`Advertisement`):**
    *   Campos: `id`, `server_id`, `user_id` (criador), `title`, `description`, `image_url`, `target_url`, `start_date`, `end_date`, `status` (`:pending_approval`, `:active`, `:inactive`, `:expired`, `:rejected`), `budget` (opcional), `impressions_count`, `clicks_count`.
4.  **`DeeperHub.ServerAdvertisements.AdSelectionLogic` (Módulo Funcional, Nova Sugestão):**
    *   **Responsabilidade:** Se a lógica de qual anúncio exibir for complexa (ex: baseada em lances, segmentação, rotação), este módulo conteria essa lógica. Para casos simples, pode estar no `ServerAdvertisementsService`.
5.  **Workers (Opcional):**
    *   `AdvertisementStatusUpdateWorker`: Para atualizar o status de anúncios (ex: de `:active` para `:expired`) periodicamente.
    *   `AdvertisementStatsAggregationWorker`: Para agregar estatísticas de performance.

### 3.2. Estrutura de Diretórios (Proposta)

```
lib/deeper_hub/server_advertisements/
├── server_advertisements.ex          # Fachada Pública
│
├── services/
│   └── server_advertisements_service.ex # Serviço principal
│
├── schemas/
│   └── advertisement_schema.ex
│
├── storage.ex                        # (Opcional)
├── ad_selection_logic.ex             # (Opcional, Nova Sugestão)
│
├── workers/                          # Opcional
│   ├── advertisement_status_update_worker.ex
│   └── advertisement_stats_aggregation_worker.ex
│
├── cached_adapter.ex                 # (Opcional, da documentação original)
├── supervisor.ex
└── telemetry.ex
```

### 3.3. Decisões de Design Importantes

*   **Simplicidade vs. Complexidade do Sistema de Anúncios:** Decidir se será um sistema simples de \"destaque\" ou um sistema mais complexo com lances, segmentação e otimização de performance.
*   **Moderação:** Se os anúncios podem conter conteúdo customizado, um fluxo de moderação é essencial.
*   **Rastreamento de Performance:** O rastreamento de impressões e cliques precisa ser eficiente e não intrusivo.

## 🛠️ 4. Casos de Uso Principais

*   **Proprietário de Servidor Cria uma Campanha de Anúncio:**
    *   Na UI, seleciona o servidor, define título, descrição, imagem, orçamento e duração.
    *   API chama `ServerAdvertisements.create_advertisement_campaign(user_id, attrs)`.
    *   Anúncio é salvo com status `:pending_approval` ou `:active` (se não houver moderação).
*   **Plataforma Exibe um Anúncio:**
    *   Uma seção da UI (ex: sidebar, topo da lista de servidores) precisa exibir um anúncio.
    *   Chama `ServerAdvertisements.get_advertisement_to_display(%{placement_id: \"sidebar\", user_context: ...})`.
    *   `AdSelectionLogic` escolhe um anúncio ativo.
    *   `ServerAdvertisements.track_advertisement_impression(selected_ad.id)` é chamado.
*   **Usuário Clica em um Anúncio:**
    *   O link do anúncio redireciona através de um endpoint de rastreamento do DeeperHub.
    *   Esse endpoint chama `ServerAdvertisements.track_advertisement_click(ad_id)` e então redireciona para a `target_url` do anúncio.

## 🌊 5. Fluxos Importantes

### Fluxo de Seleção e Exibição de Anúncio

1.  **Solicitação de UI:** A interface do DeeperHub precisa de um anúncio para um slot específico.
2.  Chama `DeeperHub.ServerAdvertisements.get_advertisement_to_display(criteria)`.
3.  **`ServerAdvertisementsService` (ou `AdSelectionLogic`):**
    *   Busca anúncios ativos que correspondam aos critérios (ex: segmentação, não exibido recentemente para este usuário).
    *   Aplica lógica de rotação ou priorização.
    *   Seleciona um anúncio.
    *   Se nenhum anúncio for selecionado, retorna `nil`.
4.  **`ServerAdvertisementsService`:**
    *   Se um anúncio foi selecionado, chama `track_advertisement_impression(selected_ad.id)` (pode ser assíncrono).
    *   Retorna os dados do anúncio para a UI.
5.  **UI:** Renderiza o anúncio.

## 📡 6. API (Funções Públicas da Fachada `DeeperHub.ServerAdvertisements`)

*(Baseado nas responsabilidades e na documentação original para `Advertisement`)*

### 6.1. Gerenciamento de Campanhas (Proprietário/Admin)

*   **`DeeperHub.ServerAdvertisements.create_advertisement_campaign(creator_user_id :: String.t(), attrs :: map()) :: {:ok, Advertisement.t()} | {:error, Ecto.Changeset.t()}`**
    *   `attrs`: `%{server_id: String.t(), title: String.t(), description: String.t(), image_url: String.t(), target_url: String.t(), start_date: Date.t(), end_date: Date.t(), budget: Decimal.t() | nil, bid_amount: Decimal.t() | nil}`.
*   **`DeeperHub.ServerAdvertisements.update_advertisement_campaign(advertisement_id :: String.t(), attrs :: map(), current_user_id :: String.t()) :: {:ok, Advertisement.t()} | {:error, Ecto.Changeset.t() | :unauthorized}`**
*   **`DeeperHub.ServerAdvertisements.delete_advertisement_campaign(advertisement_id :: String.t(), current_user_id :: String.t()) :: :ok | {:error, :unauthorized | :not_found}`**
*   **`DeeperHub.ServerAdvertisements.list_my_advertisements(user_id :: String.t(), filters :: map(), opts :: keyword()) :: {:ok, list(Advertisement.t()), Pagination.t()}`**
    *   `filters`: `:status`.

### 6.2. Exibição e Rastreamento

*   **`DeeperHub.ServerAdvertisements.get_advertisement_to_display(criteria :: map()) :: {:ok, Advertisement.t() | nil}`**
    *   `criteria`: `%{placement_id: String.t(), user_targeting_info: map() | nil}`.
*   **`DeeperHub.ServerAdvertisements.track_advertisement_impression(advertisement_id :: String.t(), viewer_context :: map()) :: :ok`**
    *   `viewer_context`: `%{user_id: String.t() | nil, ip_address: String.t()}`.
*   **`DeeperHub.ServerAdvertisements.track_advertisement_click(advertisement_id :: String.t(), clicker_context :: map()) :: {:ok, %{target_url: String.t()}}`**

### 6.3. Moderação (Admin)

*   **`DeeperHub.ServerAdvertisements.list_pending_approval_advertisements(opts :: keyword()) :: {:ok, list(Advertisement.t()), Pagination.t()}`**
*   **`DeeperHub.ServerAdvertisements.approve_advertisement(advertisement_id :: String.t(), admin_user_id :: String.t()) :: {:ok, Advertisement.t()}`**
*   **`DeeperHub.ServerAdvertisements.reject_advertisement(advertisement_id :: String.t(), reason :: String.t(), admin_user_id :: String.t()) :: {:ok, Advertisement.t()}`**

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager`:

*   **`[:server_advertisements, :enabled]`** (Boolean).
*   **`[:server_advertisements, :requires_moderation]`** (Boolean): Se novos anúncios precisam de aprovação.
*   **`[:server_advertisements, :max_active_ads_per_placement]`** (Integer).
*   **`[:server_advertisements, :default_ad_duration_days]`** (Integer).
*   **`[:server_advertisements, :impression_counting_method]`** (Atom): `:simple_counter` ou `:unique_user_per_day`.
*   **`[:server_advertisements, :min_bid_amount]`** (Decimal, se houver sistema de lances).
*   **`[:server_advertisements, :cache, :active_ads_ttl_seconds]`** (Integer).

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.*`.
*   `DeeperHub.Servers`: Para `server_id`.
*   `DeeperHub.Accounts`: Para `user_id`.
*   `DeeperHub.Auth`/`RBAC`: Para permissões.
*   `DeeperHub.Notifications`: Para notificar sobre status de anúncios.
*   `DeeperHub.Payments` (Opcional): Se os anúncios forem pagos.
*   `DeeperHub.Audit`.

### 8.2. Bibliotecas Externas

*   `Ecto`.

## 🤝 9. Como Usar / Integração

*   **Frontend/UI da Plataforma:** Em locais designados (sidebar, header, entre listagens), chama `get_advertisement_to_display` para buscar e renderizar um anúncio.
*   **Painel do Proprietário do Servidor:** Interface para criar e gerenciar campanhas de anúncios.
*   **Painel de Administração:** Interface para moderar anúncios e ver estatísticas globais.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar CRUD de campanhas de anúncio.
*   Testar a lógica de seleção de anúncios (`AdSelectionLogic`).
*   Testar o rastreamento de impressões e cliques.
*   Testar o fluxo de moderação.
*   Testar o agendamento e expiração de anúncios.
*   Localização: `test/deeper_hub/server_advertisements/`.

### 10.2. Métricas

*   `deeper_hub.server_advertisements.campaigns.created.count`
*   `deeper_hub.server_advertisements.impressions.count` (tags: `advertisement_id`, `placement_id`)
*   `deeper_hub.server_advertisements.clicks.count` (tags: `advertisement_id`, `placement_id`)
*   `deeper_hub.server_advertisements.active_ads.gauge` (tags: `placement_id`)
*   `deeper_hub.server_advertisements.moderation.status_changed.count` (tags: `new_status`)

### 10.3. Logs

*   **Nível INFO:** Nova campanha criada, anúncio exibido, clique registrado. Status de anúncio alterado.
*   **Nível WARNING:** Orçamento da campanha esgotado. Anúncio rejeitado na moderação.
*   **Nível ERROR:** Falha ao processar pagamento da campanha.

### 10.4. Telemetria

*   `[:deeper_hub, :server_advertisements, :campaign, :created | :updated | :status_changed]`
*   `[:deeper_hub, :server_advertisements, :ad, :impression]`
*   `[:deeper_hub, :server_advertisements, :ad, :click]`

## ❌ 11. Tratamento de Erros

*   Falhas no rastreamento de impressões/cliques não devem quebrar a exibição da página principal.
*   Erros na seleção de anúncios devem resultar em um slot de anúncio vazio ou um anúncio padrão, não um erro na página.

## 🛡️ 12. Considerações de Segurança

*   **Conteúdo do Anúncio:** Se os anúncios permitem HTML customizado ou scripts, eles são um vetor de XSS significativo. Idealmente, os anúncios são baseados em templates predefinidos com campos de texto/imagem limitados, e todo o conteúdo é rigorosamente sanitizado.
*   **URLs de Destino:** Validar e, possivelmente, verificar `target_url`s para evitar redirecionamentos para sites maliciosos.
*   **Fraude de Cliques/Impressões:** Se o sistema de anúncios envolver pagamento por clique/impressão, mecanismos para detectar e prevenir fraude são necessários (integrando com `FraudDetection`).

## 🧑‍💻 13. Contribuição

*   Novos placements de anúncios devem ser coordenados com a equipe de UI/UX.
*   A lógica de `AdSelectionLogic` pode se tornar complexa e deve ser bem testada.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar um sistema de lances (bidding) para a exibição de anúncios.
*   [ ] Adicionar segmentação de audiência mais avançada (geográfica, por interesse, por comportamento do usuário).
*   [ ] Testes A/B para diferentes criativos de anúncio.
*   [ ] Limitar a frequência com que um mesmo usuário vê o mesmo anúncio (frequency capping).
*   [ ] Integração com redes de anúncios externas para preencher inventário não vendido (ad network mediation).

---

*Última atualização: 2025-05-12*

---

Este módulo de anúncios pode variar muito em complexidade dependendo dos requisitos!

Próximo? Que tal `DeeperHub.ServerEvents` ou `DeeperHub.ServerUpdateMessages` para continuar com os módulos relacionados a `Servers`?"""),
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
                types.Part.from_text(text="""Ok! Vamos prosseguir com `DeeperHub.ServerEvents`. Este módulo é focado em permitir que os proprietários de servidores criem e gerenciem eventos para suas comunidades.

---

