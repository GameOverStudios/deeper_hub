# Módulo: `DeeperHub.Security.GeoLocationService` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Security.GeoLocationService`

O módulo `DeeperHub.Security.GeoLocationService` é responsável por obter, analisar e gerenciar informações de geolocalização associadas a endereços IP dos usuários que interagem com o sistema DeeperHub. Ele fornece dados como país, região, cidade e, potencialmente, provedor de internet (ISP) e informações de ASN (Autonomous System Number) para um determinado IP.

Essas informações são cruciais para várias funcionalidades de segurança, incluindo:
*   Detecção de logins de locais incomuns ou de alto risco.
*   Análise de \"viagens impossíveis\" (quando um usuário parece logar de locais geograficamente distantes em um curto período).
*   Enriquecimento de dados para avaliação de risco e detecção de fraude.
*   Aplicação de políticas de acesso baseadas em geolocalização.

Este módulo tipicamente integra-se com serviços de GeoIP externos (como MaxMind GeoIP2, IPinfo.io, etc.) e/ou utiliza bases de dados GeoIP locais, com mecanismos de cache e circuit breaker para garantir performance e resiliência. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Lookup de IP para Geolocalização (`get_location/1` ou `lookup_ip/2`):**
    *   Obter dados de geolocalização (país, cidade, região, coordenadas, ISP, ASN) para um endereço IP.
    *   Suporte a diferentes provedores de GeoIP (externos ou bases de dados locais).
*   **Cache de Resultados de Geolocalização:**
    *   Armazenar em cache os resultados de lookups de IP para reduzir a latência e o custo de chamadas a serviços externos (via `DeeperHub.Security.Cache.GeoCache` ou similar).
*   **Proteção com Circuit Breaker:**
    *   Integrar com `DeeperHub.Core.CircuitBreakerFactory` ao chamar serviços GeoIP externos para prevenir falhas em cascata.
*   **Análise de Risco de Localização (`assess_location_risk/3`):**
    *   Avaliar o risco associado a uma determinada localização (ex: país de alto risco, proxy conhecido, Tor exit node).
*   **Detecção de Viagem Impossível (`is_impossible_travel?/3`):**
    *   Comparar a localização atual de um login com localizações anteriores para detectar movimentos geograficamente implausíveis em um curto período.
*   **Gerenciamento de Localizações Confiáveis e Bloqueadas (Integração):**
    *   Permitir que usuários ou administradores marquem certas localizações (ou países/regiões) como confiáveis ou bloqueadas (lógica gerenciada por `DeeperHub.SessionPolicy` ou `SecurityPolicyManager`).
    *   Validar se um IP pertence a uma lista de países permitidos/bloqueados.
*   **Atualização de Bases de Dados GeoIP (se locais):**
    *   Fornecer mecanismos ou recomendar processos para manter as bases de dados GeoIP locais atualizadas.
