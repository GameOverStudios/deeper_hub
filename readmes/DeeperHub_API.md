# Módulo: `Deeper_Hub.API` 🚀

## 📜 1. Visão Geral do Módulo `Deeper_Hub.API`

O módulo `Deeper_Hub.API` é responsável por definir, gerenciar e proteger a Interface de Programação de Aplicativos (API) RESTful do sistema Deeper_Hub. Ele serve como o principal ponto de interação para clientes externos (aplicações web, mobile, serviços de terceiros) consumirem as funcionalidades e dados do Deeper_Hub.

Este módulo foca em fornecer uma API robusta, segura, versionada e bem documentada, incluindo mecanismos para limitação de taxa (Rate Limiting) e validação de requisições. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Definição de Endpoints RESTful:**
    *   Mapeamento de rotas HTTP para controllers e ações específicas.
    *   Suporte aos verbos HTTP padrão (GET, POST, PUT, PATCH, DELETE).
*   **Validação de Requisições:**
    *   Validação de parâmetros de query, path e corpo da requisição (via `Deeper_Hub.API.Validation.APIRequestValidator`).
    *   Validação de tipos de dados, formatos e regras de negócio.
*   **Limitação de Taxa (Rate Limiting):**
    *   Controle do número de requisições por cliente/IP/token em um determinado período (via `Deeper_Hub.API.RateLimit.RateLimiterFacade` e `Deeper_Hub.API.RateLimiter` Plug).
    *   Prevenção de abusos e sobrecarga da API.
    *   Retorno de cabeçalhos HTTP padrão para rate limiting (ex: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `Retry-After`).
*   **Autenticação e Autorização de API (Delegação):**
    *   Integrar com `Deeper_Hub.Auth` para autenticar requisições (ex: via tokens de API, JWTs de sessão).
    *   Verificar se o cliente autenticado tem permissão para acessar o recurso/endpoint solicitado.
*   **Versionamento da API:**
    *   Suporte a diferentes versões da API para permitir evolução sem quebrar clientes existentes (ex: `/api/v1/...`, `/api/v2/...`).
*   **Formatação de Respostas:**
    *   Utilizar `Deeper_Hub.Core.APIResponder` para padronizar o formato das respostas JSON (sucesso, erro, validação).
*   **Documentação da API:**
    *   Facilitar a geração de documentação interativa (ex: OpenAPI/Swagger) a partir das definições de endpoint e schemas de validação.
*   **Tratamento de Erros da API:**
    *   Converter erros internos e de validação em respostas HTTP apropriadas e padronizadas.
*   **Gerenciamento de CORS (Cross-Origin Resource Sharing):**
    *   Configurar políticas de CORS para permitir ou restringir acesso de diferentes origens.
*   **Caching de Respostas (Opcional):**
    *   Integrar com `Deeper_Hub.Core.Cache` para armazenar em cache respostas de endpoints frequentemente acessados e com dados pouco voláteis.

## 🏗️ 3. Arquitetura e Design

O módulo `Deeper_Hub.API` normalmente reside na camada de interface do sistema, interagindo com os módulos de domínio (como `Deeper_Hub.Accounts`, `Deeper_Hub.Servers`, etc.) para processar requisições e com os módulos Core para funcionalidades transversais.

### 3.1. Componentes Principais

1.  **Router (ex: `Deeper_HubWeb.Router` se usando Phoenix):**
    *   **Responsabilidade:** Define as rotas da API, mapeando URLs e métodos HTTP para os respectivos `Controllers`.
    *   **Interações:** Aplica Plugs de middleware para autenticação, rate limiting, validação, etc.
