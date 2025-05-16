# Módulo: `Deeper_Hub.Core.CircuitBreaker` 🚀

## 📜 1. Visão Geral do Módulo `Deeper_Hub.Core.CircuitBreaker`

O módulo `Deeper_Hub.Core.CircuitBreaker` implementa o padrão de design **Circuit Breaker**. Seu objetivo é aumentar a resiliência e a estabilidade do sistema Deeper_Hub ao interagir com serviços externos ou recursos internos que podem apresentar falhas ou latência.

Quando um serviço protegido por um circuit breaker começa a falhar repetidamente, o circuito \"abre\", fazendo com que as chamadas subsequentes para esse serviço falhem imediatamente (ou retornem um fallback) por um período, sem tentar realmente contatar o serviço problemático. Isso previne que a aplicação fique presa esperando por um serviço que não responde, evita o esgotamento de recursos (como threads ou conexões) e dá tempo para o serviço problemático se recuperar. Após um timeout, o circuito entra no estado \"meio-aberto\", permitindo um número limitado de chamadas de teste. Se bem-sucedidas, o circuito \"fecha\" e o tráfego normal é restaurado. Caso contrário, ele volta para o estado \"aberto\". 😊

*(Nota: A documentação original tem `Deeper_Hub.Shared.CircuitBreaker`, `CircuitBreakerFacade`, `Registry`, `Config`. Esta documentação consolida a funcionalidade principal sob `Deeper_Hub.Core.CircuitBreaker`, que pode atuar como fachada e orquestrador para instâncias de circuit breakers gerenciadas talvez por um `Registry` interno ou pela biblioteca escolhida).*

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Proteção de Chamadas a Serviços:**
    *   Envolver chamadas a serviços (internos ou externos) com a lógica do circuit breaker (`run/4` ou `call/3`).
*   **Gerenciamento de Estados do Circuito:**
    *   Manter o estado de cada circuit breaker individualmente:
        *   **Fechado (`:closed`):** Operação normal, chamadas são permitidas. Falhas são contadas.
        *   **Aberto (`:open`):** Falhas excederam o limiar. Chamadas falham imediatamente (ou usam fallback) por um período de `reset_timeout`.
        *   **Meio-Aberto (`:half_open`):** Após o `reset_timeout`, permite um número limitado de chamadas de teste. Se bem-sucedidas, volta para `:closed`. Se falharem, volta para `:open`.
*   **Contagem de Falhas e Sucessos:**
    *   Rastrear o número de falhas e sucessos consecutivos (ou dentro de uma janela de tempo) para cada serviço protegido.
*   **Limiares Configuráveis:**
    *   `failure_threshold`: Número de falhas para abrir o circuito.
    *   `success_threshold`: Número de sucessos em estado meio-aberto para fechar o circuito.
    *   `reset_timeout_ms`: Tempo que o circuito permanece aberto antes de tentar o estado meio-aberto.
    *   `call_timeout_ms` (opcional): Timeout para a chamada ao serviço protegido em si.
*   **Suporte a Fallback:**
    *   Permitir a execução de uma função de fallback quando o circuito está aberto ou a chamada principal falha.
*   **Registro e Gerenciamento de Instâncias de Circuit Breaker:**
    *   Permitir a criação e configuração dinâmica de múltiplos circuit breakers, cada um nomeado e associado a um serviço específico (`register/2`).
    *   Consultar o estado e configuração de circuit breakers (`state/1`, `list_all/0`).
    *   Resetar manualmente um circuit breaker (`reset/1`).
*   **Observabilidade:**
    *   Emitir eventos e métricas sobre mudanças de estado do circuito, chamadas permitidas/bloqueadas, falhas, sucessos.
    *   Logar transições de estado e erros significativos.
*   **Persistência de Estado (Opcional, Avançado):**
    *   Para ambientes distribuídos ou para manter o estado entre reinícios, o estado dos circuit breakers (especialmente o estado `:open` e `reset_timeout`) poderia ser persistido (ex: Redis). Por padrão, o estado é geralmente em memória por processo/ETS.

## 🏗️ 3. Arquitetura e Design

