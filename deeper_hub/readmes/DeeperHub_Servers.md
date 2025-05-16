# Módulo: `Deeper_Hub.Servers` 🚀

## 📜 1. Visão Geral do Módulo `Deeper_Hub.Servers`

O módulo `Deeper_Hub.Servers` é o contexto de domínio central responsável por gerenciar todas as entidades \"Servidor\" dentro da plataforma Deeper_Hub. Isso inclui a criação, configuração, listagem, atualização e exclusão de servidores, bem como o gerenciamento de seus metadados associados, como status, tags, pacotes de assinatura, eventos, alertas, avaliações (reviews) e mensagens de atualização.

Este módulo serve como a principal interface para que usuários (proprietários de servidores e jogadores) e outros sistemas interajam com os dados e funcionalidades dos servidores listados na plataforma. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Gerenciamento CRUD de Servidores (`create_server/1`, `get_server/1`, `update_server/2`, `delete_server/1`):**
    *   Criação de novos registros de servidor com informações básicas (nome, descrição, endereço, porta, proprietário).
    *   Busca de servidores por ID, nome, ou outros critérios.
    *   Atualização de informações do servidor.
    *   Exclusão (lógica ou física) de servidores.
*   **Listagem e Descoberta de Servidores (`list_servers/1`):**
    *   Fornecer funcionalidades de listagem com filtros (por tags, região, status, tipo de jogo, etc.) e ordenação.
    *   Suporte à paginação para grandes listas de servidores.
*   **Gerenciamento de Status do Servidor:**
    *   Rastrear e atualizar o status de um servidor (online, offline, manutenção).
    *   (Opcional) Integrar com um sistema de monitoramento para obter status em tempo real.
*   **Gerenciamento de Tags de Servidor (`add_server_tag/2`, `remove_server_tag/2`, `list_server_tags/1`):**
    *   Permitir que proprietários de servidores associem tags aos seus servidores para categorização e descoberta.
    *   (Delegação para `Deeper_Hub.Services.ServerTags`).
*   **Gerenciamento de Pacotes de Servidor (Assinaturas/VIPs) (`Deeper_Hub.Services.ServerPackages`):**
    *   Permitir que proprietários criem e gerenciem pacotes (ex: VIP, itens) que podem ser oferecidos aos jogadores.
*   **Gerenciamento de Eventos de Servidor (`Deeper_Hub.Services.ServerEvents`):**
    *   Permitir que proprietários criem e gerenciem eventos para seus servidores (ex: evento de XP em dobro, torneio).
*   **Gerenciamento de Alertas de Servidor (`Deeper_Hub.Services.ServerAlerts`):**
    *   Permitir que proprietários enviem alertas ou anúncios para os jogadores do seu servidor ou para a comunidade.
*   **Gerenciamento de Avaliações (Reviews) de Servidor (`Deeper_Hub.Services.ServerReviews`):**
    *   Permitir que jogadores avaliem e escrevam reviews sobre os servidores.
    *   Calcular a avaliação média de um servidor.
*   **Gerenciamento de Mensagens de Atualização (`Deeper_Hub.Services.ServerUpdateMessages`):**
    *   Permitir que proprietários postem mensagens de atualização sobre seus servidores (ex: notas de patch, novidades).
*   **Gerenciamento de Convites de Servidor (`create_server_invite/1`, `list_server_invites/2`):**
    *   Permitir a criação e gerenciamento de códigos de convite para servidores privados ou para rastrear referências.
*   **Reputação do Servidor (`Deeper_Hub.Services.Lists.Schema.Reputation`):**
    *   (Potencial) Manter e calcular uma pontuação de reputação para servidores com base em avaliações, tempo online, moderação, etc.
*   **Integração com Autenticação e Autorização:**
    *   Garantir que apenas o proprietário de um servidor (ou administradores com permissão) possa modificar suas configurações.
    *   Usar `Deeper_Hub.Auth` e `Deeper_Hub.RBAC`.
*   **Observabilidade:**
    *   Registrar logs e métricas para operações de servidor.
    *   Publicar eventos de domínio (servidor criado, atualizado, etc.) no `Core.EventBus`.
