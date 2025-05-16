# Módulo: `Deeper_Hub.GeoIP` 🌎

## 📜 1. Visão Geral do Módulo `Deeper_Hub.GeoIP`

O módulo `Deeper_Hub.GeoIP` é responsável por obter informações de geolocalização (como país, cidade, região, coordenadas, ISP) a partir de um endereço IP. Ele atua como uma interface centralizada para interagir com serviços de geolocalização externos ou bases de dados locais, abstraindo os detalhes da implementação específica e incorporando mecanismos de resiliência como Circuit Breaker e cache. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Lookup de Endereço IP:**
    *   Receber um endereço IP e retornar dados geográficos associados.
    *   Suporte para IPv4 e IPv6.
*   **Abstração de Provedor de GeoIP:**
    *   Interface para um ou mais provedores de GeoIP (ex: MaxMind GeoLite2/GeoIP2, IP-API, DB-IP, etc.).
    *   Permitir a troca de provedores com configuração mínima.
*   **Cache de Resultados:**
    *   Armazenar em cache os resultados de lookups de IP para reduzir a latência e o número de chamadas a serviços externos (usando `Deeper_Hub.Core.Cache`).
    *   Configuração de TTL para as entradas do cache.
*   **Integração com Circuit Breaker:**
    *   Utilizar o `Deeper_Hub.Core.CircuitBreakerFactory` para proteger o sistema contra falhas ou lentidão de serviços de GeoIP externos.
    *   Fallback para uma base de dados local (se disponível e configurada) ou para um resultado padrão/nulo quando o circuito estiver aberto.
*   **Logging e Métricas:**
    *   Registrar lookups, acertos/erros de cache, e o estado do Circuit Breaker.
    *   Coletar métricas de latência, taxa de sucesso/erro das consultas aos provedores.
*   **Atualização de Base de Dados Local (Opcional):**
    *   Se usar uma base de dados local (ex: arquivos MaxMind DB), fornecer mecanismos ou scripts para sua atualização periódica.
*   **Normalização de Dados:**
    *   Retornar os dados geográficos em um formato padronizado, independentemente do provedor.

## 🏗️ 3. Arquitetura e Design

`Deeper_Hub.GeoIP` será uma fachada que interage com um ou mais adaptadores de provedores de GeoIP, utilizando o `Core.HTTPClient` (para APIs externas) e o `Core.Cache`.

*   **Interface Pública (`Deeper_Hub.GeoIP.GeoIPFacade` ou `Deeper_Hub.GeoIP`):** Função principal `lookup/2`.
*   **Adaptador(es) de Provedor (`Deeper_Hub.GeoIP.Adapters.<ProviderName>Adapter`):**
    *   Implementa a lógica específica para consultar um provedor de GeoIP (ex: `MaxMindDBAdapter` para arquivos locais, `IPAPIAdapter` para uma API HTTP).
    *   A seleção do adaptador ou a ordem de preferência pode ser configurada.
*   **Struct de Resposta (`Deeper_Hub.GeoIP.LocationData`):** Estrutura padronizada para os dados de geolocalização.
*   **Integração com `Core.HTTPClient`:** Para adaptadores que consomem APIs externas.
*   **Integração com `Core.Cache`:** Para armazenar resultados de lookups.
*   **Integração com `Core.CircuitBreakerFactory`:** Para chamadas a APIs externas.
*   **Integração com `Core.ConfigManager`:** Para URLs de API, chaves, caminhos de DB local, TTLs de cache.

**Padrões de Design:**

*   **Fachada (Facade):** Simplifica o uso do serviço de GeoIP.
*   **Adaptador (Adapter):** Para diferentes provedores de GeoIP.
*   **Circuit Breaker:** Para resiliência com serviços externos.
*   **Cache-Aside:** Para performance.

### 3.1. Componentes Principais