2.  **Controllers (ex: `Deeper_HubWeb.API.V1.UserController`):**
    *   **Responsabilidade:** Receber requisições HTTP, extrair parâmetros, chamar os módulos de serviço/fachadas de domínio apropriados, e formatar a resposta.
    *   **Interações:**
        *   Utiliza `Deeper_Hub.Core.APIResponder` para formatar respostas.
        *   Chama fachadas de domínio (ex: `Deeper_Hub.Accounts.get_user/1`).
        *   Pode interagir com `Deeper_Hub.Auth.authorize/4` para verificações de permissão finas.
3.  **Plugs (Middleware):**
    *   **`Deeper_Hub.API.RateLimiter`:** Plug para aplicar limitação de taxa antes de atingir o controller.
    *   **`Deeper_Hub.API.Validation.APIRequestValidator`:** Plug para validar parâmetros da requisição contra um schema.
    *   **Plugs de Autenticação:** Para verificar tokens e carregar o usuário/cliente autenticado.
    *   **Plug de CORS:** Para gerenciar cabeçalhos CORS.
    *   **Plug de Logging de Requisição:** (ex: `Deeper_Hub.Logger.PhoenixIntegration.RequestLogger`) para logar detalhes de cada requisição.
4.  **`Deeper_Hub.API.RateLimit.RateLimiterFacade` e `Deeper_Hub.API.RateLimit.Registry`:**
    *   **Responsabilidade:** Fornecem a lógica de negócio e o estado para o sistema de rate limiting.
    *   **Interações:** Utilizados pelo Plug `Deeper_Hub.API.RateLimiter`.
5.  **`Deeper_Hub.API.Validation.APIRequestValidator`:**
    *   **Responsabilidade:** Fornece a lógica para validação de schemas de requisição.
    *   **Interações:** Utilizado como Plug ou diretamente pelos controllers.
6.  **Schemas de Validação (ex: em `Deeper_Hub.API.Validation.Schemas`):**
    *   **Responsabilidade:** Definir a estrutura esperada e as regras de validação para os dados de entrada de cada endpoint. Podem ser baseados em Ecto Changesets ou bibliotecas como `Params`.

### 3.2. Estrutura de Diretórios (Proposta com Phoenix)

```
lib/deeper_hub_web/ # (Se usando Phoenix)
├── api/
│   ├── v1/ # Para versionamento
│   │   ├── user_controller.ex
│   │   ├── server_controller.ex
│   │   └── ... (outros controllers da v1)
│   │
│   └── v2/ # Futura versão
│       └── ...
│
├── plugs/
│   ├── auth_api_token_plug.ex
│   └── ... (outros plugs customizados para a API)
│
└── router.ex # Define os pipelines e escopos da API

api/ # Lógica de negócio da API, independente do Phoenix
├── rate_limit/
│   ├── rate_limiter_facade.ex
│   ├── registry.ex
│   └── supervisor.ex
│
├── validation/
│   ├── api_request_validator.ex
│   └── schemas/
│       ├── user_schemas.ex
│       └── ...
│
├── rate_limiter.ex # Plug de Rate Limit (se não estiver em _web)
└── supervisor.ex   # Supervisor para os GenServers de RateLimit
```

### 3.3. Decisões de Design Importantes

*   **Stateless API:** A API deve ser o mais stateless possível, com o estado do cliente gerenciado por tokens.
*   **Versionamento:** O versionamento da API (ex: no path `/api/v1/`) é crucial para permitir atualizações e novas funcionalidades sem quebrar integrações existentes.
*   **Validação na Entrada:** Todas as entradas devem ser rigorosamente validadas o mais cedo possível no ciclo da requisição para garantir a integridade dos dados e proteger contra payloads maliciosos.
*   **Padronização de Respostas:** Usar um formato consistente para todas as respostas (sucesso e erro) melhora a experiência do desenvolvedor que consome a API.
*   **Segurança como Prioridade:** Autenticação, autorização, rate limiting e outras medidas de segurança devem ser aplicadas de forma robusta.

## 🛠️ 4. Casos de Uso Principais