Existem várias maneiras de implementar Circuit Breakers em Elixir:
1.  **Usando uma biblioteca existente:** Como `Fuse`, `Breaker`, ou `CircuitBreaker.Ex`. Estas geralmente fornecem GenServers para gerenciar o estado de cada breaker.
2.  **Implementação customizada com GenServers:** Um GenServer por serviço protegido para manter seu estado.
3.  **Implementação com ETS:** Para alta performance, o estado pode ser mantido em ETS com atualizações atômicas.

Assumindo o uso de uma abordagem baseada em GenServer (seja de uma biblioteca ou customizada) gerenciada por um Registry:

### 3.1. Componentes Principais

1.  **`Deeper_Hub.Core.CircuitBreaker` (Fachada Pública):**
    *   Ponto de entrada para registrar, executar chamadas e gerenciar circuit breakers.
    *   Delega para o `CircuitBreaker.Registry` ou diretamente para a biblioteca de circuit breaker configurada.
2.  **`Deeper_Hub.Core.CircuitBreaker.Registry` (GenServer):**
    *   **Responsabilidade:** Gerenciar e supervisionar as instâncias de GenServers de circuit breakers individuais.
    *   Mantém um mapa de `service_name` para `pid_do_breaker_genserver`.
    *   Lida com o registro (`register/2`) e consulta (`state/1`) de breakers.
3.  **`Deeper_Hub.Core.CircuitBreaker.Instance` (GenServer - um por serviço protegido):**
    *   **Responsabilidade:** Implementa a lógica de máquina de estados do circuit breaker para um serviço específico.
    *   **Estado Interno:** `:state` (`:closed`, `:open`, `:half_open`), `failure_count`, `success_count`, `last_failure_timestamp`, `config` (limiares, timeouts).
    *   **Interações:** Recebe solicitações de execução (`run/4`), atualiza seu estado com base no sucesso/falha da chamada ao serviço real.
4.  **Configurações (via `Deeper_Hub.Core.ConfigManager`):**
    *   Configurações padrão para novos circuit breakers.
    *   Configurações específicas por `service_name`.
5.  **Módulos que usam o Circuit Breaker:**
    *   Qualquer módulo que faça chamadas a serviços externos ou internos que podem falhar (ex: `GeoLocationService.Adapters`, `Mailer.Adapters`, `OAuth.Integrations.OAuthApiIntegration`).

### 3.2. Estrutura de Diretórios (Proposta)

```
core/circuit_breaker/
├── circuit_breaker.ex              # Fachada Pública
├── registry.ex                     # GenServer para gerenciar instâncias de CB
├── instance.ex                     # GenServer que implementa a lógica de um CB
├── config.ex                       # (Opcional) Módulo para carregar/gerenciar configs de CBs
└── supervisor.ex                   # Supervisor para o Registry e, indiretamente, as Instâncias
```
Se uma biblioteca externa for usada, a estrutura pode ser mais simples, com `circuit_breaker.ex` atuando como um wrapper/fachada para a API da biblioteca.

### 3.3. Decisões de Design Importantes

*   **Nomeação de Circuit Breakers:** Cada serviço ou recurso protegido deve ter um nome único para seu circuit breaker.
*   **Configuração por Instância:** Cada circuit breaker deve poder ter seus próprios limiares e timeouts, com padrões globais.
*   **Transparência para o Chamador:** A função `run/4` (ou `call/3`) deve abstrair a lógica do circuit breaker. O chamador apenas fornece a função a ser executada e, opcionalmente, um fallback.
*   **Notificação de Mudança de Estado:** É útil emitir eventos ou logs quando um circuito abre ou fecha, para monitoramento.

## 🛠️ 4. Casos de Uso Principais

*   **Chamada a uma API de GeoIP Externa:**
    *   `GeoLocationService` precisa buscar dados de um IP.
    *   `CircuitBreaker.run(:geoip_service, fn -> HTTPClient.get(url) end, fn -> {:ok, fallback_data} end, call_timeout_ms: 2000)`.
    *   Se a API GeoIP estiver lenta ou offline, após algumas falhas, o circuito para `:geoip_service` abre. Chamadas subsequentes usam `fallback_data` imediatamente.
*   **Envio de Email via SMTP Externo:**
    *   `Mailer` tenta enviar um email.
    *   `CircuitBreaker.run(:smtp_service, fn -> SMTPClient.send(email) end)`.
    *   Se o servidor SMTP estiver inacessível, o circuito abre, e o `Mailer` pode enfileirar o email para tentativa posterior.
