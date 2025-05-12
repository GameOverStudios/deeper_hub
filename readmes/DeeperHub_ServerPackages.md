# Módulo: `DeeperHub.ServerPackages` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.ServerPackages`

O módulo `DeeperHub.ServerPackages` é responsável por gerenciar **pacotes, itens ou assinaturas (packages)** que os proprietários de servidores podem oferecer aos jogadores na plataforma DeeperHub. Estes pacotes podem representar uma variedade de ofertas, como acesso VIP, moedas virtuais específicas do servidor, itens no jogo, cosméticos, ou outros benefícios e produtos digitais.

Este módulo lida com:
*   A definição, criação e gerenciamento de pacotes pelos proprietários de servidores.
*   A listagem de pacotes disponíveis para um servidor.
*   A lógica de \"aquisição\" ou \"compra\" desses pacotes, que pode envolver integração com sistemas de pagamento ou moedas virtuais da plataforma.
*   A concessão dos benefícios do pacote ao usuário após a aquisição.

O objetivo é fornecer uma maneira estruturada e gerenciável para os servidores oferecerem valor adicional ou monetizarem suas comunidades dentro do ecossistema DeeperHub. 😊

*(Nota: Na documentação original, este era `DeeperHub.Services.ServerPackages`. Será tratado como `DeeperHub.ServerPackages`.)*

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Gerenciamento CRUD de Definições de Pacotes (`create_server_package/1`, `get_server_package/1`, `update_server_package/2`, `delete_server_package/1`):**
    *   Permitir que proprietários de servidores (ou administradores com permissão) criem, visualizem, atualizem e excluam definições de pacotes associados aos seus servidores.
    *   Cada definição de pacote inclui: nome, descrição detalhada, preço (com moeda – real ou virtual), tipo de pacote (ex: compra única, assinatura mensal), duração (se assinatura), lista de benefícios/itens incluídos (pode ser um campo JSONB flexível para descrever os efeitos), imagem/ícone, status (ativo, inativo, rascunho), datas de disponibilidade (opcional).
*   **Listagem de Pacotes:**
    *   Listar todos os pacotes ativos e disponíveis para um servidor específico (`list_server_packages_by_server/2`).
    *   Listar todos os pacotes disponíveis na plataforma com filtros (ex: por tipo de servidor, por tipo de pacote, por faixa de preço) (`list_all_server_packages/1`).
    *   Suporte a paginação e ordenação.
*   **Processo de Aquisição de Pacote (Coordenação):**
    *   Fornecer uma API para iniciar o processo de aquisição de um pacote por um usuário (`acquire_package/3` - esta função pode residir em um `UserPackageService` ou `UserInventoryService` que coordena com `ServerPackages` e `Payments`).
    *   Verificar elegibilidade do usuário para adquirir o pacote (ex: limites de compra, pré-requisitos).
*   **Integração com Pagamentos (`DeeperHub.Payments`):**
    *   Se o pacote tiver um preço em moeda real, integrar com o sistema de pagamentos para processar a transação antes de conceder o pacote.
*   **Integração com Moeda Virtual/Pontos (`DeeperHub.PointsService` ou similar):**
    *   Se o pacote for adquirido com moeda virtual da plataforma, integrar com o serviço correspondente para debitar o saldo do usuário.
*   **Concessão de Benefícios/Itens (`grant_package_benefits/3`):**
    *   Após a aquisição bem-sucedida, acionar a lógica para conceder os benefícios ou itens do pacote ao usuário. Isso pode envolver:
        *   Chamar APIs do servidor de jogo (se o DeeperHub tiver essa capacidade de integração).
        *   Atualizar o estado do usuário no `DeeperHub.Accounts` (ex: marcar como VIP).
        *   Adicionar itens a um `DeeperHub.UserInventoryService` (Novo Sugerido).
        *   Conceder papéis/permissões específicas (via `DeeperHub.RBAC`).
*   **Gerenciamento de Assinaturas (se aplicável):**
    *   Lidar com a lógica de renovação, cancelamento e status de pacotes do tipo assinatura. (Isso pode ser complexo e exigir um submódulo ou integração com um serviço de faturamento recorrente).