*   **Cliente Web Obtém Lista de Servidores:**
    *   O frontend envia um `GET /api/v1/servers?tag=pvp&page=2`.
    *   A requisição passa por Plugs de autenticação (opcional), rate limiting.
    *   `ServerController.index/2` é chamado.
    *   O controller valida os parâmetros de query.
    *   Chama `Deeper_Hub.Servers.list_servers(%{tag: \"pvp\", page: 2})`.
    *   Formata a resposta usando `APIResponder.format_success/3` e retorna JSON.
*   **Aplicativo Mobile Cria um Novo Usuário:**
    *   O app envia `POST /api/v1/users` com dados do usuário no corpo.
    *   Plugs de rate limiting e `APIRequestValidator` (para o corpo) são executados.
    *   `UserController.create/2` é chamado.
    *   Chama `Deeper_Hub.Accounts.register_user(params)`.
    *   Retorna uma resposta de sucesso (201 Created) ou erro de validação (422).
*   **Serviço Externo Atualiza Status (com Token de API):**
    *   Serviço envia `PUT /api/v1/services/{service_id}/status` com header `Authorization: Bearer <api_token>`.
    *   Plug de autenticação de API valida o token.
    *   Rate limiting específico para tokens de API é aplicado.
    *   Controller apropriado verifica permissões do token e atualiza o status.

## 🌊 5. Fluxos Importantes

### Fluxo de uma Requisição API Típica (com Phoenix)

1.  **Requisição HTTP:** Cliente envia requisição (ex: `GET /api/v1/me`).
2.  **Endpoint Phoenix:** Recebe a requisição.
3.  **Pipeline de Plugs (definido no Router):**
    *   `Plug.Telemetry`: Inicia telemetria da requisição.
    *   `Plug.Parsers`: Parseia o corpo da requisição (se houver).
    *   `MyAppWeb.Plugs.AuthApiTokenPlug` (ou similar): Verifica o token de autenticação no header, carrega `current_user_id` ou `current_client_id`. Se falhar, pode retornar 401.
    *   `Deeper_Hub.API.RateLimiter`: Verifica se a requisição excede os limites de taxa. Se sim, retorna 429.
    *   `Deeper_Hub.API.Validation.APIRequestValidator` (se configurado para a rota): Valida parâmetros de query/corpo. Se falhar, retorna 422.
    *   Outros plugs (CORS, etc.).
4.  **Router Phoenix:** Direciona a requisição para o Controller e Ação apropriados (ex: `UserController.show_me/2`).
5.  **Controller (`UserController.show_me/2`):**
    *   Obtém `current_user_id` da `conn.assigns`.
    *   Chama o serviço de domínio: `Deeper_Hub.Accounts.get_user(current_user_id)`.
    *   Recebe a resposta do serviço (`{:ok, user}` ou `{:error, reason}`).
    *   Usa `Deeper_Hub.Core.APIResponder` para formatar a resposta JSON.
        *   Ex: `APIResponder.format_success(user_data_map)` ou `APIResponder.format_error(reason)`.
    *   Envia a resposta para o cliente com o status HTTP apropriado (ex: `json(conn, formated_response)`).
6.  **Plug.Telemetry (Saída):** Finaliza a telemetria da requisição.

## 📡 6. API (Endpoints RESTful)

Esta seção deve detalhar os principais endpoints da API. Dada a natureza genérica deste módulo, os endpoints específicos seriam definidos pelos módulos de domínio que expõem funcionalidades via API. No entanto, o módulo `API` define *como* esses endpoints são estruturados e protegidos.

**Exemplo de Definição de um Grupo de Endpoints (conceptual):**

### `GET /api/v1/users/{user_id}`

*   **Descrição:** Retorna os detalhes de um usuário específico.
*   **Autenticação:** Requer token de acesso válido (sessão ou API).
*   **Autorização:** O usuário solicitante deve ter permissão para ver o perfil do `user_id` (ex: ser o próprio usuário ou um administrador).
*   **Parâmetros de Caminho:**
    *   `user_id` (string, UUID): ID do usuário a ser buscado.
