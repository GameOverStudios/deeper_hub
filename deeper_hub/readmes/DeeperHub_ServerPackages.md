# Módulo: `DeeperHub.ServerPackages` 📦

## 📜 1. Visão Geral do Módulo `DeeperHub.ServerPackages`

O módulo `DeeperHub.ServerPackages` é responsável por gerenciar os diferentes pacotes, planos ou itens que podem ser oferecidos por um servidor dentro da plataforma DeeperHub. Isso pode incluir pacotes de assinatura, itens virtuais, benefícios VIP, ou qualquer outro produto ou serviço que os proprietários de servidores queiram disponibilizar para seus usuários, seja de forma gratuita ou paga. O módulo lida com a definição, listagem e associação desses pacotes aos servidores. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Definição de Pacotes de Servidor:**
    *   CRUD para Pacotes (`ServerPackage`): nome, descrição, preço (se aplicável), moeda, tipo de pacote (ex: assinatura, item único, benefício).
    *   Detalhes do pacote: lista de features/benefícios incluídos, duração (para assinaturas), quantidade (para itens).
    *   Associação do pacote a um servidor específico (`server_id`).
*   **Gerenciamento de Preços e Moedas:**
    *   Suporte para diferentes moedas.
    *   (Opcional) Histórico de preços.
*   **Listagem e Descoberta de Pacotes:**
    *   Permitir que usuários visualizem os pacotes disponíveis para um servidor.
    *   Filtrar pacotes por tipo, preço, popularidade.
*   **Controle de Disponibilidade:**
    *   Habilitar ou desabilitar pacotes.
    *   (Opcional) Gerenciar estoque para pacotes com quantidade limitada.
*   **Integração com Compras/Assinaturas (Delegação):**
    *   Embora este módulo defina os pacotes, a lógica de processamento de compra ou gerenciamento de assinaturas ativas seria provavelmente delegada a um módulo `DeeperHub.Billing` ou `DeeperHub.Subscriptions`. Este módulo apenas informa o que está disponível para compra/assinatura.
*   **Administração de Pacotes:**
    *   Interface para proprietários de servidores criarem e gerenciarem os pacotes de seus servidores.
    *   Interface para administradores da plataforma moderarem ou destacarem pacotes.

## 🏗️ 3. Arquitetura e Design

`DeeperHub.ServerPackages` atuará como uma fachada para um serviço de lógica de negócio e componentes de persistência.

*   **Interface Pública (`DeeperHub.ServerPackages.ServerPackagesFacade` ou `DeeperHub.ServerPackages`):** Funções como `create_server_package/1`, `list_packages_for_server/2`, `get_package_details/1`.
*   **Serviço de Pacotes de Servidor (`DeeperHub.ServerPackages.Services.PackageService`):**
    *   Contém a lógica de negócio principal para definir e gerenciar pacotes.
*   **Schemas Ecto:**
    *   `DeeperHub.ServerPackages.Schema.ServerPackage`: Define um pacote de servidor.
    *   `DeeperHub.ServerPackages.Schema.PackageFeature` (Opcional): Para detalhar os benefícios de um pacote.
*   **Cache (`DeeperHub.ServerPackages.Cache` ou via `Core.Cache`):**
    *   Cache para definições de pacotes frequentemente acessadas, especialmente para listagens em páginas de servidores.
*   **Integrações:**
    *   `DeeperHub.Core.Repo`: Para persistência.
    *   `DeeperHub.Servers`: Para associar pacotes a servidores.
    *   `DeeperHub.Billing` / `DeeperHub.Subscriptions` (Potencial): Para a lógica de compra/assinatura.
    *   `DeeperHub.Core.Internationalization (I18n)`: Para descrições de pacotes localizadas.

**Padrões de Design:**

*   **Fachada (Facade).**
*   **Serviço de Domínio.**

### 3.1. Componentes Principais

*   **`DeeperHub.ServerPackages.ServerPackagesFacade`:** Ponto de entrada.
*   **`DeeperHub.ServerPackages.Services.PackageService`:** Lógica de negócio.
*   **`DeeperHub.ServerPackages.Schema.ServerPackage`:** Schema principal.
*   **`DeeperHub.ServerPackages.Supervisor`:** Supervisiona processos.

### 3.3. Decisões de Design Importantes

*   **Flexibilidade dos Pacotes:** O schema `ServerPackage` deve ser flexível o suficiente para acomodar diferentes tipos de ofertas (assinaturas, itens únicos, bundles).
*   **Integração com Pagamentos:** Definir claramente a fronteira de responsabilidade entre este módulo (definição do que é vendável) e um módulo de Billing/Pagamentos (processamento da transação).

## 🛠️ 4. Casos de Uso Principais