*   **Limitação de Taxa (Rate Limiting):**
    *   Aplicar rate limiting para operações de criação ou atualização frequentes (via `Deeper_Hub.Services.Servers.RateLimitIntegration`).

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`Deeper_Hub.Servers` (Fachada Pública):**
    *   Ponto de entrada para todas as operações relacionadas a servidores.
    *   Delega para o `ServersService` (ou `DefaultServersService`).
2.  **`Deeper_Hub.Servers.Services.DefaultServersService` (ou `ServersService`):**
    *   **Responsabilidade:** Orquestra a lógica de negócio para o domínio de Servidores.
    *   **Interações:**
        *   `Deeper_Hub.Core.Repo`: Para todas as operações CRUD com o `ServerSchema` e schemas associados (se não delegados).
        *   `Deeper_Hub.Services.ServerTags.ServerTagsAdapter` (ou sua fachada): Para gerenciamento de tags.
        *   `Deeper_Hub.Services.ServerPackages.ServerPackagesAdapter`: Para pacotes.
        *   `Deeper_Hub.Services.ServerEvents.ServerEventsAdapter`: Para eventos.
        *   `Deeper_Hub.Services.ServerAlerts.ServerAlertsAdapter`: Para alertas.
        *   `Deeper_Hub.Services.ServerReviews.ServerReviewsAdapter`: Para reviews.
        *   `Deeper_Hub.Services.ServerUpdateMessages.ServerUpdateMessagesAdapter`: Para mensagens de atualização.
        *   `Deeper_Hub.Auth`: Para verificações de autorização (ex: quem é o proprietário).
        *   `Deeper_Hub.Core.EventBus`: Para publicar eventos como `server_created`.
        *   `Deeper_Hub.Core.Cache`: Para cachear dados de servidores frequentemente acessados.
3.  **Schemas Ecto:**
    *   **`Deeper_Hub.Servers.Schema.Server`:** Entidade principal do servidor.
    *   `Deeper_Hub.Services.ServerTags.Schema.Tag` (ou `Deeper_Hub.Servers.Schema.Tag` se movido para cá).
    *   `Deeper_Hub.Services.ServerPackages.Schema.ServerPackage`
    *   `Deeper_Hub.Services.ServerEvents.Schema.Event`
    *   `Deeper_Hub.Services.ServerAlerts.Schema.Alert`
    *   `Deeper_Hub.Services.ServerReviews.Schema.Review`
    *   `Deeper_Hub.Services.ServerUpdateMessages.Schema.UpdateMessage`
    *   `Deeper_Hub.Servers.Schema.Invite`
    *   `Deeper_Hub.Services.Lists.Schema.Reputation` (ou `Deeper_Hub.Servers.Schema.Reputation`)
4.  **`Deeper_Hub.Servers.Storage` (ou lógica dentro do `DefaultServersService`):**
    *   Encapsula as consultas Ecto diretas para o `ServerSchema` e, potencialmente, para os schemas associados mais simples, se os submódulos (`ServerTags`, etc.) forem apenas lógicos e não tiverem seu próprio storage.
5.  **Workers (Opcional):**
    *   `ServerStatusMonitorWorker`: Para verificar periodicamente o status online dos servidores.
    *   `ServerReputationCalculatorWorker`: Para recalcular a reputação dos servidores.
6.  **`Deeper_Hub.Servers.RateLimitIntegration`:**
    *   Aplica rate limiting para operações específicas do módulo Servers.
7.  **`Deeper_Hub.Servers.CachedAdapter` (Opcional):**
    *   Se for decidido adicionar uma camada de cache explícita para os dados do servidor além do `Core.Cache` genérico. (A documentação original sugere isso para `ServerPackages`, `ServerEvents`, etc., o que é uma boa prática).

### 3.2. Estrutura de Diretórios (Proposta)

```
servers/
├── servers.ex                        # Fachada Pública
│
├── services/
│   └── default_servers_service.ex    # Serviço principal do domínio Servers
│   # Outros serviços auxiliares específicos de Servers, se necessário
│
├── schemas/                          # (Ou schema/ singular)
│   ├── server.ex
│   └── invite.ex
│   └── reputation.ex                 # Se a reputação for fortemente ligada ao servidor
│
├── workers/                          # Opcional
│   ├── server_status_monitor_worker.ex
│   └── server_reputation_calculator_worker.ex
│
├── rate_limit_integration.ex
├── supervisor.ex
└── telemetry.ex                      # Ou um Metrics.ex dedicado
```
**Submódulos de \"Serviços\" da documentação original seriam seus próprios contextos de domínio:**
```
server_tags/
server_packages/
server_events/
server_alerts/
server_reviews/
server_update_messages/
```
Cada um com sua própria estrutura (fachada, serviço, schemas, storage/adapter, supervisor, telemetry). O `Deeper_Hub.Servers` então interagiria com as fachadas desses módulos.