*   **`Deeper_Hub.GeoIP.GeoIPFacade` (ou `Deeper_Hub.GeoIP`):** Ponto de entrada.
*   **`Deeper_Hub.GeoIP.LocationData` (Struct):** `%{country_code: \"US\", country_name: \"United States\", region_name: \"California\", city_name: \"Mountain View\", latitude: 37.422, longitude: -122.084, isp: \"Google LLC\", organization: \"Google LLC\", timezone: \"America/Los_Angeles\", postal_code: \"94043\", asn: 15169}`.
*   **`Deeper_Hub.GeoIP.AdapterBehaviour` (Novo Sugerido):** Comportamento para adaptadores de provedor.
*   **Exemplos de Adaptadores:**
    *   `Deeper_Hub.GeoIP.Adapters.MaxMindDBAdapter` (para arquivos `.mmdb`)
    *   `Deeper_Hub.GeoIP.Adapters.IPAPIAdapter` (para `ip-api.com`)
*   **`Deeper_Hub.GeoIP.Cache` (Novo Sugerido, ou usa `Core.Cache` com namespace):** Gerencia o cache de lookups.
*   **`Deeper_Hub.GeoIP.Supervisor` (Opcional):** Se houver processos de longa duração, como um atualizador de DB.

### 3.3. Decisões de Design Importantes

*   **Escolha do(s) Provedor(es):** Decidir quais provedores de GeoIP usar (gratuitos, pagos, locais, baseados em API) e a estratégia de fallback entre eles.
*   **Precisão vs. Performance:** Balancear a necessidade de dados precisos com a performance do lookup e os custos de provedores pagos.
*   **Formato do Banco de Dados Local:** Se for usar um DB local, escolher o formato (ex: MaxMind DB) e o processo de atualização.

## 🛠️ 4. Casos de Uso Principais

*   **Módulo `Security.LoginLocation` enriquece dados de login:** Ao rastrear um login, este módulo chama `GeoIP.lookup(ip_address)` para obter o país/cidade da tentativa de login.
*   **Módulo `Auth` avalia risco da sessão:** Usa dados do `GeoIP` para verificar se o login vem de um país de alto risco.
*   **Módulo `Analytics` segmenta usuários por região:** Usa dados do `GeoIP` para relatórios geográficos.
*   **Módulo `API` aplica rate limiting geográfico:** Limita o acesso a certos endpoints com base no país de origem do IP.

## 🌊 5. Fluxos Importantes (Opcional)

**Fluxo de Lookup de IP com Cache e Circuit Breaker (para API externa):**

1.  Outro módulo chama `Deeper_Hub.GeoIP.lookup(ip_address, opts)`.
2.  `GeoIP` verifica se o resultado para `ip_address` está no `Core.Cache`.
3.  **Cache Hit:** Se encontrado e válido, retorna os dados cacheados.
4.  **Cache Miss:**
    *   Seleciona o adaptador do provedor configurado (ex: `IPAPIAdapter`).
    *   `IPAPIAdapter` utiliza `Core.HTTPClient` para fazer a chamada à API externa. A chamada HTTP é envolvida por um `Core.CircuitBreaker`.
    *   **HTTP Sucesso:**
        *   A resposta da API é parseada e normalizada para a struct `LocationData`.
        *   Os dados são armazenados no `Core.Cache` com o TTL configurado.
        *   Retorna `{:ok, location_data}`.
    *   **HTTP Falha (ou Circuito Aberto):**
        *   Tenta um provedor de fallback, se configurado (ex: DB local).
        *   Se o fallback falhar ou não existir, retorna `{:error, reason}`.
5.  O resultado é retornado ao módulo chamador.

## 📡 6. API (Se Aplicável)

### 6.1. `Deeper_Hub.GeoIP.lookup/2`