*   **Proprietário de Servidor Cria um Pacote VIP:** O dono de um servidor define um pacote \"VIP Mensal\" que oferece acesso a áreas exclusivas e um item no jogo por R$19,90/mês.
*   **Usuário Visualiza Pacotes de um Servidor:** Um jogador visita a página de um servidor e vê os diferentes pacotes de assinatura ou itens que pode adquirir.
*   **Sistema Lista Pacotes em Destaque:** A plataforma pode destacar pacotes populares ou promocionais.
*   **Administrador Desabilita um Pacote:** Um pacote que viola as políticas da plataforma é desabilitado por um administrador.

## 🌊 5. Fluxos Importantes (Opcional)

**Fluxo de Criação de um Novo Pacote de Servidor:**

1.  Proprietário do servidor (via UI/API) submete os dados para um novo pacote.
2.  `DeeperHub.API` (Controller) chama `DeeperHub.ServerPackages.create_server_package(params)`.
3.  `ServerPackagesFacade` delega para `DeeperHub.ServerPackages.Services.PackageService.create_package(params)`.
4.  `PackageService`:
    *   Valida os `params` usando `ServerPackage.changeset/2`.
    *   Verifica se o `user_id` (dos `params` ou do contexto da sessão) é o proprietário do `server_id` associado.
    *   Se válido, cria o registro `ServerPackage` no banco de dados via `Core.Repo`.
    *   (Opcional) Cria registros `PackageFeature` associados.
    *   Invalida caches relevantes (ex: cache de pacotes para aquele servidor).
    *   Publica um evento `ServerPackageCreatedEvent` no `Core.EventBus`.
5.  Retorna `{:ok, package_criado}`.

## 📡 6. API (Se Aplicável)

### 6.1. `DeeperHub.ServerPackages.create_server_package/1`

