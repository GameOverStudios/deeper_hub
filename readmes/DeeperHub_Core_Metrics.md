# Módulo: `DeeperHub.Core.Metrics` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Core.Metrics`

O módulo `DeeperHub.Core.Metrics` é a fachada centralizada para a coleta, registro e exposição de métricas de desempenho e saúde do sistema DeeperHub. Ele fornece uma API unificada para que todos os outros módulos possam registrar métricas de forma consistente, abstraindo a implementação do backend de métricas (ex: Prometheus, StatsD, InfluxDB, ou um coletor ETS interno).

O objetivo principal é fornecer dados quantitativos sobre o comportamento da aplicação, permitindo monitoramento em tempo real, alertas sobre anomalias, análise de tendências de desempenho e otimização de recursos. 😊

*(Nota: A documentação original menciona `DeeperHub.Core.MetricsFacade` e `DeeperHub.Shared.Metrics.MetricsFacade`. Esta documentação consolida em `DeeperHub.Core.Metrics` como a fachada principal, que delegaria para uma implementação mais robusta como `DeeperHub.Shared.Metrics.Services.EtsMetricsService` ou um adaptador para um sistema externo.)*

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Interface de Registro de Métricas Unificada:**
    *   Fornecer funções para diferentes tipos de métricas:
        *   **Contadores (`increment/3`, `decrement/3`):** Para valores que só aumentam ou diminuem (ex: número de requisições, erros).
        *   **Gauges (`gauge/3`):** Para valores que podem subir e descer arbitrariamente (ex: número de usuários ativos, uso de memória).
        *   **Histogramas/Distribuições (`histogram/3`, `record_timing/3`):** Para rastrear a distribuição estatística de um conjunto de valores (ex: latência de requisições, tamanho de payloads).
        *   **Timers (`start_timer/2`, `stop_timer/1` ou função wrapper):** Para medir a duração de operações.
*   **Suporte a Tags/Labels:**
    *   Permitir a adição de tags (pares chave-valor) às métricas para segmentação e filtragem (ex: `endpoint=\"/users\"`, `status_code=\"200\"`).
*   **Nomeação Consistente de Métricas:**
    *   Promover ou impor um esquema de nomeação hierárquico para métricas (ex: `deeper_hub.http.requests.duration_ms`).
*   **Abstração de Backend:**
    *   Delegar o armazenamento e a exposição real das métricas para um adaptador configurável, permitindo a integração com diferentes sistemas de monitoramento.
*   **Coleta Automática de Métricas do Sistema (Opcional):**
    *   Integrar com um `SystemMonitor` para coletar automaticamente métricas básicas do sistema (CPU, memória, etc.).
*   **Agregação e Sumarização (Básica):**
    *   Fornecer funcionalidades para obter resumos ou valores atuais de métricas (principalmente para backends em memória como ETS ou para dashboards de depuração).
*   **Exportação de Métricas (via Adaptador):**
    *   Permitir que os adaptadores exponham as métricas em formatos padronizados (ex: formato Prometheus).