*   **Acesso a um Microserviço Interno:**
    *   `OrderService` precisa chamar `InventoryService`.
    *   `CircuitBreaker.run(:inventory_service, fn -> InventoryClient.check_stock(item_id) end)`.
    *   Se o `InventoryService` estiver sobrecarregado, o circuito protege o `OrderService` de ficar esperando.

## 🌊 5. Fluxos Importantes

### Fluxo de Execução de uma Chamada Protegida (`run/4`)

1.  **Chamador:** `CircuitBreaker.run(:my_api, do_api_call_fun, fallback_fun, opts)`.
2.  **`CircuitBreaker` (Fachada):**
    *   Localiza o PID do `CircuitBreaker.Instance` para `:my_api` através do `Registry`.
    *   Se não existir, pode tentar registrar um novo com configurações padrão/específicas ou retornar erro.
    *   Encaminha a solicitação para o `CircuitBreaker.Instance` PID.
3.  **`CircuitBreaker.Instance` (GenServer para `:my_api`):**
    *   **Verifica Estado:**
        *   **Se `:open`:**
            *   Verifica se `reset_timeout` passou.
                *   Se sim, muda para `:half_open`, reseta `success_count`, e permite a chamada.
                *   Se não, executa `fallback_fun` (se fornecida) ou retorna `{:error, :circuit_open}`. Incrementa métrica `calls_short_circuited`.
        *   **Se `:half_open`:**
            *   Verifica se o número de chamadas de teste permitidas (`half_open_calls`) foi excedido.
                *   Se sim, executa `fallback_fun` ou retorna `{:error, :circuit_open}` (ainda está testando).
                *   Se não, permite a chamada.
        *   **Se `:closed`:** Permite a chamada.
    *   **Executa `do_api_call_fun` (se permitido):**
        *   Pode aplicar um `call_timeout_ms` específico.
        *   **Sucesso (`{:ok, result}`):**
            *   Se estado era `:half_open`, incrementa `success_count`. Se `success_count >= success_threshold`, muda para `:closed`, reseta contadores.
            *   Se estado era `:closed`, reseta `failure_count`.
            *   Incrementa métrica `calls_succeeded`.
            *   Retorna `{:ok, result}`.
        *   **Falha (`{:error, reason}` ou exceção):**
            *   Incrementa métrica `calls_failed`.
            *   Se estado era `:half_open`, muda para `:open`, agenda próximo `reset_timeout`.
            *   Se estado era `:closed`, incrementa `failure_count`. Se `failure_count >= failure_threshold`, muda para `:open`, agenda `reset_timeout`.
            *   Executa `fallback_fun` (se fornecida) ou retorna `{:error, reason_da_chamada_original}`.

## 📡 6. API (Funções Públicas da Fachada `Deeper_Hub.Core.CircuitBreaker`)

*(Baseado na documentação original e consolidando)*

### 6.1. `Deeper_Hub.Core.CircuitBreaker.run(service_name :: atom(), func :: (() -> {:ok, term()} | {:error, term()}), fallback_func :: (() -> {:ok, term()} | {:error, term()}) | nil, opts :: keyword()) :: {:ok, term()} | {:error, :circuit_open | term()}`

*   **Descrição:** Executa `func` protegida pelo circuit breaker nomeado `service_name`. Se o circuito estiver aberto ou `func` falhar e um `fallback_func` for fornecido, o resultado do fallback é retornado.
*   **`opts`:**
    *   `:call_timeout_ms` (integer): Timeout para a execução de `func`.
    *   Outras opções podem ser passadas para a lógica de registro/configuração do breaker se ele não existir.
*   **Retorno:** `{:ok, result_de_func_ou_fallback}` ou `{:error, :circuit_open}` (se sem fallback e aberto) ou `{:error, reason_de_func_ou_fallback}`.

### 6.2. `Deeper_Hub.Core.CircuitBreaker.register(service_name :: atom(), config :: map()) :: :ok | {:error, :already_registered | term()}`

*   **Descrição:** Registra e configura um novo circuit breaker.
*   **`config`:** Mapa com limiares e timeouts (ex: `%{failure_threshold: 5, reset_timeout_ms: 30000, success_threshold: 2, call_timeout_ms: 5000, half_open_calls: 3}`).

### 6.3. `Deeper_Hub.Core.CircuitBreaker.state(service_name :: atom()) :: {:ok, :closed | :open | :half_open} | {:error, :not_found}`