### 3.3. Decisões de Design Importantes

*   **Domínio Rico vs. Anêmico:** O `ServerSchema` e o `DefaultServersService` devem conter lógica de negócio relevante para um servidor.
*   **Delegação para Subdomínios:** Funcionalidades como Tags, Pacotes, Eventos, Reviews, etc., são complexas o suficiente para serem seus próprios contextos/módulos de domínio, com os quais `Deeper_Hub.Servers` interage. Isso mantém o módulo `Servers` focado na entidade principal.
*   **Propriedade e Autorização:** A lógica de quem pode fazer o quê com um servidor (proprietário, administradores, jogadores) é fundamental e deve ser integrada com `Deeper_Hub.Auth` e `Deeper_Hub.RBAC`.
*   **Caching Estratégico:** Dados de servidores frequentemente visualizados (listagens, detalhes de servidores populares) devem ser cacheados. A invalidação do cache deve ocorrer quando os dados do servidor ou de seus sub-recursos (reviews, tags) mudam.

## 🛠️ 4. Casos de Uso Principais

*   **Proprietário Cria um Novo Servidor:**
    *   Usuário autenticado (proprietário) preenche um formulário.
    *   A API chama `Deeper_Hub.Servers.create_server(user_id, server_attrs)`.
    *   O serviço valida os dados, verifica permissões, e persiste o novo servidor.
    *   Um evento `server_created` é publicado.
*   **Jogador Procura Servidores de \"RPG PvP\":**
    *   A API recebe uma requisição para `GET /api/v1/servers?tags=rpg,pvp`.
    *   Chama `Deeper_Hub.Servers.list_servers(%{tags: [\"rpg\", \"pvp\"], include_stats: true})`.
    *   O serviço consulta servidores, possivelmente buscando tags no módulo `ServerTags`, e retorna a lista.
*   **Jogador Avalia um Servidor:**
    *   A API chama `Deeper_Hub.ServerReviews.create_review(user_id, server_id, review_attrs)`.
    *   O `ServerReviews` valida e salva a review.
    *   Pode disparar um evento que o `Deeper_Hub.Servers` escuta para recalcular a média de avaliação do servidor e invalidar o cache.
*   **Sistema Monitora Status de um Servidor:**
    *   `ServerStatusMonitorWorker` periodicamente tenta se conectar ao `server.address` e `server.port`.
    *   Atualiza o `server.status` e `server.last_seen_online_at` via `Deeper_Hub.Servers.update_server_status(server_id, new_status_info)`.

## 🌊 5. Fluxos Importantes

### Fluxo de Criação de Servidor

1.  **Requisição API/UI:** Usuário submete dados para criar um servidor.
2.  **Controller API:** Valida a autenticação do usuário. Chama `Deeper_Hub.Servers.create_server(current_user.id, params)`.
3.  **`Deeper_Hub.Servers` (Fachada):** Delega para `DefaultServersService.create_server/2`.
4.  **`DefaultServersService.create_server/2`:**
    *   Verifica se o usuário tem permissão para criar servidores (ex: `Deeper_Hub.RBAC.has_permission?(user_id, :server, :create)`).
    *   Cria um changeset para `Deeper_Hub.Servers.Schema.Server` com os `params` e `owner_id: current_user.id`.
    *   Se o changeset for válido:
        *   Chama `Deeper_Hub.Core.Repo.insert(changeset)`.
        *   Se a inserção for bem-sucedida:
            *   Publica um evento `server_created` via `Core.EventBus` com os dados do novo servidor.
            *   Registra no `Deeper_Hub.Audit`.
            *   Retorna `{:ok, server_struct}`.
        *   Se a inserção falhar, retorna `{:error, db_error_reason}`.
    *   Se o changeset for inválido, retorna `{:error, changeset}`.