*   **Resposta de Sucesso (200 OK):**
    ```json
    {
      \"status\": \"success\",
      \"data\": {
        \"id\": \"uuid-user-123\",
        \"email\": \"user@example.com\", // Pode ser omitido dependendo das permissões
        \"profile\": {
          \"full_name\": \"John Doe\",
          \"bio\": \"Developer\"
        }
      },
      \"message\": null,
      \"meta\": null
    }
    ```
*   **Respostas de Erro:**
    *   `401 Unauthorized`: Token inválido ou ausente.
    *   `403 Forbidden`: Usuário autenticado não tem permissão.
    *   `404 Not Found`: Usuário não encontrado.
    *   `429 Too Many Requests`: Limite de taxa excedido.

*(Esta seção seria populada com os endpoints reais à medida que são definidos).*

## ⚙️ 7. Configuração

Configurações gerenciadas pelo `Deeper_Hub.Core.ConfigManager`:

*   **Rate Limiting (prefixo: `[:api, :rate_limit, <endpoint_key>]`):**
    *   `... :limit` (Integer): Número máximo de requisições.
    *   `... :window_seconds` (Integer): Janela de tempo em segundos.
    *   `... :block_seconds` (Integer): Duração do bloqueio após exceder o limite.
    *   Exemplo: `[:api, :rate_limit, :users_index, :limit] = 100`
*   **Validação (geralmente por schema, não globalmente no ConfigManager para APIRequestValidator):**
    *   `[:api, :validation, :strict_mode_enabled]` (Boolean): Se `APIRequestValidator` deve rejeitar campos desconhecidos. (Padrão: `true`)
*   **Versionamento:**
    *   `[:api, :default_version]` (String): Versão padrão da API se nenhuma for especificada (ex: `\"v1\"`).
    *   `[:api, :supported_versions]` (List de Strings): Lista de versões da API atualmente suportadas.
*   **CORS:**
    *   `[:api, :cors, :origins]` (List de Strings ou Regex): Origens permitidas.
    *   `[:api, :cors, :methods]` (List de Strings): Métodos HTTP permitidos.
    *   `[:api, :cors, :headers]` (List de Strings): Cabeçalhos permitidos.
*   **Documentação:**
    *   `[:api, :docs, :openapi_spec_path]` (String): Caminho para o arquivo de especificação OpenAPI.
    *   `[:api, :docs, :ui_enabled]` (Boolean): Habilita a UI do Swagger/OpenAPI.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `Deeper_Hub.Core.ConfigManager`: Para configurações de rate limiting, versionamento, etc.
*   `Deeper_Hub.Core.APIResponder`: Para padronizar respostas.
*   `Deeper_Hub.Core.Logger`: Para logging de requisições e erros.
*   `Deeper_Hub.Core.Metrics`: Para métricas de API (latência, taxa de erro, etc.).
*   `Deeper_Hub.Auth`: Para autenticação e autorização de requisições.
*   Módulos de domínio (ex: `Deeper_Hub.Accounts`, `Deeper_Hub.Servers`): Para acessar a lógica de negócio.

### 8.2. Bibliotecas Externas

*   `Phoenix` (se for o framework web): Para routing, controllers, plugs.
*   `Jason`: Para manipulação de JSON.
*   `Plug` (Elixir): Para a arquitetura de middleware.
*   Bibliotecas de validação de parâmetros (ex: `Params`, `Ecto.Changeset` para validação de corpo).
*   Bibliotecas de OpenAPI/Swagger para geração de documentação (ex: `OpenApiSpex`).

## 🤝 9. Como Usar / Integração