*   **Alertas Baseados em Métricas (Integração):**
    *   Fornecer os dados para um sistema de alertas (`DeeperHub.Shared.Metrics.AlertsSystem`) que monitora métricas e dispara alertas quando limiares são cruzados.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.Core.Metrics` (Fachada Pública):**
    *   **Responsabilidade:** Ponto de entrada para todos os módulos registrarem métricas.
    *   **Interações:** Formata nomes de métricas e tags, e delega para o `DeeperHub.Core.Metrics.Adapter`.
2.  **`DeeperHub.Core.Metrics.Adapter` (Behaviour e Implementação Padrão):**
    *   **Responsabilidade:** Abstrair a lógica de interação com o backend de métricas.
    *   **Comportamento (`MetricsBehaviour`):** Define a interface que os adaptadores devem implementar.
    *   **Implementação Padrão (`DefaultMetricsAdapter` que usa `DeeperHub.Shared.Metrics.Services.EtsMetricsService` ou similar):**
        *   Recebe as chamadas da fachada.
        *   Interage com o sistema de armazenamento de métricas (ex: ETS, ou um cliente para Prometheus/StatsD).
        *   Pode envolver um GenServer para operações assíncronas ou agregação em lote, dependendo do backend.
3.  **`DeeperHub.Shared.Metrics.Services.EtsMetricsService` (Exemplo de Backend em Memória):**
    *   **Responsabilidade:** Armazenar e agregar métricas em tabelas ETS.
    *   **Componentes Internos (como visto na documentação original):**
        *   `EtsMetricsCounter`: Para contadores.
        *   `EtsMetricsHistogram`: Para gauges e histogramas.
4.  **`DeeperHub.Shared.Metrics.ModuleMetrics`:**
    *   **Responsabilidade:** Coletar métricas específicas de diferentes módulos do sistema (ex: número de usuários ativos do módulo `Accounts`). Pode ser chamado por um `CollectorWorker`.
5.  **`DeeperHub.Shared.Metrics.CollectorWorker` (GenServer):**
    *   **Responsabilidade:** Executar tarefas de coleta de métricas periodicamente (ex: chamar `ModuleMetrics.collect_all_module_metrics`).
6.  **`DeeperHub.Shared.Metrics.AlertsSystem` (GenServer):**
    *   **Responsabilidade:** Monitorar métricas contra limiares definidos e gerenciar alertas.
7.  **`DeeperHub.Shared.Metrics.ApiExporter`:**
    *   **Responsabilidade:** Formatar métricas para serem expostas via uma API (ex: endpoint `/metrics` no formato Prometheus).
8.  **`DeeperHub.Shared.Metrics.ExportWorker` (GenServer):**
    *   **Responsabilidade:** Exportar métricas periodicamente para sistemas externos (se configurado).

### 3.2. Estrutura de Diretórios (Proposta)

```
core/metrics/
├── metrics.ex                    # Fachada Pública
├── adapter.ex                    # Behaviour e Default Adapter
│
├── backends/                     # (Opcional) Adaptadores para backends específicos (Prometheus, StatsD)
│   └── prometheus_adapter.ex
│
└── supervisor.ex                 # Supervisor para processos do Core.Metrics (se houver)