*   **Descrição:** Retorna o estado atual do circuit breaker especificado.

### 6.4. `Deeper_Hub.Core.CircuitBreaker.reset(service_name :: atom()) :: :ok | {:error, :not_found}`

*   **Descrição:** Força o circuit breaker especificado para o estado `:closed`.

### 6.5. `Deeper_Hub.Core.CircuitBreaker.list_all() :: {:ok, list(%{name: atom(), state: atom(), config: map(), stats: map()})}`

*   **Descrição:** Lista todos os circuit breakers registrados, seus estados, configurações e estatísticas (contagem de falhas/sucessos recentes).

### 6.6. `Deeper_Hub.Core.CircuitBreaker.update_config(service_name :: atom(), new_config :: map()) :: :ok | {:error, :not_found | term()}`

*   **Descrição:** Atualiza a configuração de um circuit breaker existente em tempo de execução.

## ⚙️ 7. Configuração

Via `Deeper_Hub.Core.ConfigManager`:

*   **`[:core, :circuit_breaker, :enabled]`** (Boolean): Habilita/desabilita o sistema de Circuit Breaker globalmente. (Padrão: `true`)
*   **`[:core, :circuit_breaker, :default_config]`** (Map): Configurações padrão para novos circuit breakers.
    *   Ex: `%{failure_threshold: 5, reset_timeout_ms: 30000, success_threshold: 2, call_timeout_ms: 5000, half_open_calls: 3}`
*   **`[:core, :circuit_breaker, :services, <service_name>]`** (Map): Configurações específicas para um `service_name`. Estas sobrescrevem os padrões.
    *   Ex: `%{geoip_api: %{failure_threshold: 3, reset_timeout_ms: 60000}}`
*   **`[:core, :circuit_breaker, :storage_adapter]`** (Module, opcional): Se o estado dos breakers precisar ser persistido (ex: `MyApp.CircuitBreaker.RedisStorage`). (Padrão: estado em memória via GenServer/ETS).

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `Deeper_Hub.Core.ConfigManager`: Para configurações.
*   `Deeper_Hub.Core.Logger`: Para logar transições de estado e erros.
*   `Deeper_Hub.Core.Metrics`: Para métricas de circuit breaker.
*   `Deeper_Hub.Core.Supervisor` (indireta): Para supervisionar o `Registry` e as `Instance`s.

### 8.2. Bibliotecas Externas

*   Opcionalmente, uma biblioteca de Circuit Breaker como `Fuse` ou `Breaker`. Se não, a lógica é implementada internamente com GenServers/ETS.

## 🤝 9. Como Usar / Integração

Módulos que fazem chamadas a serviços externos ou internos que podem ser instáveis devem envolver essas chamadas com `CircuitBreaker.run/4`.

**Exemplo em um adaptador de serviço externo:**
```elixir
defmodule MyApp.ExternalGeoServiceAdapter do
  alias Deeper_Hub.Core.CircuitBreaker
  alias Deeper_Hub.Core.HTTPClient # Assumindo um HTTPClient

  @service_name :external_geo_service

  def init_breaker do
    # Config pode vir do ConfigManager
    config = %{failure_threshold: 3, reset_timeout_ms: 60000, call_timeout_ms: 2000}
    CircuitBreaker.register(@service_name, config)
  end

  def get_location_for_ip(ip_address) do
    api_call_fun = fn ->
      case HTTPClient.get(\"https://geo.example.com/ip/#{ip_address}\", timeout: 1800) do
        {:ok, %{status_code: 200, body: body_map}} -> {:ok, body_map}
        {:ok, %{status_code: _other_status}} -> {:error, :api_error}
        {:error, reason} -> {:error, reason}
      end
    end

    fallback_fun = fn ->
      # Tentar uma base de dados local ou retornar dados padrão
      {:ok, %{country: \"Unknown\", city: \"Unknown\"}} 
    end

    CircuitBreaker.run(@service_name, api_call_fun, fallback_fun)
  end
end
```
A chamada `init_breaker` seria feita uma vez na inicialização do módulo ou da aplicação.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar a transição de estados do circuit breaker (`closed` -> `open` -> `half_open` -> `closed` e `half_open` -> `open`).
*   Testar o comportamento com e sem função de fallback.
*   Testar o `call_timeout_ms`.
*   Testar o `reset_timeout_ms`.
*   Testar o registro e atualização de configuração de breakers.
*   Localização: `test/deeper_hub/core/circuit_breaker/`.