*   **Consumidores da API:** Devem seguir a documentação da API (idealmente gerada por OpenAPI) para entender os endpoints, formatos de requisição/resposta e autenticação.
*   **Desenvolvedores do Deeper_Hub:**
    *   Ao adicionar novos endpoints, definir rotas no Router.
    *   Criar Controllers para lidar com a lógica da requisição.
    *   Definir schemas de validação para os dados de entrada usando `Deeper_Hub.API.Validation.APIRequestValidator` ou similar.
    *   Configurar regras de rate limiting para os novos endpoints em `Deeper_Hub.API.RateLimiter`.
    *   Utilizar `Deeper_Hub.Core.APIResponder` para formatar todas as respostas.
    *   Integrar com `Deeper_Hub.Auth` para proteger os endpoints.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   **Testes de Integração/Controlador:** Para cada endpoint, testar:
    *   Respostas de sucesso (2xx).
    *   Erros de validação de entrada (422).
    *   Erros de autenticação (401).
    *   Erros de autorização (403).
    *   Recurso não encontrado (404).
    *   Rate limiting (429).
    *   Formato correto da resposta JSON.
*   **Testes de Plugs:** Testes unitários para plugs customizados (rate limiter, validador).
*   Localização: `test/deeper_hub_web/api/v1/` (para controllers), `test/deeper_hub/api/` (para lógica de negócio da API).

### 10.2. Métricas

*   `deeper_hub.api.http.requests.total` (Contador, tags: `path`, `method`, `status_code`): Número total de requisições.
*   `deeper_hub.api.http.requests.duration_ms` (Histograma, tags: `path`, `method`): Latência das requisições.
*   `deeper_hub.api.rate_limit.throttled.count` (Contador, tags: `path`, `client_id`): Número de requisições bloqueadas por rate limiting.
*   `deeper_hub.api.validation.errors.count` (Contador, tags: `path`, `field`): Número de erros de validação.

### 10.3. Logs

*   Cada requisição HTTP deve ser logada (via `RequestLogger`), incluindo método, path, status code, duração, IP do cliente, user_id (se autenticado).
*   Erros de validação e exceções nos controllers devem ser logados com detalhes.

### 10.4. Telemetria

Phoenix já emite muitos eventos de telemetria para o ciclo de vida da requisição. O módulo `API` pode adicionar eventos específicos:
*   `[:deeper_hub, :api, :rate_limit, :exceeded]`
    *   Metadados: `%{path: path, client_id: id, limit: limit, window: window}`
*   `[:deeper_hub, :api, :validation, :failed]`
    *   Metadados: `%{path: path, errors: errors_map}`

## ❌ 11. Tratamento de Erros

*   Utilizar `Deeper_Hub.Core.APIResponder` para garantir que todas as respostas de erro sigam um formato padronizado (ex: JSON:API error objects).
*   Mapear exceções comuns (ex: `Ecto.NoResultsError` para 404, erros de autorização para 403) para os status HTTP corretos.
*   Evitar vazar detalhes internos do sistema (stack traces) em respostas de erro para o cliente em ambiente de produção.

## 🛡️ 12. Considerações de Segurança

*   **Autenticação e Autorização:** Todos os endpoints (exceto os explicitamente públicos) devem ser protegidos.
*   **Validação de Entrada:** Validar *todos* os dados provenientes do cliente.
*   **Rate Limiting:** Essencial para prevenir abuso.
*   **Sanitização de Saída:** Embora geralmente o `APIResponder` lide com JSON, garantir que nenhum dado sensível ou script seja inadvertidamente incluído em respostas.
*   **Segurança de Cabeçalhos:** Usar cabeçalhos de segurança HTTP apropriados (CSP, HSTS, X-Frame-Options, etc.), geralmente configurados no nível do endpoint web.
*   **Proteção contra Ataques Comuns:** CSRF (para APIs baseadas em sessão/cookie), XSS (se a API retorna HTML ou permite upload de conteúdo que é renderizado), Injeção de SQL (prevenindo na camada de serviço/dados).
*   **Gerenciamento de Tokens de API:** Tokens de API devem ser tratados como segredos, ter escopos limitados e permitir revogação.