*   **Observabilidade:**
    *   Registrar métricas sobre lookups, acertos/erros de cache, latência de provedores externos.
    *   Logar erros e atividades importantes.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.Security.GeoLocationService` (Fachada Pública):**
    *   Ponto de entrada para todas as funcionalidades de geolocalização.
    *   Delega para um `GeoLocationAdapter` ou diretamente para um serviço interno.
2.  **`DeeperHub.Security.GeoLocationService.Adapter` (Behaviour e Implementações):**
    *   **Responsabilidade:** Abstrair a interação com diferentes provedores de GeoIP.
    *   **Implementações:**
        *   `MaxMindAdapter`: Para interagir com a API ou base de dados MaxMind GeoIP2.
        *   `IPinfoAdapter`: Para interagir com a API IPinfo.io.
        *   `LocalDbAdapter`: Para consultar uma base de dados GeoIP local (ex: baixada e atualizada periodicamente).
        *   `CompositeAdapter`: Para tentar múltiplos provedores em uma ordem de precedência.
3.  **`DeeperHub.Core.CircuitBreakerFactory` e Circuit Breakers específicos por provedor:**
    *   Usados pelos adaptadores de provedores externos para proteger o sistema.
    *   Exemplo: `DeeperHub.Infrastructure.GeoIP.GeoIPServiceWithCircuitBreaker` (da documentação original) pode ser renomeado ou integrado aqui.
4.  **`DeeperHub.Security.Cache.GeoCache` (GenServer ou ETS direta):**
    *   Armazena em cache os resultados de lookups de IP para evitar chamadas repetidas a serviços externos.
5.  **`DeeperHub.Security.GeoLocationService.RiskAnalyzer` (Módulo Funcional):**
    *   Contém a lógica para `assess_location_risk/3` e `is_impossible_travel?/3`.
    *   Pode consultar listas de países de alto risco, proxies conhecidos, etc. (configuráveis).
6.  **`DeeperHub.Security.LoginLocation.Schema.LocationHistory` e `TrustedLocation` (se persistência for usada):**
    *   Schemas Ecto para armazenar o histórico de login de usuários e localizações confiáveis. A lógica de gravação/leitura seria gerenciada por um serviço como `LoginLocationService` ou diretamente pelo `RiskAnalyzer`.
7.  **Configurações (via `DeeperHub.Core.ConfigManager` e `DeeperHub.Security.Policy.SecurityPolicyManager`):**
    *   Chaves de API para serviços GeoIP externos.
    *   Caminhos para bases de dados GeoIP locais.
    *   Configurações de cache (TTL).
    *   Listas de países de alto risco.
    *   Limiares para detecção de viagem impossível (velocidade máxima).

### 3.2. Estrutura de Diretórios (Proposta)

```
lib/deeper_hub/security/geo_location_service/ # Ou apenas geo_location.ex se for mais simples
├── geo_location_service.ex         # Fachada Pública
│
├── adapters/                       # Adaptadores para diferentes provedores GeoIP
│   ├── geo_location_adapter.ex     # Behaviour
│   ├── maxmind_adapter.ex
│   ├── ipinfo_adapter.ex
│   └── local_db_adapter.ex
│   └── composite_adapter.ex          # (Gerencia múltiplos provedores)
│
├── risk_analyzer.ex                # Lógica para assess_location_risk, is_impossible_travel
├── cache/                          # Cache específico para GeoLocation
│   └── geo_cache.ex                # (Pode reusar Core.Cache com namespace ou ser específico)
│
├── supervisor.ex                   # Supervisor para processos do GeoLocation (ex: Cache)
└── telemetry.ex
```
*(Nota: O módulo `DeeperHub.LoginLocation` da documentação original parece ter responsabilidades sobrepostas. A geolocalização de um IP é uma função, enquanto rastrear e analisar os *logins* de um *usuário* em diferentes localizações é outra. Podemos manter `GeoLocationService` focado no lookup de IP e na análise de risco da localização em si, e `LoginLocation` (ou um `UserLocationHistoryService`) focado no histórico e padrões do usuário.)*

### 3.3. Decisões de Design Importantes

*   **Abstração de Provedor:** Isolar a lógica de interação com provedores GeoIP específicos em adaptadores facilita a troca ou adição de provedores.
*   **Resiliência:** O uso de Circuit Breakers e cache é essencial para lidar com a indisponibilidade ou latência de serviços externos.
*   **Fallback:** Ter uma base de dados GeoIP local como fallback (mesmo que menos precisa) pode ser útil se os serviços externos falharem.
*   **Atualização de Dados:** Bases de dados GeoIP mudam. Um processo para atualizá-las regularmente é necessário se forem usadas localmente.

## 🛠️ 4. Casos de Uso Principais

*   **Verificar Localização de um Novo Login:**
    *   `DeeperHub.Auth` recebe um IP durante o login.
    *   Chama `GeoLocationService.get_location(ip_address)`.
    *   O resultado é usado pelo `RiskAssessment` para avaliar o risco do login.
*   **Detectar Viagem Impossível:**
    *   Após um login bem-sucedido, o `RiskAssessment` ou `Auth` obtém a localização atual e a compara com a última localização conhecida do usuário usando `GeoLocationService.is_impossible_travel?(last_location, current_location, time_diff)`.
*   **Bloquear Acesso de Países de Alto Risco:**
    *   Um Plug de segurança chama `GeoLocationService.assess_location_risk(ip_info)`.
    *   Se o risco for crítico devido ao país, a requisição pode ser bloqueada.
*   **Enriquecer Logs de Auditoria:**
    *   `DeeperHub.Audit` usa o `GeoLocationService` para adicionar informações de país/cidade aos logs de eventos.

## 🌊 5. Fluxos Importantes

### Fluxo de Lookup de IP (`get_location/1`)

1.  **Chamador:** Um módulo (ex: `RiskAssessment`) chama `GeoLocationService.get_location(ip_address)`.
2.  **`GeoLocationService` (Fachada):**
    *   Primeiro, tenta obter os dados do `GeoCache.get(ip_address)`.
3.  **`GeoCache`:**
    *   **Cache Hit:** Se encontrado e não expirado, retorna `{:ok, geo_data}` para a fachada.
    *   **Cache Miss:** Retorna `{:error, :not_found}`.
4.  **`GeoLocationService` (Fachada, em caso de Cache Miss):**
    *   Seleciona o `GeoLocationAdapter` configurado (ex: `CompositeAdapter`).
5.  **`GeoLocationAdapter` (ex: `CompositeAdapter`):**
    *   Tenta o primeiro provedor configurado (ex: `MaxMindAdapter`).
        *   **`MaxMindAdapter`:**
            *   Executa a chamada à API MaxMind (ou consulta DB local) através de um `CircuitBreaker`.
            *   **Sucesso:** Retorna `{:ok, geo_data_from_maxmind}`.
            *   **Falha (API/Circuito Aberto):** Tenta o próximo provedor no `CompositeAdapter`.
    *   Se um provedor retornar sucesso:
        *   `GeoCache.put(ip_address, geo_data_from_provider, ttl_configurado)`.
        *   Retorna `{:ok, geo_data_from_provider}` para a fachada.
    *   Se todos os provedores falharem:
        *   (Opcional) Tenta um fallback para uma base de dados local menos precisa.
        *   Retorna `{:error, :all_providers_failed_or_unavailable}`.
6.  **`GeoLocationService` (Fachada):** Retorna o resultado para o chamador.

## 📡 6. API (Funções Públicas da Fachada)

### 6.1. `DeeperHub.Security.GeoLocationService.get_location(ip_address :: String.t(), opts :: keyword()) :: {:ok, GeoData.t()} | {:error, reason :: atom()}`

*   **Descrição:** Obtém dados de geolocalização para um endereço IP.
*   **`opts`:**
    *   `:provider_preference` (list(atom)): Ordem de preferência dos provedores (ex: `[:maxmind, :ipinfo]`).
    *   `:skip_cache` (boolean): Se `true`, ignora o cache. (Padrão: `false`)
    *   `:timeout_ms` (integer): Timeout para provedores externos.
*   **`GeoData.t()`:** `%{ip_address: String.t(), country_code: String.t() | nil, country_name: String.t() | nil, region_code: String.t() | nil, region_name: String.t() | nil, city_name: String.t() | nil, postal_code: String.t() | nil, latitude: float() | nil, longitude: float() | nil, timezone: String.t() | nil, isp: String.t() | nil, organization: String.t() | nil, asn: String.t() | nil, is_proxy: boolean() | nil, is_tor_node: boolean() | nil, source_provider: atom()}`
*   **Retorno de Erro:** `:invalid_ip_format`, `:provider_unavailable`, `:lookup_failed`, `:cache_error`.
*   **Exemplo:**
    ```elixir
    case GeoLocationService.get_location(\"8.8.8.8\") do
      {:ok, geo_data} -> IO.inspect(geo_data.city_name) # \"Mountain View\"
      {:error, reason} -> Logger.error(\"GeoIP lookup failed: #{reason}\")
    end
    ```

### 6.2. `DeeperHub.Security.GeoLocationService.assess_location_risk(ip_address :: String.t() | GeoData.t(), opts :: keyword()) :: {:ok, LocationRisk.t()} | {:error, reason :: atom()}`

*   **Descrição:** Avalia o risco associado a um IP ou dados de geolocalização já obtidos.
*   **`opts`:**
    *   `:user_context` (map): Informações sobre o usuário para análise comparativa (ex: `%{usual_countries: [\"BR\", \"US\"]}`).
*   **`LocationRisk.t()`:** `%{risk_score: float(), risk_level: atom(), factors: list(%{factor: atom(), description: String.t(), score_impact: float()})}`.
    *   Fatores: `:high_risk_country`, `:proxy_detected`, `:tor_node`, `:inconsistent_with_user_history`.
*   **Exemplo:**
    ```elixir
    GeoLocationService.assess_location_risk(\"1.2.3.4\", user_context: %{usual_countries: [\"BR\"]})
    # {:ok, %{risk_score: 75.0, risk_level: :high, factors: [...]}}
    ```

### 6.3. `DeeperHub.Security.GeoLocationService.is_impossible_travel?(prev_location :: StoredLocation.t(), current_ip :: String.t(), current_timestamp :: DateTime.t() | nil, opts :: keyword()) :: {:ok, ImpossibleTravelResult.t()} | {:error, reason :: atom()}`

*   **Descrição:** Verifica se uma movimentação entre a `prev_location` (com seu timestamp) e a localização do `current_ip` (no `current_timestamp`) é geograficamente implausível.
*   **`StoredLocation.t()`:** `%{latitude: float(), longitude: float(), timestamp: DateTime.t()}`.
*   **`opts`:**
    *   `:max_credible_speed_kmh` (integer): Velocidade máxima considerada crível. (Padrão: config)
*   **`ImpossibleTravelResult.t()`:** `%{is_impossible: boolean(), calculated_speed_kmh: float() | nil, distance_km: float() | nil}`.
*   **Exemplo:**
    ```elixir
    last_loc = %{latitude: -23.55, longitude: -46.63, timestamp: DateTime.add(DateTime.utc_now(), -3600, :second)} # SP, 1 hora atrás
    GeoLocationService.is_impossible_travel?(last_loc, \"8.8.8.8\") # Mountain View, CA
    # {:ok, %{is_impossible: true, calculated_speed_kmh: 8000.0, ...}}
    ```

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager` e `DeeperHub.Security.Policy.SecurityPolicyManager`:

*   **`[:security, :geo_location, :enabled]`** (Boolean): Habilita/desabilita o serviço. (Padrão: `true`)
*   **`[:security, :geo_location, :default_provider_order]`** (List de Atoms): Ordem de preferência dos adaptadores de provedor GeoIP (ex: `[:maxmind_api, :ipinfo_api, :local_db]`).
*   **`[:security, :geo_location, :providers, :maxmind_api, :api_key]`** (String): Chave de API para MaxMind.
*   **`[:security, :geo_location, :providers, :ipinfo_api, :api_key]`** (String): Chave de API para IPinfo.
*   **`[:security, :geo_location, :providers, :local_db, :path]`** (String): Caminho para a base de dados GeoIP local.
*   **`[:security, :geo_location, :cache, :ttl_seconds]`** (Integer): TTL para entradas de geolocalização no cache. (Padrão: `86400` - 24 horas)
*   **`[:security, :geo_location, :risk, :high_risk_country_codes]`** (List de Strings): Lista de códigos de país ISO considerados de alto risco.
*   **`[:security, :geo_location, :risk, :known_proxy_ips_source]`** (String, opcional): URL ou caminho para uma lista de IPs de proxy conhecidos.
*   **`[:security, :geo_location, :risk, :impossible_travel_max_speed_kmh]`** (Integer): Velocidade máxima para detecção de viagem impossível. (Padrão: `800` km/h)

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.ConfigManager`, `Core.Logger`, `Core.Metrics`, `Core.Cache` (ou `Security.Cache.GeoCache`).
*   `DeeperHub.Core.CircuitBreakerFactory`: Para chamadas a APIs externas.
*   `DeeperHub.Core.HTTPClient`: Para realizar as chamadas HTTP aos provedores.
*   `DeeperHub.Security.Policy.SecurityPolicyManager`: Para obter listas de países de risco, etc.

### 8.2. Bibliotecas Externas

*   Bibliotecas cliente para provedores GeoIP (ex: se MaxMind fornecer um cliente Elixir).
*   `Jason` (ou similar) para parsear respostas JSON de APIs externas.
*   (Opcional) Bibliotecas para trabalhar com formatos de banco de dados GeoIP locais (ex: MaxMind DB Reader).

## 🤝 9. Como Usar / Integração

O `GeoLocationService` é primariamente consumido por outros módulos de segurança.

**Exemplo no `RiskAssessment`:**
```elixir
defp calculate_location_factors(ip_address, user_profile) do
  factors = 
    case DeeperHub.Security.GeoLocationService.get_location(ip_address) do
      {:ok, geo_data} ->
        location_risk_result = DeeperHub.Security.GeoLocationService.assess_location_risk(geo_data, user_context: user_profile.geo_history)
        
        travel_check = 
          if last_login = UserLoginHistory.get_last(user_profile.id) do
            DeeperHub.Security.GeoLocationService.is_impossible_travel?(last_login.location, ip_address)
          else
            {:ok, %{is_impossible: false}}
          end

        [
          %{factor: :country_risk, value: location_risk_result.risk_score},
          %{factor: :is_proxy, value: geo_data.is_proxy},
          %{factor: :impossible_travel, value: travel_check.is_impossible}
        ]
      {:error, _reason} ->
        [%{factor: :location_unknown, value: true}] # Penalidade se não conseguir obter dados
    end
  factors
end
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar cada adaptador de provedor GeoIP com mocks para as APIs externas.
*   Testar a lógica do `CompositeAdapter` para fallback entre provedores.
*   Testar a funcionalidade de cache (get, put, expiração).
*   Testar as funções de `RiskAnalyzer` (`assess_location_risk`, `is_impossible_travel`) com diferentes cenários.
*   Localização: `test/deeper_hub/security/geo_location_service/`.

### 10.2. Métricas

*   `deeper_hub.security.geo_location.lookup.count` (tags: `provider`, `status` (`success`, `failure`, `cache_hit`, `cache_miss`))
*   `deeper_hub.security.geo_location.lookup.duration_ms` (Histograma, tags: `provider`)
*   `deeper_hub.security.geo_location.cache.size.gauge`
*   `deeper_hub.security.geo_location.risk_assessment.count` (tags: `risk_level_calculated`)
*   `deeper_hub.security.geo_location.impossible_travel.detected.count`

### 10.3. Logs

*   **Nível DEBUG:** Detalhes da resposta de provedores GeoIP.
*   **Nível INFO:** Lookup de IP bem-sucedido (especialmente se não for do cache), detecção de viagem impossível.
*   **Nível WARNING:** Falha ao contatar um provedor GeoIP primário, fallback para outro provedor ou base local. Lookup de IP de país de alto risco.
*   **Nível ERROR:** Falha ao contatar todos os provedores GeoIP configurados e nenhum fallback disponível. Erros internos no serviço.

### 10.4. Telemetria

*   `[:deeper_hub, :security, :geo_location, :lookup, :start | :stop | :exception]`
    *   Metadados: `%{ip_address: ip, provider_used: provider, from_cache: boolean}`
    *   No `:stop`: `%{country_code: code, city: city}`
*   `[:deeper_hub, :security, :geo_location, :risk_analysis, :stop]`
    *   Metadados: `%{ip_address: ip, risk_score: score, risk_level: level}`
*   `[:deeper_hub, :security, :geo_location, :impossible_travel_check, :stop]`
    *   Metadados: `%{user_id: id, current_ip: ip, result: boolean, speed_kmh: speed}`

## ❌ 11. Tratamento de Erros

*   **Provedor Externo Indisponível:** O `CircuitBreaker` deve abrir para o provedor problemático. O `CompositeAdapter` deve tentar o próximo provedor na lista. Se todos falharem, pode-se usar uma base de dados local como fallback ou retornar um erro indicando que a geolocalização não pôde ser determinada.
*   **IP Inválido:** A função `get_location/1` deve validar o formato do IP e retornar um erro apropriado.
*   **Cache Indisponível:** Se o `GeoCache` falhar, o sistema deve tentar buscar diretamente dos provedores (com logging do erro do cache).

## 🛡️ 12. Considerações de Segurança (do próprio Módulo)

*   **Chaves de API:** As chaves de API para serviços GeoIP externos devem ser armazenadas de forma segura (ex: variáveis de ambiente, `Core.ConfigManager` com `is_sensitive: true`) e não expostas no código.
*   **Precisão dos Dados:** A precisão dos dados de GeoIP varia. O sistema não deve tomar decisões críticas baseadas *apenas* em GeoIP sem corroborar com outros fatores, especialmente para IPs móveis ou atrás de VPNs/proxies.
*   **Privacidade:** Embora endereços IP sejam geralmente considerados dados menos sensíveis que PII direto, o armazenamento de histórico de localização de IP deve seguir políticas de retenção e ser acessado apenas quando necessário.

## 🧑‍💻 13. Contribuição

*   Ao adicionar um novo adaptador de provedor GeoIP, certifique-se de implementar o `GeoLocationAdapterBehaviour` e adicionar a lógica de Circuit Breaker.
*   Mantenha as listas de países de alto risco e outros dados de referência atualizados.
*   Documente a precisão esperada e as limitações de cada provedor GeoIP usado.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar um worker para atualizar automaticamente bases de dados GeoIP locais (ex: MaxMind GeoLite2).
*   [ ] Adicionar suporte para detecção de VPNs e proxies de forma mais robusta, possivelmente integrando com serviços especializados.
*   [ ] Permitir que os usuários revisem e contestem informações de geolocalização associadas às suas contas, se relevante.
*   [ ] Desenvolver heurísticas mais avançadas para `assess_location_risk` considerando a combinação de ISP, ASN, tipo de IP (residencial, comercial, data center).
*   [ ] Cachear resultados de `is_impossible_travel` para pares de localizações/tempos frequentemente verificados, se a performance se tornar um gargalo.

---

*Última atualização: 2025-05-11*

---

Agora que cobrimos a geolocalização, faz sentido documentar o `DeeperHub.Security.DeviceService` (ou `SecurityManager` se ele englobar essa funcionalidade) que lida com o registro e confiança de dispositivos, usando a `DeviceFingerprint`. Ou prefere mudar o foco?"""),
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
                types.Part.from_text(text="""Perfeito! Vamos então detalhar o `DeeperHub.Security.DeviceService`. Este módulo é crucial para o gerenciamento de dispositivos, trabalhando em conjunto com o `DeeperHub.Security.DeviceFingerprint` para identificar e gerenciar o acesso de diferentes dispositivos dos usuários.

---

