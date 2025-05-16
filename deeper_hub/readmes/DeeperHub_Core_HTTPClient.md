# Módulo: `Deeper_Hub.Core.HTTPClient` 🚀

## 📜 1. Visão Geral do Módulo `Deeper_Hub.Core.HTTPClient`

O módulo `Deeper_Hub.Core.HTTPClient` é o responsável centralizado por todas as chamadas HTTP externas realizadas pelo sistema Deeper_Hub. Ele fornece uma interface unificada e padronizada para interagir com APIs de terceiros, serviços externos ou qualquer outro recurso acessível via HTTP/S. O objetivo é abstrair as bibliotecas HTTP subjacentes (como Finch, Tesla, HTTPoison, etc.), facilitar o teste, e integrar funcionalidades transversais como logging, métricas e, opcionalmente, Circuit Breakers. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Interface Unificada para Requisições HTTP:**
    *   Suporte aos métodos HTTP comuns: `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `HEAD`, `OPTIONS`.
    *   Configuração de cabeçalhos (headers) da requisição.
    *   Envio de corpo (body) da requisição em diferentes formatos (JSON, form-urlencoded, etc.).
    *   Configuração de timeouts (conexão, recebimento).
    *   Suporte para autenticação HTTP básica e por token (Bearer).
*   **Abstração da Biblioteca HTTP:**
    *   Permite trocar a biblioteca HTTP subjacente com mínimo impacto no restante do sistema.
    *   Centraliza a configuração da biblioteca HTTP (pools de conexão, SSL, etc.).
*   **Tratamento Padronizado de Respostas:**
    *   Parseamento automático do corpo da resposta (ex: JSON para mapa Elixir).
    *   Retorno padronizado `{:ok, %HTTPResponse{}}` ou `{:error, %HTTPError{}}`.
    *   `%HTTPResponse{}` incluiria status code, headers, corpo da resposta (parseado e bruto).
    *   `%HTTPError{}` incluiria o motivo da falha (ex: `:timeout`, `:connection_refused`, `:non_2xx_status`), status code (se aplicável), e corpo do erro.
*   **Integração com Observabilidade (Logging e Métricas):**
    *   Registro automático de todas as requisições e respostas (níveis de log configuráveis).
    *   Coleta de métricas para cada requisição (duração, status code, taxa de sucesso/erro) por host/serviço.
    *   Integração com o `Deeper_Hub.Core.Logger` e `Deeper_Hub.Core.Metrics`.
*   **Integração Opcional com Circuit Breaker:**
    *   Permite envolver chamadas HTTP com um `Deeper_Hub.Core.CircuitBreaker` para proteger o sistema contra serviços externos instáveis.
    *   Configurável por host de destino ou serviço.
*   **Retentativas (Retry) Configuráveis:**
    *   Suporte para retentativas automáticas em caso de falhas transitórias (ex: erros de rede, status 5xx) com backoff exponencial.
*   **Gerenciamento de SSL/TLS:**
    *   Configuração de certificados SSL/TLS para conexões seguras.
*   **Streaming de Respostas (Opcional, se necessário):**
    *   Suporte para processar grandes respostas HTTP de forma incremental.
*   **Mocking para Testes:**
    *   Facilita o mocking de requisições HTTP em ambientes de teste.

## 🏗️ 3. Arquitetura e Design

O `Deeper_Hub.Core.HTTPClient` provavelmente será uma fachada que utiliza um ou mais adaptadores para bibliotecas HTTP específicas.

*   **Interface Pública (`Deeper_Hub.Core.HTTPClient`):** Define as funções como `get/3`, `post/4`, etc.
*   **Adaptador (ex: `Deeper_Hub.Core.HTTPClient.FinchAdapter`, `Deeper_Hub.Core.HTTPClient.TeslaAdapter`):**
    *   Implementa a lógica específica para interagir com a biblioteca HTTP escolhida.
    *   A seleção do adaptador pode ser feita via configuração no `ConfigManager`.
*   **Structs de Resposta (`HTTPResponse`, `HTTPError`):** Estruturas de dados padronizadas para representar respostas e erros.
*   **Integração com `Core.ConfigManager`:** Para obter configurações de timeouts, URLs base de serviços, configurações de Circuit Breaker, etc.
*   **Integração com `Core.CircuitBreakerFactory`:** Para obter ou criar instâncias de Circuit Breaker para hosts específicos.
*   **Integração com `Core.Logger` e `Core.Metrics`:** Para registrar detalhes e desempenho das chamadas.

**Padrões de Design:**

*   **Fachada (Facade):** Simplifica a interface para um subsistema complexo.
*   **Adaptador (Adapter):** Permite que interfaces incompatíveis trabalhem juntas.
*   **Strategy (Opcional):** Para diferentes estratégias de retry ou tratamento de erros.

### 3.1. Componentes Principais

*   **`Deeper_Hub.Core.HTTPClient`:** A fachada principal.
*   **`Deeper_Hub.Core.HTTPClient.AdapterBehaviour` (Novo Sugerido):** Um comportamento que os adaptadores de biblioteca HTTP devem implementar.
*   **`Deeper_Hub.Core.HTTPClient.Adapters.FinchAdapter` (Exemplo):** Uma implementação concreta do adaptador para a biblioteca Finch.
*   **`Deeper_Hub.Core.HTTPClient.Response`:** Struct para respostas bem-sucedidas.
*   **`Deeper_Hub.Core.HTTPClient.Error`:** Struct para respostas de erro.
*   **`Deeper_Hub.Core.HTTPClient.Config` (Novo Sugerido):** Módulo para gerenciar configurações específicas do HTTPClient, como User-Agent padrão, timeouts globais, etc.

### 3.3. Decisões de Design Importantes

*   **Abstração da Biblioteca:** A decisão de usar adaptadores permite flexibilidade para mudar a biblioteca HTTP no futuro sem reescrever o código que consome o `HTTPClient`.
*   **Retorno Padronizado:** Usar structs `HTTPResponse` e `HTTPError` garante que os chamadores sempre recebam dados de forma consistente, independentemente da biblioteca subjacente.
*   **Circuit Breaker por Serviço/Host:** Permite isolar falhas de serviços externos específicos.

## 🛠️ 4. Casos de Uso Principais

*   **Módulo `OAuth` chama API de um provedor externo:** O módulo `Deeper_Hub.OAuth` usa `HTTPClient.post/4` para trocar um código de autorização por um token de acesso com um provedor OAuth como Google ou Facebook.
*   **Módulo `Webhooks` envia um evento para um endpoint externo:** O módulo `Deeper_Hub.Webhooks` usa `HTTPClient.post/4` para enviar um payload JSON para uma URL de webhook configurada por um cliente.
*   **Módulo `GeoIP` consulta um serviço de geolocalização:** O módulo `Deeper_Hub.GeoIP` usa `HTTPClient.get/3` para buscar informações de geolocalização para um endereço IP.
*   **Módulo `Notifications` envia email via API SMTP (ex: SendGrid):** O módulo `Deeper_Hub.Notifications` usa `HTTPClient.post/4` para enviar um email através da API de um provedor de email.

## 🌊 5. Fluxos Importantes (Opcional)

**Fluxo de uma Requisição `POST` com Circuit Breaker:**

1.  O módulo chamador (ex: `Deeper_Hub.OAuth`) invoca `Deeper_Hub.Core.HTTPClient.post(url, body, headers, opts)`.
2.  `HTTPClient` identifica o host de destino a partir da `url`.
3.  Verifica no `ConfigManager` se um Circuit Breaker está configurado para este host/serviço.
4.  Se sim, solicita ao `Core.CircuitBreakerFactory.get_breaker(service_name)` para obter a instância do Circuit Breaker.
5.  Executa a chamada HTTP através do Circuit Breaker: `CircuitBreaker.call(breaker_name, fn -> HTTPClient.Adapter.post(url, body, headers, opts) end)`.
6.  O `HTTPClient.Adapter` (ex: `FinchAdapter`) realiza a chamada HTTP real.
    *   Métricas de início de chamada são registradas.
    *   Logging da requisição é feito.
7.  O Adaptador recebe a resposta da biblioteca HTTP.
8.  A resposta é normalizada para `{:ok, %HTTPResponse{}}` ou `{:error, %HTTPError{}}`.
9.  Métricas de fim de chamada (duração, status) são registradas.
10. Logging da resposta é feito.
11. O resultado normalizado é retornado ao `HTTPClient`.
12. O Circuit Breaker é atualizado (sucesso/falha).
13. O `HTTPClient` retorna o resultado ao módulo chamador.

## 📡 6. API (Se Aplicável)

### 6.1. `Deeper_Hub.Core.HTTPClient.get/3`

*   **Descrição:** Realiza uma requisição HTTP GET.
*   **`@spec`:** `get(url :: String.t(), headers :: Keyword.t() | map(), opts :: Keyword.t()) :: {:ok, HTTPResponse.t()} | {:error, HTTPError.t()}`
*   **Parâmetros:**
    *   `url` (String): A URL completa para a requisição.
    *   `headers` (Keyword.t() | map()): Cabeçalhos da requisição. (Padrão: `[]`)
    *   `opts` (Keyword.t()): Opções adicionais.
        *   `:timeout` (integer): Timeout em milissegundos. (Padrão: `5000`)
        *   `:circuit_breaker` (atom | String.t()): Nome do serviço/host para usar com Circuit Breaker. (Padrão: `nil`)
        *   `:retries` (integer): Número de retentativas. (Padrão: `0`)
        *   `:params` (Keyword.t() | map()): Parâmetros de query string.
*   **Retorno:**
    *   `{:ok, %HTTPResponse{status_code: integer(), headers: list(), body: term()}}`
    *   `{:error, %HTTPError{reason: atom(), status_code: integer() | nil, body: term() | nil}}`
*   **Exemplo de Uso (Elixir):**
    ```elixir
    case Deeper_Hub.Core.HTTPClient.get(\"https://api.example.com/data\", [{\"Authorization\", \"Bearer token\"}], timeout: 10000) do
      {:ok, response} -> IO.inspect(response.body)
      {:error, error} -> Logger.error(\"HTTP GET falhou: #{inspect(error)}\")
    end
    ```

### 6.2. `Deeper_Hub.Core.HTTPClient.post/4`

*   **Descrição:** Realiza uma requisição HTTP POST.
*   **`@spec`:** `post(url :: String.t(), body :: term(), headers :: Keyword.t() | map(), opts :: Keyword.t()) :: {:ok, HTTPResponse.t()} | {:error, HTTPError.t()}`
*   **Parâmetros:**
    *   `url` (String): A URL completa para a requisição.
    *   `body` (term()): O corpo da requisição (será codificado para JSON por padrão, a menos que `Content-Type` especifique outro formato).
    *   `headers` (Keyword.t() | map()): Cabeçalhos da requisição. (Padrão: `[]`)
    *   `opts` (Keyword.t()): Opções adicionais (mesmas de `get/3` mais opções de codificação de corpo).
        *   `:encode_body_as` (:json, :form, :raw_binary): Como codificar o corpo. (Padrão: `:json`)
*   **Retorno:**
    *   `{:ok, %HTTPResponse{}}`
    *   `{:error, %HTTPError{}}`
*   **Exemplo de Uso (Elixir):**
    ```elixir
    payload = %{name: \"Test\", value: 123}
    headers = [{\"Content-Type\", \"application/json\"}]
    case Deeper_Hub.Core.HTTPClient.post(\"https://api.example.com/submit\", payload, headers, []) do
      {:ok, response} -> Logger.info(\"POST bem-sucedido: #{response.status_code}\")
      {:error, error} -> Logger.error(\"HTTP POST falhou: #{inspect(error)}\")
    end
    ```

*(Outras funções como `put/4`, `delete/3` seguiriam um padrão similar)*

## ⚙️ 7. Configuração

O `HTTPClient` pode ser configurado através do `Deeper_Hub.Core.ConfigManager`.

*   **ConfigManager:**
    *   `[:core, :http_client, :default_timeout_ms]`: Timeout padrão para requisições HTTP em milissegundos. (Padrão: `5000`)
    *   `[:core, :http_client, :default_user_agent]`: String User-Agent padrão para as requisições. (Padrão: `\"Deeper_Hub HTTPClient/1.0\"`)
    *   `[:core, :http_client, :default_retries]`: Número padrão de retentativas. (Padrão: `0`)
    *   `[:core, :http_client, :default_retry_delay_ms]`: Atraso base para retentativas. (Padrão: `1000`)
    *   `[:core, :http_client, :adapter_module]`: Módulo do adaptador HTTP a ser usado (ex: `Deeper_Hub.Core.HTTPClient.Adapters.FinchAdapter`). (Padrão: `Deeper_Hub.Core.HTTPClient.Adapters.FinchAdapter`)
    *   `[:core, :http_client, :services, :service_name, :base_url]`: URL base para um serviço específico.
    *   `[:core, :http_client, :services, :service_name, :circuit_breaker_config]`: Configuração do Circuit Breaker para um serviço.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `Deeper_Hub.Core.ConfigManager`: Para configurações.
*   `Deeper_Hub.Core.Logger`: Para logging.
*   `Deeper_Hub.Core.Metrics`: Para métricas.
*   `Deeper_Hub.Core.CircuitBreakerFactory`: Para gerenciamento de Circuit Breakers.
*   Biblioteca HTTP subjacente (ex: `Finch`, `Tesla`) – através do adaptador.

### 8.2. Bibliotecas Externas

*   Biblioteca HTTP escolhida (ex: `Finch`).
*   `Jason`: Para manipulação de JSON (se for o padrão).

## 🤝 9. Como Usar / Integração

Outros módulos devem usar as funções públicas de `Deeper_Hub.Core.HTTPClient` para fazer requisições HTTP.

```elixir
# Exemplo de uso em outro módulo
defmodule Deeper_Hub.MyService do
  alias Deeper_Hub.Core.HTTPClient
  alias Deeper_Hub.Core.Logger

  def fetch_external_data(user_id) do
    url = \"https://some.api.com/user_data/#{user_id}\"
    headers = [{\"X-API-Key\", \"mysecretkey\"}]
    opts = [timeout: 10_000, circuit_breaker: :some_api_service]

    case HTTPClient.get(url, headers, opts) do
      {:ok, response} ->
        Logger.info(\"Dados externos recebidos para #{user_id}: #{response.status_code}\")
        {:ok, response.body} # Supondo que o body já foi parseado para um mapa
      {:error, error} ->
        Logger.error(\"Falha ao buscar dados externos para #{user_id}: #{inspect(error)}\")
        {:error, :external_api_failed}
    end
  end
end
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testes unitários devem cobrir a lógica da fachada e dos adaptadores.
*   Testes de integração devem usar mocks para a biblioteca HTTP subjacente (ex: `Finch.Test`) para simular respostas de APIs externas.
*   Localização: `test/deeper_hub/core/http_client/`

### 10.2. Métricas

*   `deeper_hub.core.http_client.request.duration_ms` (Histograma): Duração das requisições HTTP. Tags: `host`, `method`, `status_code_class` (2xx, 4xx, 5xx), `service_name` (se `circuit_breaker` usado).
*   `deeper_hub.core.http_client.request.count` (Contador): Número total de requisições. Tags: `host`, `method`, `status_code`, `service_name`.
*   `deeper_hub.core.http_client.request.success.count` (Contador): Requisições bem-sucedidas (status 2xx). Tags: `host`, `method`, `service_name`.
*   `deeper_hub.core.http_client.request.failure.count` (Contador): Requisições falhas (status 4xx, 5xx, timeouts, etc.). Tags: `host`, `method`, `reason`, `service_name`.
*   `deeper_hub.core.http_client.circuit_breaker.state_changed.count` (Contador): Mudanças de estado do Circuit Breaker. Tags: `service_name`, `new_state` (:open, :closed, :half_open).

### 10.3. Logs

*   Requisições iniciadas: `Logger.debug(\"HTTP #{method} #{url} iniciando\", %{request_id: id, headers: sanitized_headers, body: sanitized_body})`
*   Respostas recebidas: `Logger.info(\"HTTP #{method} #{url} respondida com #{status_code} em #{duration_ms}ms\", %{request_id: id, response_body: sanitized_response_body})`
*   Erros: `Logger.error(\"HTTP #{method} #{url} falhou: #{reason}\", %{request_id: id, error_details: inspect(error_struct)})`
*   Logs devem incluir um `request_id` único para correlação.

### 10.4. Telemetria

Eventos Telemetry podem ser emitidos para cada fase da requisição:
*   `[:deeper_hub, :core, :http_client, :request, :start]`
*   `[:deeper_hub, :core, :http_client, :request, :stop]`
*   `[:deeper_hub, :core, :http_client, :request, :exception]`

Esses eventos podem ser usados pelo `Core.Metrics` para popular as métricas descritas acima.

## ❌ 11. Tratamento de Erros

*   Retorna `{:ok, %HTTPResponse{}}` para respostas HTTP bem-sucedidas (status 2xx).
*   Retorna `{:error, %HTTPError{reason: :http_error, status_code: code, ...}}` para respostas HTTP com status não-2xx (ex: 4xx, 5xx).
*   Retorna `{:error, %HTTPError{reason: :timeout}}` para timeouts de conexão ou recebimento.
*   Retorna `{:error, %HTTPError{reason: :connection_failed}}` para falhas de conexão.
*   Retorna `{:error, %HTTPError{reason: :circuit_open}}` se a chamada for bloqueada pelo Circuit Breaker e não houver fallback.
*   Outros erros podem ser `{:error, %HTTPError{reason: :internal_error, details: ...}}`.

## 🛡️ 12. Considerações de Segurança

*   **Sanitização de Logs:** URLs, cabeçalhos e corpos de requisição/resposta devem ser sanitizados antes de serem logados para evitar vazamento de dados sensíveis (ex: tokens em headers, PII no corpo).
*   **Tratamento de Segredos:** Chaves de API e outros segredos usados em headers ou body devem ser gerenciados de forma segura (ex: via `Core.ConfigManager` com flags `is_sensitive`).
*   **Validação de URLs:** As URLs de destino devem ser validadas para prevenir SSRF (Server-Side Request Forgery) se as URLs puderem ser influenciadas por entrada do usuário.
*   **SSL/TLS:** Por padrão, deve impor o uso de HTTPS e validar certificados, a menos que explicitamente configurado de outra forma para ambientes de desenvolvimento/teste.
*   **Timeouts:** Configurar timeouts adequados para evitar que o sistema fique preso esperando por respostas de serviços lentos.

## 🧑‍💻 13. Contribuição

*   Ao adicionar suporte para uma nova biblioteca HTTP, crie um novo módulo adaptador que implemente o `Deeper_Hub.Core.HTTPClient.AdapterBehaviour`.
*   Mantenha a interface pública da fachada `HTTPClient` consistente.
*   Garanta que todas as chamadas sejam logadas e metrificadas adequadamente.
*   Adicione testes para qualquer nova funcionalidade ou correção.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Adicionar suporte para autenticação mTLS (mutual TLS).
*   [ ] Implementar um sistema de cache HTTP mais robusto (respeitando Cache-Control, ETags, etc.).
*   [ ] Suporte para proxies HTTP/S.
*   [ ] Permitir configuração de estratégias de retry mais granulares por serviço ou tipo de erro.
*   [ ] Integração com um sistema de tracing distribuído (ex: OpenTelemetry).

---

*Última atualização: YYYY-MM-DD*

---

O que acha deste primeiro README? Podemos seguir para o próximo (`Core.Internationalization (I18n)`)?"""),
            ],
        ),
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(text="""próximo"""),
            ],
        ),
        types.Content(
            role="model",
            parts=[
                types.Part.from_text(text="""Perfeito! Vamos para o README do `Core.Internationalization (I18n)`.

---