## 🧑‍💻 13. Contribuição

*   Ao adicionar novos endpoints, siga o padrão RESTful.
*   Documente os endpoints usando o padrão OpenAPI/Swagger.
*   Adicione schemas de validação para todas as novas requisições.
*   Configure regras de rate limiting apropriadas.
*   Escreva testes de integração abrangentes.

## 📝 14. Respostas Padronizadas da API

O módulo `Deeper_Hub.Core.APIResponder` é responsável por padronizar todas as respostas da API, garantindo consistência e facilitando o consumo pelos clientes.

### 14.1 Formatos de Resposta

1. **Resposta de Sucesso**:
   ```elixir
   # Formato
   %{
     "status" => "success",
     "data" => %{...},       # Dados da resposta
     "meta" => %{...},       # Metadados opcionais (paginacao, etc)
     "message" => "Mensagem opcional"
   }
   ```

2. **Resposta de Erro**:
   ```elixir
   %{
     "status" => "error",
     "error" => %{
       "code" => "codigo_do_erro",
       "message" => "Mensagem de erro amigável",
       "details" => %{}  # Detalhes adicionais do erro
     }
   }
   ```

3. **Erros de Validação**:
   ```elixir
   %{
     "status" => "error",
     "error" => %{
       "code" => "validation_error",
       "message" => "Erro de validação",
       "details" => %{
         "email" => ["não pode ficar em branco"],
         "password" => ["deve ter no mínimo 8 caracteres"]
       }
     }
   }
   ```

### 14.2 Mapeamento de Códigos de Erro

| Código do Erro        | Status HTTP | Descrição                          |
|----------------------|-------------|----------------------------------|
| `:bad_request`       | 400         | Requisição inválida               |
| `:unauthorized`      | 401         | Não autenticado                   |
| `:forbidden`         | 403         | Acesso negado                     |
| `:not_found`         | 404         | Recurso não encontrado            |
| `:conflict`          | 409         | Conflito (ex: recurso já existe)  |
| `:unprocessable_entity` | 422     | Erro de validação                |
| `:too_many_requests` | 429         | Muitas requisições                |
| `:internal_server_error` | 500    | Erro interno do servidor         |

## 📚 15. Documentação da API

A documentação da API é gerada automaticamente usando OpenAPI (Swagger) e está disponível em `/api/documentation` quando o ambiente for `:dev` ou `:test`.

### 15.1 Como documentar um endpoint

```elixir
defmodule Deeper_HubWeb.API.V1.UserController do
  use Deeper_HubWeb, :controller
  use PhoenixSwagger   # Adicione esta linha

  @doc """
  Lista usuários

  ## Parâmetros
    * page - Número da página (opcional, padrão: 1)
    * per_page - Itens por página (opcional, padrão: 20, máximo: 100)

  """
  swagger_path :index do
    get "/api/v1/users"
    description "Lista usuários com paginação"
    produces "application/json"
    parameter :query, :page, :integer, "Número da página", required: false
    parameter :query, :per_page, :integer, "Itens por página", required: false
    response 200, "Success", :Users
    response 400, "Bad Request"
    response 401, "Unauthorized"
  end

  def index(conn, params) do
    # Implementação do controller
  end
end
```

## 🔄 16. Configuração de CORS

O Deeper_Hub usa o plug `CORSPlug` para gerenciar políticas de CORS. A configuração é feita no arquivo `config/config.exs`:

```elixir
config :cors_plug,
  origin: [
    "https://app.Deeper_Hub.com",
    ~r{^https://[a-z0-9-]+\\.Deeper_Hub\\.com$}
  ],
  methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  headers: ["Authorization", "Content-Type", "Accept", "X-Requested-With"],
  max_age: 86400,
  credentials: true
```

### 16.1 Configurações por Ambiente