*   **Observabilidade e Auditoria:**
    *   Logar e metrificar a criação, aquisição e concessão de pacotes.
    *   Publicar eventos de domínio (ex: `server_package.created`, `user.package_acquired`) no `Core.EventBus`.
    *   Auditar todas as transações e modificações de pacotes.
*   **Caching:**
    *   Cachear definições de pacotes para acesso rápido.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.ServerPackages` (Fachada Pública):**
    *   Ponto de entrada para gerenciamento de definições de pacotes e consulta.
    *   Delega para o `ServerPackagesService`.
2.  **`DeeperHub.ServerPackages.Services.ServerPackagesService` (ou `DefaultServerPackagesService`):**
    *   **Responsabilidade:** Lógica de negócio para CRUD de `ServerPackageSchema`.
    *   **Interações:**
        *   `DeeperHub.Core.Repo`: Para persistência.
        *   `DeeperHub.Servers`: Para validar `server_id`.
        *   `DeeperHub.Accounts`: Para `user_id` do criador.
        *   `DeeperHub.Auth`/`RBAC`: Para permissões de gerenciamento.
        *   `DeeperHub.Core.EventBus`, `Core.Cache`, `Core.ConfigManager`.
3.  **`DeeperHub.ServerPackages.Schemas.ServerPackageSchema`:**
    *   Define a estrutura de um pacote oferecido por um servidor.
    *   Campos: `id`, `server_id`, `name`, `description`, `image_url`, `package_type` (`:one_time`, `:subscription`), `price_currency` (ex: \"BRL\", \"USD\", \"POINTS_PLATFORM\", \"CREDITS_SERVER_X\"), `price_amount` (Decimal), `duration_days` (para assinaturas), `benefits_payload` (JSONB, descrevendo o que é concedido, ex: `%{ \"role\": \"VIP_GOLD\", \"ingame_items\": [{\"id\": \"sword123\", \"qty\": 1}], \"virtual_currency\": {\"type\": \"gems\", \"amount\": 500} }`), `is_active`, `available_from`, `available_until`, `max_per_user`, `sort_order`.
4.  **`DeeperHub.UserInventory` (ou `UserPackages` - Novo Módulo Sugerido):**
    *   **Fachada (`DeeperHub.UserInventory`):** Para operações como `acquire_package`, `list_my_packages`.
    *   **Serviço (`UserInventoryService`):** Orquestra a aquisição, incluindo interação com `Payments`/`PointsService` e `ServerPackages` para obter detalhes do pacote, e então `GrantingService` para aplicar os benefícios.
    *   **Schema (`UserPackageInstanceSchema`):** Registra que um `user_id` adquiriu um `server_package_id`, com `acquired_at`, `expires_at` (para assinaturas), `status` (`:active`, `:expired`, `:cancelled`).
5.  **`DeeperHub.GrantingService` (Novo Módulo Sugerido ou parte do `UserInventory`):**
    *   **Responsabilidade:** Interpretar o `benefits_payload` de um `ServerPackage` e aplicar os benefícios ao usuário. Isso pode envolver chamar APIs de jogos, atualizar `UserSchema` ou `UserRoleSchema`, adicionar itens a um inventário virtual, etc. Pode usar um sistema de \"handlers de benefício\" similar aos `RewardHandler`s.
6.  **`DeeperHub.Payments` (Módulo Separado):**
    *   Se houver pagamento com moeda real.
7.  **`DeeperHub.ServerPackages.Storage` / `UserInventory.Storage`:**
    *   Encapsulam queries Ecto.

### 3.2. Estrutura de Diretórios (Proposta)

```
lib/deeper_hub/server_packages/
├── server_packages.ex                # Fachada para definições de pacotes
│
├── services/
│   └── server_packages_service.ex    # CRUD para ServerPackageSchema
│
├── schemas/
│   └── server_package_schema.ex
│
├── storage.ex                        # (Opcional)
├── cached_adapter.ex                 # (Opcional, para definições)
├── supervisor.ex
└── telemetry.ex

lib/deeper_hub/user_inventory/        # NOVO MÓDULO para gerenciar o que os usuários possuem
├── user_inventory.ex                 # Fachada (ex: acquire_package)
│
├── services/
│   ├── user_inventory_service.ex     # Orquestra aquisição
│   └── granting_service.ex           # Aplica benefícios
│
├── schemas/
│   └── user_package_instance_schema.ex
│
├── storage.ex
├── supervisor.ex
└── telemetry.ex
```

### 3.3. Decisões de Design Importantes

*   **Separação de Definição e Instância:** Manter `ServerPackageSchema` (o que está à venda) separado de `UserPackageInstanceSchema` (o que o usuário comprou) é crucial.
*   **Flexibilidade dos Benefícios:** O `benefits_payload` em JSONB é chave para suportar diversos tipos de benefícios sem alterar o schema do banco de dados constantemente.
*   **Transacionalidade da Aquisição:** O processo de debitar fundos (reais ou virtuais) e conceder o pacote/benefícios deve ser atômico.
*   **Lógica de Concessão:** A lógica de como os benefícios são aplicados (`GrantingService`) pode ser complexa e precisar de integrações com sistemas externos (APIs de jogos).

## 🛠️ 4. Casos de Uso Principais

*   **Proprietário de Servidor Adiciona um Pacote \"Kit Inicial\":**
    *   Define nome, descrição, preço (ex: 500 \"Pontos da Plataforma\"), e `benefits_payload: %{\"ingame_items\": [{\"item_id\": \"basic_sword\", \"qty\": 1}, {\"item_id\": \"healing_potion\", \"qty\": 5}]}`.
    *   API chama `ServerPackages.create_server_package(...)`.
*   **Jogador Compra o \"Kit Inicial\":**
    *   UI mostra o pacote. Jogador clica em \"Comprar com 500 Pontos\".
    *   API chama `UserInventory.acquire_package(user_id, package_id, %{payment_method: :platform_points})`.
    *   `UserInventoryService` verifica e debita os pontos do `PointsService`.
    *   Cria `UserPackageInstanceSchema`.
    *   `GrantingService` interpreta o `benefits_payload` e (por exemplo) chama uma API do servidor de jogo para dar os itens ao jogador.
*   **Sistema Verifica Assinatura VIP de um Jogador:**
    *   Quando o jogador loga no servidor de jogo, o jogo pode consultar uma API do DeeperHub: `UserInventory.get_active_package_instance_by_type(user_id, server_id, :vip_subscription)`.

## 🌊 5. Fluxos Importantes

### Fluxo de Compra de um Pacote de \"Uso Único\" com Moeda Virtual

1.  **Usuário (UI):** Clica para comprar Pacote P (ID: `pkg_123`) que custa 100 Pontos.
2.  **Controller API:** Chama `DeeperHub.UserInventory.acquire_package(user_id, \"pkg_123\", %{payment_method: :platform_points, expected_points_cost: 100})`.
3.  **`UserInventoryService.acquire_package/3`:**
    *   Busca `ServerPackageSchema` para \"pkg_123\" (via `ServerPackages.get_server_package`). Verifica se está ativo e o preço.
    *   Verifica se o usuário já atingiu `max_per_user` para este pacote, se aplicável.
    *   Chama `DeeperHub.PointsService.debit_points(user_id, 100, %{reason: \"Purchase of pkg_123\"})`.
    *   **Se débito falhar (saldo insuficiente):** Retorna `{:error, :insufficient_points}`.
    *   **Se débito OK:**
        *   Inicia uma transação `Core.Repo.transaction/2`.
        *   Dentro da transação:
            *   Cria um `UserPackageInstanceSchema` (`user_id`, `server_package_id`, `acquired_at`, `status: :active` (ou `:consumed` se o efeito é imediato e único)).
            *   Incrementa `total_purchased_count` no `ServerPackageSchema`.
        *   **Fim da transação.**
        *   Se a transação do Repo falhar, tenta reverter o débito de pontos (lógica de compensação ou saga pode ser necessária aqui, ou a transação de pontos deve fazer parte da transação do Repo se o PointsService usar o mesmo DB).
        *   Se tudo OK:
            *   Chama `GrantingService.apply_benefits(user_id, server_package.benefits_payload, %{source_package_instance_id: ...})`.
            *   Publica evento `user_package.acquired` no `Core.EventBus`.
            *   Notifica o usuário.
            *   Retorna `{:ok, user_package_instance}`.

## 📡 6. API (Funções Públicas das Fachadas)

### `DeeperHub.ServerPackages` (Gerenciamento de Definições)

*   `create_server_package(creator_user_id, server_id, attrs)`
*   `update_server_package(package_id, attrs, current_user_id)`
*   `delete_server_package(package_id, current_user_id)`
*   `get_server_package(package_id)`
*   `list_server_packages_by_server(server_id, opts)`
*   `list_all_server_packages(filters, opts)`

### `DeeperHub.UserInventory` (Aquisição e Gerenciamento de Instâncias de Usuário)

*   **`DeeperHub.UserInventory.acquire_package(user_id :: String.t(), server_package_id :: String.t(), acquisition_context :: map()) :: {:ok, UserPackageInstance.t()} | {:error, term()}`**
    *   `acquisition_context`: `%{payment_method: :platform_points | :real_money_transaction_id, expected_cost: Decimal.t() | nil}`.
*   **`DeeperHub.UserInventory.list_my_active_packages(user_id :: String.t(), opts :: keyword()) :: {:ok, list(UserPackageInstanceView.t())}`**
    *   `UserPackageInstanceView.t()`: Combina dados da instância com a definição do pacote.
*   **`DeeperHub.UserInventory.get_package_instance_details(user_package_instance_id :: String.t(), user_id :: String.t()) :: {:ok, UserPackageInstanceView.t() | nil}`**
*   **`DeeperHub.UserInventory.cancel_subscription(user_package_instance_id :: String.t(), user_id :: String.t()) :: :ok | {:error, term()}`** (Se houver assinaturas)

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager`:

*   **`[:server_packages, :enabled]`** (Boolean).
*   **`[:server_packages, :max_name_length]`** (Integer).
*   **`[:server_packages, :max_description_length]`** (Integer).
*   **`[:server_packages, :allowed_currencies]`** (List de Strings): Ex: `[\"POINTS_PLATFORM\", \"USD\"]`.
*   **`[:server_packages, :default_package_types]`** (List de Atoms): Ex: `[:one_time, :subscription]`.
*   **`[:server_packages, :cache, :package_definition_ttl_seconds]`** (Integer).
*   **`[:user_inventory, :default_subscription_renewal_notification_days_before]`** (Integer): Para enviar lembretes de renovação.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.*`.
*   `DeeperHub.Servers`: Para `server_id`.
*   `DeeperHub.Accounts`: Para `user_id`.
*   `DeeperHub.Auth`/`RBAC`: Para permissões.
*   `DeeperHub.Notifications`: Para notificar sobre aquisições.
*   `DeeperHub.Payments` (Opcional).
*   `DeeperHub.PointsService` (ou similar, Opcional).
*   `DeeperHub.Audit`.

### 8.2. Bibliotecas Externas

*   `Ecto`.
*   `Decimal`.

## 🤝 9. Como Usar / Integração

*   **UI do Proprietário do Servidor:** Para definir e gerenciar os pacotes que seu servidor oferece.
*   **Loja na Página do Servidor (UI do Jogador):** Para listar pacotes e iniciar o fluxo de aquisição.
*   **Servidor de Jogo (Externo):** Pode precisar de uma API para:
    *   Verificar os pacotes/benefícios ativos de um jogador (via `UserInventory`).
    *   (Potencialmente) Conceder itens/benefícios no jogo após o `GrantingService` ser notificado (ex: via webhook ou API do jogo).

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar CRUD para `ServerPackageSchema`.
*   Testar o fluxo completo de aquisição de pacotes com diferentes métodos de pagamento (mockados).
*   Testar a correta concessão de benefícios pelo `GrantingService` (com mocks para sistemas externos).
*   Testar a lógica de assinaturas (criação, renovação, cancelamento, expiração).
*   Testar limites (ex: `max_per_user`).
*   Localização: `test/deeper_hub/server_packages/` e `test/deeper_hub/user_inventory/`.

### 10.2. Métricas

*   `deeper_hub.server_packages.definitions.count` (Gauge, tags: `server_id`)
*   `deeper_hub.user_inventory.package_acquired.count` (tags: `package_id`, `server_id`, `payment_method`)
*   `deeper_hub.user_inventory.revenue_generated.sum` (Contador, tags: `currency`, `package_id`) (Para moeda real)
*   `deeper_hub.user_inventory.points_spent.sum` (Contador, tags: `package_id`) (Para moeda virtual)
*   `deeper_hub.user_inventory.active_subscriptions.gauge` (tags: `package_id`)

### 10.3. Logs

*   **Nível INFO:** Definição de pacote criada/atualizada. Pacote adquirido por usuário. Benefícios concedidos.
*   **Nível WARNING:** Tentativa de adquirir pacote sem saldo/meio de pagamento válido. Falha na concessão de um benefício específico (com retry se aplicável).
*   **Nível ERROR:** Falha crítica no processamento de pagamento. Falha ao persistir `UserPackageInstance` após pagamento confirmado.

### 10.4. Telemetria

*   `[:deeper_hub, :server_packages, :definition, :created | :updated | :deleted]`
*   `[:deeper_hub, :user_inventory, :acquisition_attempt, :start | :stop | :exception]`
    *   Metadados: `%{user_id: id, package_id: id, payment_method: method}`
    *   No `:stop`: `%{status: :success | :failure_payment | :failure_granting, instance_id: id}`
*   `[:deeper_hub, :user_inventory, :benefit_granting, :start | :stop | :exception]`
    *   Metadados: `%{user_id: id, package_instance_id: id, benefit_type: type}`

## ❌ 11. Tratamento de Erros

*   **Falha no Pagamento:** O fluxo de aquisição deve parar, nenhum benefício concedido.
*   **Falha na Concessão de Benefícios Pós-Pagamento:** Este é um cenário crítico. Idealmente, a concessão é parte da mesma transação. Se não for possível, o pagamento deve ser reembolsado/estornado, ou a concessão deve ser reenfileirada com alta prioridade e monitoramento.
*   Erros de validação na criação de pacotes retornam `{:error, changeset}`.

## 🛡️ 12. Considerações de Segurança

*   **Validação de Preços:** Impedir preços negativos ou absurdamente baixos/altos.
*   **Segurança do Fluxo de Pagamento:** Se envolver dinheiro real, a integração com o `Payments` deve ser PCI DSS compliant (se aplicável) e seguir todas as melhores práticas de segurança para transações financeiras.
*   **Concessão de Benefícios:** A lógica no `GrantingService` deve ser segura para evitar que usuários ganhem benefícios indevidamente.
*   **Autorização:** Apenas proprietários de servidores podem criar pacotes para *seus* servidores. Administradores da plataforma podem ter permissões mais amplas.

## 🧑‍💻 13. Contribuição

*   O `benefits_payload` é um ponto chave de extensão. Novos tipos de benefícios exigirão novos \"handlers\" no `GrantingService`.
*   A lógica de assinatura pode se tornar um submódulo próprio se muito complexa.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar um sistema de cupons de desconto para pacotes.
*   [ ] Permitir \"pacotes de presente\" que um usuário pode comprar para outro.
*   [ ] Suporte para pacotes com quantidade limitada de estoque.
*   [ ] Histórico de compras detalhado para o usuário.
*   [ ] Ferramentas para proprietários de servidores analisarem as vendas e popularidade de seus pacotes.
*   [ ] Reembolsos e gerenciamento de disputas para pacotes pagos.
*   [ ] Integração com APIs de jogos para concessão automática de itens/benefícios diretamente no jogo.

---

*Última atualização: 2025-05-13*

---

Este módulo de pacotes adiciona uma camada significativa de funcionalidade e potencial de monetização.

Próximo? Podemos cobrir o `DeeperHub.ServerUpdateMessages` para completar as funcionalidades de \"comunicação\" do servidor, ou o módulo genérico `DeeperHub.Lists`?"""),
            ],
        ),
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(text="""continue"""),
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