### Fluxo de Listagem de Servidores com Filtro por Tag

1.  **Requisição API/UI:** `GET /servers?tags=pvp,economy`
2.  **Controller API:** Chama `Deeper_Hub.Servers.list_servers(%{tags: [\"pvp\", \"economy\"], page: 1, per_page: 20})`.
3.  **`Deeper_Hub.Servers` (Fachada):** Delega para `DefaultServersService.list_servers/1`.
4.  **`DefaultServersService.list_servers/1`:**
    *   **Cache Check (Opcional):** Tenta buscar do `Core.Cache` usando uma chave baseada nos filtros. Se hit, retorna.
    *   **Consulta ao `ServerTags`:** Chama `Deeper_Hub.ServerTags.list_servers_by_tags([\"pvp\", \"economy\"])` para obter uma lista de `server_ids`.
    *   **Construção da Query Ecto:**
        ```elixir
        query = from(s in Server, where: s.id in ^server_ids_from_tags)
        # Aplicar outros filtros (status, nome, etc.)
        # Aplicar ordenação e paginação
        ```
    *   Executa a query via `Core.Repo.all(query)`.
    *   (Opcional) Para cada servidor, busca informações adicionais como avaliação média (`ServerReviews.get_average_rating(server.id)`).
    *   **Cache Put (Opcional):** Armazena o resultado no `Core.Cache`.
    *   Retorna `{:ok, %{servers: results, pagination_details: ...}}`.

## 📡 6. API (Funções Públicas da Fachada `Deeper_Hub.Servers`)

*(Baseado na documentação original e consolidando com as responsabilidades dos submódulos que seriam delegados)*

### 6.1. `Deeper_Hub.Servers.create_server(owner_id :: String.t(), attrs :: map()) :: {:ok, Server.t()} | {:error, Ecto.Changeset.t() | term()}`

*   **Descrição:** Cria um novo servidor.
*   **`attrs`:** Mapa com dados do servidor (ex: `:name`, `:description`, `:address`, `:port`, `:game_type`, `:banner_url`, etc.).

### 6.2. `Deeper_Hub.Servers.get_server(server_id :: String.t(), opts :: keyword()) :: {:ok, Server.t() | nil} | {:error, term()}`

*   **Descrição:** Obtém um servidor pelo seu ID.
*   **`opts`:**
    *   `:preload` (list): Associações Ecto a serem pré-carregadas (ex: `[:tags, :reviews, :active_events]`).
    *   `:include_stats` (boolean): Se deve incluir estatísticas agregadas como avaliação média, contagem de jogadores (pode envolver chamadas a outros serviços).
*   **Retorno:** `{:ok, server}` ou `{:ok, nil}` se não encontrado (ou `{:error, :not_found}`).

### 6.3. `Deeper_Hub.Servers.list_servers(filters :: map(), opts :: keyword()) :: {:ok, list(Server.t()), Pagination.t()} | {:error, term()}`

*   **Descrição:** Lista servidores com base em filtros, ordenação e paginação.
*   **`filters`:** Mapa com filtros (ex: `%{name_contains: \"craft\", tags: [\"survival\"], min_rating: 4.0, status: :online, owner_id: \"user123\"}`).
*   **`opts`:** `:sort_by`, `:sort_order`, `:page`, `:per_page`, `:preload`, `:include_stats`.

### 6.4. `Deeper_Hub.Servers.update_server(server_id :: String.t(), attrs :: map(), current_user_id :: String.t()) :: {:ok, Server.t()} | {:error, Ecto.Changeset.t() | :unauthorized | term()}`

*   **Descrição:** Atualiza um servidor existente. Requer que `current_user_id` seja o proprietário ou tenha permissão de admin.

### 6.5. `Deeper_Hub.Servers.delete_server(server_id :: String.t(), current_user_id :: String.t()) :: {:ok, Server.t()} | {:error, :unauthorized | :not_found | term()}`

*   **Descrição:** Exclui um servidor.

### 6.6. Funções Delegadas para Submódulos (Exemplos):