1. **Desenvolvimento (`:dev`)**
   - Origens amplas para facilitar o desenvolvimento local
   - Headers de depuração habilitados

2. **Produção (`:prod`)**
   - Origens restritas apenas aos domínios oficiais
   - Headers mínimos necessários
   - Tempo de cache maior

## 💾 17. Caching de Respostas

O módulo `Deeper_Hub.API.Cache` fornece funções para cache de respostas de API usando o `Deeper_Hub.Core.Cache`.

### 17.1 Estratégias de Cache

1. **Cache por Tempo de Vida (TTL)**:
   ```elixir
   def get_users(conn, params) do
     cache_key = "users:#{params["page"]}:#{params["per_page"]}"
     
     case API.Cache.get(cache_key) do
       {:ok, cached} -> 
         json(conn, cached)
       _ ->
         users = Accounts.list_users(params)
         response = APIResponder.format_success(users)
         :ok = API.Cache.put(cache_key, response, ttl: 300) # 5 minutos
         json(conn, response)
     end
   end
   ```

2. **Cache por ETag**:
   ```elixir
   def show_user(conn, %{"id" => id}) do
     user = Accounts.get_user!(id)
     etag = :crypto.hash(:md5, "#{user.id}-#{user.updated_at}") |> Base.encode16(case: :lower)
     
     conn
     |> put_resp_header("etag", etag)
     |> API.Cache.conditional_get(etag)
     |> case do
       :not_modified -> 
         send_resp(conn, 304, "")
       _ ->
         json(conn, APIResponder.format_success(user))
     end
   end
   ```

## 📊 18. Métricas e Monitoramento

O módulo `Deeper_Hub.API.Metrics` coleta e expõe métricas sobre o uso da API.

### 18.1 Métricas Coletadas

1. **Contadores**:
   - `api.requests.total` - Total de requisições
   - `api.requests.method.[GET|POST|PUT|...]` - Requisições por método
   - `api.requests.status.[2xx|3xx|4xx|5xx]` - Respostas por status
   - `api.requests.endpoint.[endpoint]` - Requisições por endpoint

2. **Tempos de Resposta**:
   - `api.response_time.[endpoint]` - Tempo de resposta por endpoint
   - `api.db_query_time` - Tempo gasto em consultas ao banco

3. **Tamanho das Respostas**:
   - `api.response_size.[endpoint]` - Tamanho das respostas

### 18.2 Configuração do Prometheus

```elixir
# config/prod.exs
config :deeper_hub, Deeper_Hub.API.Metrics,
  enable_metrics: true,
  metrics_port: 9568,
  path: "/metrics",
  auth: {:basic, "prometheus", "s3cr3t"}
```

## 🔮 19. Melhorias Futuras e TODOs

*   [ ] Implementar um sistema de quotas de API mais granular (além do rate limiting básico).
*   [ ] Adicionar suporte para WebSockets ou Server-Sent Events (SSE) para comunicação em tempo real, se necessário.
*   [ ] Melhorar a geração automática de documentação OpenAPI a partir do código.
*   [ ] Integrar com um API Gateway para gerenciamento mais avançado (ex: Kong, Tyk).
*   [ ] Adicionar suporte para negociação de conteúdo (ex: `Accept` header para diferentes formatos de resposta, embora JSON seja o principal).
*   [ ] Implementar caching de respostas HTTP (ETags, Cache-Control) para endpoints apropriados.

---

*Última atualização: 2025-05-11*

---

Este README para o `Deeper_Hub.API` tenta cobrir os aspectos de definição, proteção e gerenciamento da API.

Qual o próximo módulo? `Deeper_Hub.Security` seria uma boa continuação, dado que muitos aspectos da API dependem dele."""),
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
                types.Part.from_text(text="""Perfeito! Vamos agora mergulhar no `Deeper_Hub.Security`, um módulo guarda-chuva que coordena diversas funcionalidades de segurança cruciais para a robustez do Deeper_Hub.

---