### 10.2. Métricas

*   `deeper_hub.core.circuit_breaker.calls.total` (tags: `service_name`, `status` (`success`, `failure`, `timeout`, `short_circuited`))
*   `deeper_hub.core.circuit_breaker.state_transitions.count` (tags: `service_name`, `from_state`, `to_state`)
*   `deeper_hub.core.circuit_breaker.state.current` (Gauge, tags: `service_name`, valor: 0=:closed, 1=:open, 2=:half_open)
*   `deeper_hub.core.circuit_breaker.fallback.used.count` (tags: `service_name`)
*   `deeper_hub.core.circuit_breaker.call.duration_ms` (Histograma, tags: `service_name`, `was_successful`)

### 10.3. Logs

*   **Nível INFO:** Transição de estado de um circuit breaker (ex: \"Circuit breaker para :my_service ABERTO\"). Sucesso em estado `half_open` levando a fechamento.
*   **Nível WARNING:** Chamada falhou e contribuiu para abrir o circuito. Chamada short-circuitada porque o circuito está aberto.
*   **Nível ERROR:** Erro interno no próprio GenServer do Circuit Breaker.

### 10.4. Telemetria

*   `[:deeper_hub, :core, :circuit_breaker, :call, :start | :stop | :exception]`
    *   Metadados: `%{service_name: name, initial_state: state}`
    *   No `:stop`: `%{result: :success | :failure | :timeout | :short_circuited, final_state: state, fallback_used: boolean}`
*   `[:deeper_hub, :core, :circuit_breaker, :state_changed]`
    *   Metadados: `%{service_name: name, old_state: state, new_state: state, reason: :failure_threshold_reached | :reset_timeout | :success_threshold_reached}`

## ❌ 11. Tratamento de Erros

*   A função `run/4` retorna `{:error, :circuit_open}` se o circuito estiver aberto e nenhum fallback for fornecido, ou o erro da função original/fallback.
*   Erros na configuração ou registro de um breaker devem ser logados e impedir o uso desse breaker específico, mas não devem derrubar o `Registry`.

## 🛡️ 12. Considerações de Segurança

*   A exposição do estado dos circuit breakers (`list_all/0`, `state/1`) via uma API administrativa deve ser protegida, pois pode revelar informações sobre a saúde de dependências internas ou externas.

## 🧑‍💻 13. Contribuição

*   Ao adicionar uma nova integração com serviço externo, considere protegê-la com um circuit breaker.
*   Ajuste os limiares e timeouts com base no comportamento esperado e na criticidade do serviço protegido.
*   Forneça funções de fallback sensatas sempre que possível.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Adicionar \"bulkheads\" (isolamento de recursos por serviço) em conjunto com circuit breakers para limitar o impacto de um serviço lento no pool de workers da aplicação.
*   [ ] Implementar estratégias de retry com backoff *antes* de declarar uma falha para o circuit breaker, para lidar com falhas transitórias de rede.
*   [ ] Permitir que as configurações do circuit breaker (limiares, timeouts) sejam atualizadas dinamicamente em tempo de execução sem reiniciar o breaker (além do `update_config` já proposto, garantir que seja aplicado ao processo em execução).
*   [ ] Interface de UI para visualizar o estado de todos os circuit breakers e resetá-los manualmente.
*   [ ] Considerar a persistência do estado `:open` e do `reset_timeout` em um armazenamento como Redis para que o estado sobreviva a reinícios da aplicação, evitando que um serviço problemático seja imediatamente sobrecarregado após um deploy.

---

*Última atualização: 2025-05-12*

---

Circuit breakers são uma ferramenta poderosa para construir sistemas resilientes!

Onde vamos agora? Talvez `Deeper_Hub.Core.EncryptionService` para cobrir criptografia e gerenciamento de chaves, ou algum dos utilitários de `Shared.Utils` como `MapUtils` ou `ListUtils`?"""),
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
                types.Part.from_text(text="""Excelente! Vamos então detalhar o `Deeper_Hub.Core.EncryptionService`. Este módulo é fundamental para proteger dados sensíveis em repouso e, potencialmente, em trânsito dentro de certos contextos.

---