shared/metrics/    # Componentes compartilhados do sistema de métricas
├── services/
│   ├── ets_metrics_service.ex    # Implementação ETS
│   ├── ets_metrics_counter.ex
│   └── ets_metrics_histogram.ex
│
├── alerts_system.ex              # Gerenciador de alertas
├── api_exporter.ex               # Exportador para API
├── collector_worker.ex           # Worker para coleta periódica
├── export_worker.ex              # Worker para exportação periódica
├── module_metrics.ex             # Coleta de métricas de módulos
├── system_monitor.ex             # Coleta de métricas do sistema (CPU, mem)
├── supervisor.ex                 # Supervisor para os workers e services de Shared.Metrics
├── telemetry.ex                  # (Opcional) Se o próprio sistema de métricas emitir telemetria sobre sua operação
└── types.ex                      # Definições de tipos comuns de métricas
```

### 3.3. Decisões de Design Importantes

*   **API Simples e Flexível:** A fachada `Core.Metrics` deve ser fácil de usar, com funções claras para cada tipo de métrica.
*   **Performance:** O registro de métricas deve ter um impacto mínimo no desempenho das operações principais. Operações custosas de agregação ou exportação devem ser assíncronas.
*   **Padronização de Nomes e Tags:** É crucial para a usabilidade e integração com ferramentas de monitoramento.
*   **Extensibilidade de Backend:** A arquitetura deve permitir a fácil adição de novos adaptadores para diferentes sistemas de monitoramento.

## 🛠️ 4. Casos de Uso Principais

*   **Monitorar Taxa de Requisições HTTP:**
    *   Um plug na pipeline Phoenix chama `DeeperHub.Core.Metrics.increment([:http, :requests, :total], 1, %{path: \"/api/users\", method: \"GET\"})`.
    *   Outro contador é incrementado para o status code: `DeeperHub.Core.Metrics.increment([:http, :requests, :status_codes], 1, %{code: \"200\"})`.
*   **Medir Latência de Banco de Dados:**
    *   `stop_timer_fn = DeeperHub.Core.Metrics.start_timer([:database, :query, :duration_ms], %{query_name: \"get_user_by_id\"})`
    *   Executa a query.
    *   `stop_timer_fn.()`
*   **Rastrear Número de Usuários Ativos:**
    *   Um worker periódico chama uma função no módulo `Accounts` que retorna o número de usuários ativos.
    *   O worker então chama `DeeperHub.Core.Metrics.gauge([:application, :users, :active_count], count)`.
*   **Alertar sobre Alto Uso de CPU:**
    *   `DeeperHub.Shared.Metrics.SystemMonitor` coleta o uso de CPU.
    *   `DeeperHub.Shared.Metrics.AlertsSystem` verifica essa métrica contra um limiar e, se excedido, dispara um alerta que pode ser enviado via `DeeperHub.Notifications`.

## 🌊 5. Fluxos Importantes

### Fluxo de Registro de Métrica (Ex: Contador)

1.  **Módulo Chamador:** Chama `DeeperHub.Core.Metrics.increment([:my_service, :event_processed], 1, %{type: \"A\"})`.
2.  **`DeeperHub.Core.Metrics` (Fachada):**
    *   Normaliza o nome da métrica (ex: para `\"deeper_hub.my_service.event_processed.count\"`).
    *   Normaliza as tags.
    *   Delega para `DeeperHub.Core.Metrics.Adapter.increment(normalized_name, value, normalized_tags)`.
3.  **`DeeperHub.Core.Metrics.Adapter` (ex: `DefaultMetricsAdapter` usando `EtsMetricsService`):**
    *   Chama `DeeperHub.Shared.Metrics.Services.EtsMetricsService.increment(normalized_name, value, normalized_tags)`.
4.  **`DeeperHub.Shared.Metrics.Services.EtsMetricsService`:**
    *   Usa `EtsMetricsCounter` para encontrar ou criar a entrada ETS para a métrica (combinando nome e tags) e incrementa seu valor.

## 📡 6. API (Funções Públicas da Fachada)

*(A documentação original de `DeeperHub.Core.MetricsFacade` e `DeeperHub.Shared.Metrics.MetricsFacade` já lista a maioria das funções necessárias. A ideia é consolidá-las sob `DeeperHub.Core.Metrics` e garantir clareza.)*

### 6.1. `DeeperHub.Core.Metrics.increment(name :: list(atom()) | String.t(), value :: integer() | nil, tags :: map() | nil) :: :ok`

*   **Descrição:** Incrementa uma métrica de contador.
*   **`@spec`:** `increment(name :: list(atom()) | String.t(), value :: integer() | nil, tags :: map() | nil) :: :ok`
*   **Parâmetros:**
    *   `name`: Nome da métrica (ex: `[:http, :requests]` ou `\"http.requests\"`).
    *   `value`: Valor a incrementar. (Padrão: `1`)
    *   `tags`: Mapa de tags para dimensionalidade. (Padrão: `%{}`)
*   **Exemplo:** `Metrics.increment([:orders, :processed], 1, %{region: \"us-east\"})`

### 6.2. `DeeperHub.Core.Metrics.decrement(name :: list(atom()) | String.t(), value :: integer() | nil, tags :: map() | nil) :: :ok`

*   **Descrição:** Decrementa uma métrica de contador.
*   *(Parâmetros e exemplo similares a `increment/3`)*

### 6.3. `DeeperHub.Core.Metrics.gauge(name :: list(atom()) | String.t(), value :: number(), tags :: map() | nil) :: :ok`

*   **Descrição:** Define o valor de uma métrica do tipo gauge.
*   **Exemplo:** `Metrics.gauge([:system, :memory, :usage_mb], 512.5, %{server_id: \"app-01\"})`

### 6.4. `DeeperHub.Core.Metrics.histogram(name :: list(atom()) | String.t(), value :: number(), tags :: map() | nil) :: :ok`

*   **Descrição:** Registra um valor em uma métrica de histograma (ou distribuição).
*   **Exemplo:** `Metrics.histogram([:api, :request_latency_ms], 123.4, %{endpoint: \"/users\"})`

### 6.5. `DeeperHub.Core.Metrics.record_timing(name :: list(atom()) | String.t(), value_microseconds :: non_neg_integer(), tags :: map() | nil) :: :ok`

*   **Descrição:** Atalho para registrar uma duração em um histograma, tipicamente em microssegundos ou milissegundos.
*   **Exemplo:** `Metrics.record_timing([:db, :query, :duration_us], 56789, %{query_name: \"get_user\"})`

### 6.6. `DeeperHub.Core.Metrics.start_timer(name :: list(atom()) | String.t(), tags :: map() | nil) :: function()`

*   **Descrição:** Inicia um timer e retorna uma função. Chamar a função retornada para o timer e registra a duração. A duração é geralmente registrada em microssegundos.
*   **Exemplo:**
    ```elixir
    stop_fn = Metrics.start_timer([:service_call, :duration_us], %{service: \"payment\"})
    # ... fazer a chamada ao serviço ...
    stop_fn.()
    ```

### 6.7. `DeeperHub.Core.Metrics.get_metric(name :: String.t(), tags :: map() | nil) :: {:ok, value :: term()} | {:error, :not_found}`

*   **Descrição:** Obtém o valor atual de uma métrica específica (principalmente para backends em memória).
*   *(`name` aqui seria a string normalizada completa, ex: `\"deeper_hub.http.requests.total.count\"`)*

### 6.8. `DeeperHub.Core.Metrics.get_metrics_summary(prefix :: String.t() | nil) :: {:ok, map()}`

*   **Descrição:** Obtém um resumo das métricas, opcionalmente filtrado por um prefixo.

## ⚙️ 7. Configuração

Configurações gerenciadas pelo `DeeperHub.Core.ConfigManager`:

*   `[:core, :metrics, :enabled]` (Boolean): Habilita/desabilita todo o sistema de métricas. (Padrão: `true`)
*   `[:core, :metrics, :adapter]` (Module): Módulo adaptador de métricas a ser usado (ex: `DeeperHub.Shared.Metrics.Services.EtsMetricsService`, `MyApp.PrometheusAdapter`). (Padrão: `DeeperHub.Shared.Metrics.Services.EtsMetricsService`)
*   `[:core, :metrics, :default_prefix]` (String): Prefixo padrão para todos os nomes de métricas (ex: `\"deeper_hub\"`). (Padrão: `\"deeper_hub\"`)
*   `[:core, :metrics, :ets_metrics_service, :cleanup_interval_ms]` (Integer): Intervalo para limpeza de métricas antigas no `EtsMetricsService`.
*   `[:core, :metrics, :collector_worker, :collection_interval_ms]` (Integer): Intervalo para o `CollectorWorker` coletar métricas de módulos. (Padrão: `60000`)
*   `[:core, :metrics, :export_worker, :export_interval_ms]` (Integer): Intervalo para o `ExportWorker` enviar métricas para backends externos. (Padrão: `30000`)
*   `[:core, :metrics, :export_worker, :exporters]` (List de Maps): Configuração dos exportadores. Ex: `[%{adapter: MyApp.StatsDExporter, host: \"localhost\", port: 8125}]`
*   `[:core, :metrics, :alerts_system, :check_interval_ms]` (Integer): Intervalo para o `AlertsSystem` verificar regras de alerta. (Padrão: `60000`)
*   `[:core, :metrics, :alerts_system, :rules]` (List de Maps): Definição das regras de alerta.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.ConfigManager`: Para obter configurações do sistema de métricas.
*   `DeeperHub.Core.Logger`: Para logging de operações internas do sistema de métricas.
*   `DeeperHub.Core.Supervisor` (indireta): Para supervisionar os processos de métricas (workers, GenServers).
*   `DeeperHub.Shared.Utils`: Para utilitários de nomeação e manipulação de tags.

### 8.2. Bibliotecas Externas

*   Pode depender de bibliotecas de clientes para sistemas de métricas específicos (ex: `Exometer` (embora talvez seja um backend próprio), `Prometheus.Ex`, `Statix`).
*   `Telemetry` e `Telemetry.Metrics` (Elixir): Para uma base de instrumentação, especialmente se os adaptadores se integrarem com `Telemetry.Metrics`.

## 🤝 9. Como Usar / Integração

**Registrando um contador:**
```elixir
alias DeeperHub.Core.Metrics

def handle_new_user(params) do
  # ... lógica ...
  Metrics.increment([:users, :registered], 1, %{source: params.registration_source})
end
```

**Medindo a duração de uma função:**
```elixir
alias DeeperHub.Core.Metrics

def process_payment(payment_id) do
  stop_timer_fn = Metrics.start_timer([:payments, :processing, :duration_us], %{payment_id: payment_id})
  
  result = do_actual_payment_processing(payment_id) # Função real
  
  stop_timer_fn.() # Registra a duração
  result
end
```

**Definindo um gauge:**
```elixir
alias DeeperHub.Core.Metrics

def update_active_connections_gauge(count) do
  Metrics.gauge([:connections, :active_total], count, %{type: \"websocket\"})
end
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar se os diferentes tipos de métricas (`increment`, `gauge`, `histogram`, `timer`) são registrados corretamente pelo adaptador configurado.
*   Verificar se as tags são associadas corretamente.
*   Testar a obtenção de resumos e valores específicos de métricas (especialmente para adaptadores em memória).
*   Testar os workers (`CollectorWorker`, `ExportWorker`, `AlertsSystem`) para garantir que executam suas tarefas periodicamente e corretamente.
*   Localização: `test/deeper_hub/core/metrics/` e `test/deeper_hub/shared/metrics/`.

### 10.2. Métricas (do próprio sistema de Métricas - Meta-Métricas)

*   `deeper_hub.core.metrics.adapter.operations.count` (tags: `type` (`increment`, `gauge`, etc.), `adapter_name`, `status` (`:ok`, `:error`)): Número de operações de registro de métricas.
*   `deeper_hub.core.metrics.adapter.operations.duration_ms` (Histograma, tags: `type`, `adapter_name`): Duração das operações de registro.
*   `deeper_hub.core.metrics.collector_worker.runs.count` (tags: `status` (`:ok`, `:error`)): Número de execuções do coletor.
*   `deeper_hub.core.metrics.export_worker.runs.count` (tags: `exporter_name`, `status` (`:ok`, `:error`)): Número de execuções do exportador.
*   `deeper_hub.core.metrics.alerts_system.alerts_triggered.count` (tags: `rule_id`, `severity`): Número de alertas disparados.

### 10.3. Logs

*   **Nível INFO:** Inicialização do sistema de métricas, configuração de adaptadores, execução de workers.
*   **Nível WARNING:** Falha ao registrar uma métrica em um backend específico (com retentativa, se aplicável), falha na coleta de métricas de um módulo.
*   **Nível ERROR:** Falha crítica na inicialização, falha persistente em um adaptador de backend, erro na configuração de regras de alerta.

### 10.4. Telemetria

O próprio sistema de métricas pode emitir eventos Telemetry sobre suas operações internas, permitindo que outros sistemas de observabilidade (ou até mesmo ele próprio de forma recursiva, com cuidado) capturem esses dados.
*   `[:deeper_hub, :core, :metrics, :record, :start | :stop | :exception]`
    *   Metadados: `%{metric_name: name, type: type, tags: tags}`
*   `[:deeper_hub, :shared, :metrics, :collector_worker, :run, :start | :stop | :exception]`
*   `[:deeper_hub, :shared, :metrics, :export_worker, :run, :start | :stop | :exception]`
    *   Metadados: `%{exporter: exporter_name}`
*   `[:deeper_hub, :shared, :metrics, :alerts_system, :rule_check, :start | :stop | :exception]`
    *   Metadados: `%{rule_id: id}`
*   `[:deeper_hub, :shared, :metrics, :alerts_system, :alert_triggered]`
    *   Metadados: `%{rule_id: id, severity: severity, metric_name: name, value: value}`

## ❌ 11. Tratamento de Erros

*   **Falha no Adaptador de Backend:** Se um adaptador de backend (ex: Prometheus, StatsD) falhar ao registrar uma métrica, o erro deve ser logado, mas não deve impactar a aplicação principal. O sistema de métricas deve ser resiliente a falhas de backend.
*   **Configuração Inválida:** Erros na configuração de métricas ou regras de alerta devem ser logados claramente na inicialização.

## 🛡️ 12. Considerações de Segurança

*   **Exposição de Métricas:** Se as métricas forem expostas via um endpoint HTTP (ex: para Prometheus), este endpoint deve ser protegido adequadamente (ex: autenticação, restrição de IP) para evitar exposição de informações internas do sistema.
*   **Cardinalidade de Tags:** O uso excessivo de tags com alta cardinalidade (ex: `user_id` em todas as métricas) pode sobrecarregar alguns sistemas de backend de métricas. Use tags com sabedoria.
*   **Não Registrar Dados Sensíveis em Nomes/Tags:** Evite colocar informações sensíveis diretamente nos nomes das métricas ou como valores de tags.

## 🧑‍💻 13. Contribuição

*   Siga o padrão de nomenclatura hierárquico para novas métricas (ex: `deeper_hub.modulo.submodulo.acao.unidade`).
*   Use tags para adicionar dimensões e contexto, mas evite alta cardinalidade excessiva.
*   Para operações que podem variar em duração, use `start_timer/2` ou `histogram/3` em vez de apenas contadores.
*   Consulte a equipe de operações/SRE ao definir novas métricas importantes para garantir que elas possam ser efetivamente monitoradas e alertadas.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar mais adaptadores de backend (ex: Datadog, OpenTelemetry Collector).
*   [ ] Adicionar suporte para exemplars em métricas (especialmente para Prometheus).
*   [ ] Desenvolver uma UI simples para visualização de métricas básicas em tempo real (para desenvolvimento/depuração).
*   [ ] Melhorar a agregação de métricas no `EtsMetricsService` para suportar percentis de forma mais eficiente para histogramas.
*   [ ] Adicionar a capacidade de registrar métricas em lote para reduzir o overhead de chamadas individuais.

---

*Última atualização: 2025-05-11*

---

Pronto para o próximo? Talvez `DeeperHub.Auth` ou `DeeperHub.API`?"""),
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
                types.Part.from_text(text="""Ok, vamos mergulhar no `DeeperHub.Auth`, um dos módulos mais complexos e críticos do sistema. Dada a quantidade de submódulos e funcionalidades já descritas na documentação original, este será um README extenso.

---