*   **Descrição:** Obtém informações de geolocalização para um endereço IP.
*   **`@spec`:** `lookup(ip_address :: String.t(), opts :: Keyword.t()) :: {:ok, LocationData.t()} | {:error, reason :: atom()}`
*   **Parâmetros:**
    *   `ip_address` (String): O endereço IP (IPv4 ou IPv6) a ser consultado.
    *   `opts` (Keyword.t()): Opções adicionais.
        *   `:provider_preference` (list(atom())): Ordem de preferência dos provedores (ex: `[:maxmind_db, :ip_api]`).
        *   `:skip_cache` (boolean): Se `true`, ignora o cache e força uma nova consulta. (Padrão: `false`)
        *   `:timeout_ms` (integer): Timeout específico para esta consulta.
*   **Retorno:**
    *   `{:ok, %Deeper_Hub.GeoIP.LocationData{}}`: Em caso de sucesso, com os dados de geolocalização.
    *   `{:error, :not_found}`: Se o IP não for encontrado ou não tiver dados geográficos.
    *   `{:error, :service_unavailable}`: Se o serviço de GeoIP estiver indisponível (ex: circuito aberto).
    *   `{:error, :invalid_ip}`: Se o formato do IP for inválido.
    *   `{:error, reason}`: Outros erros.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    case Deeper_Hub.GeoIP.lookup(\"8.8.8.8\") do
      {:ok, location} ->
        IO.puts(\"País: #{location.country_name}, Cidade: #{location.city_name}\")
      {:error, reason} ->
        Logger.error(\"Falha ao obter GeoIP para 8.8.8.8: #{reason}\")
    end
    ```

## ⚙️ 7. Configuração

*   **ConfigManager (`Deeper_Hub.Core.ConfigManager`):**
    *   `[:geoip, :default_provider_order]`: Lista de átomos representando a ordem de preferência dos provedores de GeoIP (ex: `[:maxmind_local, :ip_api_com]`).
    *   `[:geoip, :providers, :provider_name, :api_key]`: Chave de API para um provedor específico.
    *   `[:geoip, :providers, :provider_name, :api_url]`: URL da API para um provedor específico.
    *   `[:geoip, :providers, :maxmind_local, :db_path]`: Caminho para o arquivo do banco de dados MaxMind GeoLite2/GeoIP2.
    *   `[:geoip, :cache, :enabled]`: (Boolean) Habilita/desabilita o cache de lookups. (Padrão: `true`)
    *   `[:geoip, :cache, :ttl_seconds]`: TTL para entradas de cache de GeoIP. (Padrão: `86400` - 1 dia)
    *   `[:geoip, :circuit_breaker, :service_name, :config]`: Configurações do Circuit Breaker para cada provedor de API externa.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `Deeper_Hub.Core.HTTPClient`: Para interagir com APIs de GeoIP.
*   `Deeper_Hub.Core.Cache`: Para cachear resultados de lookup.
*   `Deeper_Hub.Core.CircuitBreakerFactory`: Para proteger chamadas a APIs externas.
*   `Deeper_Hub.Core.ConfigManager`: Para configurações.
*   `Deeper_Hub.Core.Logger`: Para logging.
*   `Deeper_Hub.Core.Metrics`: Para métricas.

### 8.2. Bibliotecas Externas

*   Opcionalmente, uma biblioteca para ler arquivos MaxMind DB (ex: `geolix` ou `maxminddb_reader`).
*   Biblioteca HTTP (via `Core.HTTPClient`).

## 🤝 9. Como Usar / Integração

Outros módulos devem chamar `Deeper_Hub.GeoIP.lookup/2` para obter dados de geolocalização.

```elixir
defmodule Deeper_Hub.Security.LoginAttemptAnalyzer do
  alias Deeper_Hub.GeoIP

  def analyze_login_ip(ip_address) do
    case GeoIP.lookup(ip_address) do
      {:ok, geo_data} ->
        # Usar geo_data.country_code, geo_data.city_name, etc. para análise de risco
        IO.inspect(geo_data)
      {:error, _reason} ->
        # Lidar com a falha de lookup (ex: considerar como risco maior ou ignorar)
        :unknown_location
    end
  end
end
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar lookups para IPs válidos e inválidos.
*   Testar o funcionamento do cache (hits e misses).
*   Testar o comportamento do Circuit Breaker simulando falhas do serviço externo.
*   Testar o fallback para provedores secundários ou DB local.
*   Mockar chamadas HTTP para provedores externos.
*   Localização: `test/deeper_hub/geoip/`

### 10.2. Métricas

*   `deeper_hub.geoip.lookup.duration_ms` (Histograma): Duração dos lookups de GeoIP. Tags: `provider`, `cache_status` (hit/miss).
*   `deeper_hub.geoip.lookup.count` (Contador): Número total de lookups. Tags: `provider`, `status` (success/failure).
*   `deeper_hub.geoip.cache.hit_ratio` (Gauge): Taxa de acerto do cache de GeoIP.
*   `deeper_hub.geoip.provider.error.count` (Contador): Erros por provedor. Tags: `provider`, `error_reason`.
*   `deeper_hub.geoip.circuit_breaker.state_changed.count` (Contador): Mudanças de estado do Circuit Breaker por provedor. Tags: `provider`, `new_state`.

### 10.3. Logs

*   `Logger.debug(\"GeoIP lookup para #{ip_address} via #{provider}. Cache: #{status}\", module: Deeper_Hub.GeoIP)`
*   `Logger.error(\"Falha no GeoIP lookup para #{ip_address} via #{provider}: #{reason}\", module: Deeper_Hub.GeoIP)`
*   `Logger.warning(\"GeoIP Circuit Breaker para #{provider} abriu.\", module: Deeper_Hub.GeoIP)`

### 10.4. Telemetria

*   `[:deeper_hub, :geoip, :lookup, :start | :stop | :exception]`: Para cada tentativa de lookup. Payload: `%{ip_address: ip, provider: provider_name}`.

## ❌ 11. Tratamento de Erros

*   Retorna `{:error, :invalid_ip}` para IPs malformados.
*   Retorna `{:error, :not_found}` se o IP não for encontrado em nenhum provedor.
*   Retorna `{:error, :service_unavailable}` se todos os provedores estiverem indisponíveis (ex: Circuit Breakers abertos e sem fallback).
*   Falhas internas devem retornar `{:error, :internal_error}`.

## 🛡️ 12. Considerações de Segurança

*   **Privacidade de IP:** Embora o IP seja usado para lookup, os dados geográficos retornados podem ser sensíveis dependendo do uso.
*   **Precisão do Provedor:** A precisão dos dados de GeoIP varia entre provedores e para diferentes regiões. Não deve ser usado como a única fonte para decisões críticas de segurança sem considerar a margem de erro.
*   **Rate Limiting de APIs Externas:** Respeitar os limites de taxa das APIs de GeoIP externas para evitar bloqueios. O `Core.HTTPClient` e `Core.CircuitBreaker` ajudam nisso.

## 🧑‍💻 13. Contribuição

*   Ao adicionar um novo adaptador de provedor, implementar o `Deeper_Hub.GeoIP.AdapterBehaviour`.
*   Garantir que os dados retornados sejam normalizados para a struct `LocationData`.
*   Adicionar configurações relevantes ao `ConfigManager`.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar um worker para atualização automática de bancos de dados GeoIP locais (ex: MaxMind).
*   [ ] Adicionar suporte para lookup reverso (coordenadas para endereço).
*   [ ] Permitir a configuração de \"precisão desejada\" para escolher dinamicamente entre provedores (ex: um gratuito para baixa precisão, um pago para alta).
*   [ ] Integrar com um serviço de reputação de IP para enriquecer os dados retornados.

---

*Última atualização: YYYY-MM-DD*

---

Continuamos com `Deeper_Hub.Mailer`?"""),
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
                types.Part.from_text(text="""Beleza! Agora vamos para o README do `Deeper_Hub.Mailer`.

---