*   `Deeper_Hub.Servers.add_tag_to_server(server_id, tag_name, current_user_id)` -> Delega para `Deeper_Hub.ServerTags`.
*   `Deeper_Hub.Servers.list_server_reviews(server_id, filters, opts)` -> Delega para `Deeper_Hub.ServerReviews`.
*   `Deeper_Hub.Servers.create_server_package(server_id, package_attrs, current_user_id)` -> Delega para `Deeper_Hub.ServerPackages`.
*   ... e assim por diante para `ServerEvents`, `ServerAlerts`, `ServerUpdateMessages`, `ServerInvites`.

### 6.7. `Deeper_Hub.Servers.update_server_status(server_id :: String.t(), status_info :: map()) :: {:ok, Server.t()} | {:error, term()}` (Nova Sugestão)

*   **Descrição:** Atualiza o status de um servidor (online, offline, player_count). Usado por um worker de monitoramento.
*   **`status_info`:** `%{status: :online | :offline, player_count: integer(), max_players: integer(), version: String.t()}`.

## ⚙️ 7. Configuração

Via `Deeper_Hub.Core.ConfigManager`:

*   **`[:servers, :max_servers_per_user]`** (Integer): Limite de servidores que um usuário pode criar. (Padrão: `5`)
*   **`[:servers, :default_list_page_size]`** (Integer): Tamanho padrão da página para listagens. (Padrão: `20`)
*   **`[:servers, :cache, :server_details_ttl_seconds]`** (Integer): TTL para cache de detalhes de servidor. (Padrão: `300`)
*   **`[:servers, :cache, :server_list_ttl_seconds]`** (Integer): TTL para cache de listagens de servidor. (Padrão: `60`)
*   **`[:servers, :status_monitor, :enabled]`** (Boolean): Habilita o worker de monitoramento de status. (Padrão: `true`)
*   **`[:servers, :status_monitor, :check_interval_seconds]`** (Integer): Intervalo para verificar status dos servidores. (Padrão: `300`)
*   **`[:servers, :reputation, :recalculation_interval_hours]`** (Integer): Intervalo para recalcular reputação.
*   *(Configurações específicas para tags, reviews, pacotes, etc., residiriam em seus respectivos módulos)*

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `Deeper_Hub.Core.Repo`: Para persistência.
*   `Deeper_Hub.Core.ConfigManager`, `Core.EventBus`, `Core.Logger`, `Core.Metrics`, `Core.Cache`.
*   `Deeper_Hub.Auth` e `Deeper_Hub.RBAC`: Para autorização de proprietários e administradores.
*   `Deeper_Hub.Accounts`: Para associar servidores a proprietários.
*   **Submódulos de Serviço:** `Deeper_Hub.ServerTags`, `ServerPackages`, `ServerEvents`, `ServerAlerts`, `ServerReviews`, `ServerUpdateMessages`.
*   `Deeper_Hub.Servers.RateLimitIntegration`.

### 8.2. Bibliotecas Externas

*   `Ecto`.
*   Bibliotecas para query de status de servidores de jogos específicos (ex: Minecraft RCON, Source Query), se o `ServerStatusMonitorWorker` for implementado.

## 🤝 9. Como Usar / Integração

*   **APIs Web/Mobile:** Controllers da API chamarão as funções da fachada `Deeper_Hub.Servers` para realizar operações.
*   **Painel de Proprietário do Servidor:** Uma UI web para proprietários gerenciarem seus servidores usaria esses endpoints.
*   **Sistema de Busca:** O `Deeper_Hub.Services.Search` usaria `Deeper_Hub.Servers.list_servers/2` com vários filtros.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar todas as operações CRUD para servidores.
*   Testar a lógica de listagem com diferentes filtros e ordenações.
*   Testar as interações com os submódulos (tags, reviews, etc.) usando mocks ou testes de integração.
*   Testar a lógica de autorização (proprietário vs. outros usuários).
*   Testar o funcionamento dos workers (monitor de status, cálculo de reputação).
*   Localização: `test/deeper_hub/servers/`.

### 10.2. Métricas

*   `deeper_hub.servers.created.count`
*   `deeper_hub.servers.updated.count`
*   `deeper_hub.servers.deleted.count`
*   `deeper_hub.servers.listed.count` (tags: `filter_count`)
*   `deeper_hub.servers.viewed.count` (tags: `server_id`)
*   `deeper_hub.servers.active.gauge` (Gauge)
*   `deeper_hub.servers.status_monitor.checked.count` (tags: `status_returned`)
*   *(Métricas dos submódulos seriam registradas por eles próprios)*