*   **Descrição:** Cria um novo pacote de itens ou serviços para um servidor.
*   **`@spec`:** `create_server_package(attrs :: map()) :: {:ok, ServerPackage.t()} | {:error, Ecto.Changeset.t() | reason}`
*   **Parâmetros:**
    *   `attrs` (map): Atributos do pacote.
        *   `:server_id` (String, obrigatório): ID do servidor ao qual o pacote pertence.
        *   `:created_by_user_id` (String, obrigatório): ID do usuário que está criando o pacote (geralmente o dono do servidor).
        *   `:name` (String, obrigatório): Nome do pacote (ex: \"Pacote VIP Ouro\").
        *   `:description` (String, obrigatório): Descrição detalhada do que o pacote inclui.
        *   `:price` (Decimal, opcional): Preço do pacote. Nulo se for gratuito.
        *   `:currency` (String, opcional): Código da moeda (ex: \"BRL\", \"USD\"). Obrigatório se `price` for definido.
        *   `:package_type` (atom, obrigatório): Tipo de pacote (ex: `:subscription`, `:one_time_purchase`, `:benefit`).
        *   `:duration_days` (integer, opcional): Duração do benefício/assinatura em dias (se aplicável).
        *   `:features` (list(String), opcional): Lista de features ou itens incluídos.
        *   `:is_active` (boolean, opcional): Se o pacote está ativo e disponível para compra/visualização. (Padrão: `true`)
        *   `:stock_quantity` (integer, opcional): Quantidade em estoque, se limitada.
*   **Retorno:** O pacote criado ou um changeset com erros.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    package_attrs = %{
      server_id: \"server_123\",
      created_by_user_id: \"user_abc\",
      name: \"Kit Inicial de Aventureiro\",
      description: \"Contém uma espada básica, 10 poções de cura e 100 moedas de ouro.\",
      price: Decimal.new(\"9.99\"),
      currency: \"USD\",
      package_type: :one_time_purchase,
      features: [\"Espada Básica\", \"10x Poção de Cura\", \"100x Moedas de Ouro\"],
      is_active: true
    }
    case DeeperHub.ServerPackages.create_server_package(package_attrs) do
      {:ok, package} -> Logger.info(\"Pacote #{package.id} - '#{package.name}' criado.\")
      {:error, reason} -> Logger.error(\"Falha ao criar pacote: #{inspect(reason)}\")
    end
    ```

### 6.2. `DeeperHub.ServerPackages.list_packages_for_server/2`

*   **Descrição:** Lista todos os pacotes disponíveis para um servidor específico.
*   **`@spec`:** `list_packages_for_server(server_id :: String.t(), opts :: Keyword.t()) :: {:ok, list(ServerPackage.t())} | {:error, reason}`
*   **Parâmetros:**
    *   `server_id` (String): O ID do servidor.
    *   `opts` (Keyword.t()): Opções de filtragem.
        *   `:is_active` (boolean): Filtrar apenas pacotes ativos. (Padrão: `true`)
        *   `:package_type` (atom): Filtrar por tipo de pacote.
        *   `:order_by` (Keyword.t()): Ordenação (ex: `[price: :asc]`).
*   **Retorno:** Lista de pacotes do servidor.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    {:ok, active_packages} = DeeperHub.ServerPackages.list_packages_for_server(\"server_123\", is_active: true)
    ```

*(Outras funções como `get_package_details/1`, `update_server_package/2`, `delete_server_package/1` seriam documentadas aqui).*

## ⚙️ 7. Configuração

*   **ConfigManager (`DeeperHub.Core.ConfigManager`):**
    *   `[:server_packages, :default_currency]`: Moeda padrão para preços se não especificada. (Padrão: `\"USD\"`)
    *   `[:server_packages, :max_features_per_package]`: Número máximo de features listadas por pacote.
    *   `[:server_packages, :allow_free_packages]`: (Boolean) Se permite a criação de pacotes com preço zero. (Padrão: `true`)
    *   `[:server_packages, :cache_ttl_seconds]`: TTL para o cache de definições de pacotes.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.Repo`
*   `DeeperHub.Core.ConfigManager`
*   `DeeperHub.Core.Cache`
*   `DeeperHub.Servers` (para associação `server_id`)
*   `DeeperHub.Accounts` (para `created_by_user_id`)
*   `DeeperHub.Core.Internationalization (I18n)` (para descrições localizadas)
*   `DeeperHub.Billing` ou `DeeperHub.Subscriptions` (Potencial, para processar a compra)
*   `DeeperHub.Core.Logger`, `DeeperHub.Core.Metrics`

### 8.2. Bibliotecas Externas

*   `Ecto`
*   `Decimal` (para coordenação de preços)

## 🤝 9. Como Usar / Integração

*   **UI/Frontend:** Exibe os pacotes disponíveis na página de um servidor para os usuários.
*   **API de Gerenciamento:** Proprietários de servidor e administradores interagem com a API para criar e gerenciar pacotes.
*   **Módulo de Billing/Pagamento:** Quando um usuário decide adquirir um pacote, o módulo de Billing seria acionado, usando as informações (preço, etc.) deste módulo.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar CRUD de pacotes.
*   Testar validações de preço, moeda, tipo de pacote.
*   Testar a listagem de pacotes com diferentes filtros.
*   Testar o controle de ativação/desativação.
*   Localização: `test/deeper_hub/server_packages/`

### 10.2. Métricas

*   `deeper_hub.server_packages.created.count` (Contador): Tags: `server_id`, `package_type`.
*   `deeper_hub.server_packages.updated.count` (Contador): Tags: `package_id`.
*   `deeper_hub.server_packages.viewed.count` (Contador): (Se houver uma página de detalhes do pacote) Tags: `package_id`.
*   `deeper_hub.server_packages.active.gauge` (Gauge): Número total de pacotes ativos. Tags: `server_id`.

### 10.3. Logs

*   `Logger.info(\"Pacote '#{name}' (ID: #{id}) criado para o servidor #{server_id}\", module: DeeperHub.ServerPackages.Services.PackageService)`
*   `Logger.info(\"Pacote #{id} atualizado.\", module: DeeperHub.ServerPackages.Services.PackageService)`

### 10.4. Telemetria

*   `[:deeper_hub, :server_packages, :created | :updated | :deleted]`

## ❌ 11. Tratamento de Erros

*   `{:error, :server_not_found}`
*   `{:error, :package_not_found}`
*   `{:error, :unauthorized_action}` (ex: usuário tentando criar pacote para servidor que não é dele).
*   Falhas na validação dos dados do pacote (changeset errors).

## 🛡️ 12. Considerações de Segurança

*   **Validação de Preços:** Garantir que os preços sejam validados corretamente e não possam ser coordenados.
*   **Permissões:** Apenas proprietários de servidor ou administradores devem poder criar/editar pacotes.
*   **Descrição do Pacote:** Sanitizar a descrição e nome do pacote para prevenir XSS se exibidos diretamente.

## 🧑‍💻 13. Contribuição

*   Novos tipos de pacotes ou modelos de precificação podem ser adicionados com cuidado, considerando a integração com o sistema de Billing.
*   A lógica de concessão de benefícios/itens do pacote após a compra residiria no módulo de Billing ou em um sistema de inventário, que seria acionado após o pagamento.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Suporte para pacotes com preços variáveis ou descontos.
*   [ ] Integração com um sistema de inventário para itens virtuais concedidos por pacotes.
*   [ ] Suporte para \"gifting\" de pacotes para outros usuários.
*   [ ] Limitar o número de pacotes que um servidor pode oferecer.
*   [ ] Análise de popularidade e conversão de pacotes.

---

*Última atualização: YYYY-MM-DD*

---

O próximo seria `DeeperHub.ServerAlerts`. Prontos?"""),
            ],
        ),
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(text="""Sim, pode vir..."""),
            ],
        ),
        types.Content(
            role="model",
            parts=[
                types.Part.from_text(text="""Perfeito! Vamos ao README do `DeeperHub.ServerAlerts`.

---