### 10.3. Logs

*   **Nível INFO:** Criação, atualização, exclusão de servidores. Mudança de status de servidor.
*   **Nível WARNING:** Falha ao obter status de um servidor pelo monitor. Tentativa não autorizada de modificar um servidor.
*   **Nível ERROR:** Falha crítica ao interagir com o banco de dados.

### 10.4. Telemetria

*   `[:deeper_hub, :servers, :server, :created | :updated | :deleted]`
    *   Metadados: `%{server_id: id, owner_id: id, changes: map_if_updated}`
*   `[:deeper_hub, :servers, :server, :status_changed]`
    *   Metadados: `%{server_id: id, old_status: atom, new_status: atom}`
*   `[:deeper_hub, :servers, :list_query, :executed]`
    *   Metadados: `%{filters: map, sort: map, pagination: map, result_count: count}`
*   *(Eventos de telemetria dos submódulos seriam emitidos por eles)*

## ❌ 11. Tratamento de Erros

*   Operações CRUD retornam `{:ok, result}` ou `{:error, changeset | reason}`.
*   Falhas de autorização retornam `{:error, :unauthorized}`.
*   Recursos não encontrados retornam `{:error, :not_found}` ou `nil` (para funções `get_`).

## 🛡️ 12. Considerações de Segurança

*   **Autorização:** A verificação rigorosa de propriedade e permissões é crucial para todas as operações de escrita.
*   **Validação de Entrada:** Todos os dados fornecidos pelo usuário (nomes de servidor, descrições, endereços IP/portas) devem ser validados para prevenir XSS (se exibidos) e outros ataques. Endereços IP/hostnames devem ser validados para evitar SSRF se o sistema tentar se conectar a eles.
*   **Rate Limiting:** Proteger contra a criação excessiva de servidores ou atualizações frequentes.
*   **Moderação de Conteúdo:** Conteúdo gerado pelo usuário (nome do servidor, descrição, tags, reviews) precisa de moderação.

## 🧑‍💻 13. Contribuição

*   Mantenha a lógica de negócio específica do servidor no `DefaultServersService`.
*   Para funcionalidades relacionadas (tags, reviews, etc.), crie ou use os módulos de serviço dedicados e interaja com suas fachadas.
*   Adicione testes abrangentes para novas funcionalidades e filtros de listagem.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar um sistema de \"destaque\" ou \"promoção\" de servidores.
*   [ ] Adicionar mais opções de filtros avançados na listagem (ex: por tipo de jogo específico, mods, versão).
*   [ ] Integrar com um sistema de votação para servidores.
*   [ ] Permitir que proprietários customizem a página de seus servidores com mais detalhes.
*   [ ] Desenvolver um sistema de \"reivindicação\" para servidores existentes que foram adicionados por outros usuários.
*   [ ] Melhorar o `ServerStatusMonitorWorker` para suportar diferentes protocolos de query de jogos.
*   [ ] Implementar um sistema de ranking de servidores mais sofisticado do que apenas avaliação média.

---

*Última atualização: 2025-05-12*

---

Este módulo `Servers` é um bom exemplo de um contexto de domínio que interage com muitos outros.

O que acha de detalharmos agora um desses submódulos que `Servers` utilizaria, como `Deeper_Hub.ServerTags` ou `Deeper_Hub.ServerReviews`? Ou prefere outro módulo Core ou de Segurança?"""),
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
                types.Part.from_text(text="""Perfeito! Vamos detalhar um dos submódulos que o `Deeper_Hub.Servers` utilizaria: `Deeper_Hub.ServerTags`. Este módulo, embora mais simples que `Servers`, é importante para a organização e descoberta de servidores.

*(Nota: Na documentação original, este era `Deeper_Hub.Services.ServerTags`. Estamos elevando-o a um contexto de domínio próprio, ou um submódulo bem definido dentro de `Deeper_Hub.Servers` se a complexidade não justificar um contexto totalmente separado. Para este README, vou tratá-lo como `Deeper_Hub.ServerTags` para clareza, mas a estrutura de pastas pode refleti-lo dentro de `servers/` se preferir.)*

---

