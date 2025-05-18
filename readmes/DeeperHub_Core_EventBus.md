# Módulo: `DeeperHub.Core.EventBus` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Core.EventBus`

O módulo `DeeperHub.Core.EventBus` é o coração do sistema de publicação e assinatura de eventos (Pub/Sub) dentro do DeeperHub. Ele permite que diferentes módulos da aplicação se comuniquem de forma assíncrona e desacoplada, emitindo eventos quando ocorrem ações significativas e permitindo que outros módulos interessados reajam a esses eventos sem conhecimento direto uns dos outros. Isso promove uma arquitetura mais modular, extensível e resiliente. 😊

Exemplo: Quando um novo usuário é criado pelo módulo `DeeperHub.Accounts`, ele publica um evento `UserCreatedEvent`. O módulo `DeeperHub.Notifications` pode estar inscrito nesse evento para enviar um email de boas-vindas, e o módulo `DeeperHub.Audit` pode registrar o evento para fins de auditoria.

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Registro de Assinantes (Subscribers):**
    *   Permitir que módulos ou processos registrem interesse em tópicos de eventos específicos.
    *   Suporte a tópicos com wildcards para assinaturas mais flexíveis (ex: `user.*`, `payment.success`).
    *   Gerenciar o ciclo de vida das assinaturas, incluindo remoção automática de assinantes que terminam.
*   **Publicação de Eventos (Publishers):**
    *   Receber eventos de qualquer módulo do sistema.
    *   Validar (opcionalmente) o formato do evento e do payload.
*   **Distribuição de Eventos:**
    *   Identificar todos os assinantes para um determinado tópico de evento.
    *   Entregar cópias do evento para cada assinante de forma assíncrona e concorrente.
    *   Garantir que a falha na entrega para um assinante não afete a entrega para outros.
*   **Retentativa de Entrega (Retry Logic):**
    *   Implementar uma política de retentativa configurável para eventos que falham na entrega (ex: assinante temporariamente indisponível).
    *   Suporte a backoff exponencial entre as tentativas.
*   **Histórico de Eventos (Opcional e Configurável):**
    *   Manter um histórico limitado dos últimos N eventos publicados por tópico.
    *   Permitir que novos assinantes recebam eventos passados recentes ao se inscreverem (`receive_past` opção).
*   **Monitoramento e Observabilidade:**
    *   Expor métricas sobre o número de eventos publicados, entregues, falhos, em fila, etc.
    *   Registrar logs detalhados sobre a atividade do barramento de eventos.
*   **Persistência de Eventos (Avançado/Opcional):**
    *   Capacidade de integrar com um mecanismo de armazenamento persistente para garantir a entrega de eventos críticos mesmo após reinícios do sistema (ex: Kafka, RabbitMQ, ou uma tabela de banco de dados).

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.Core.EventBus.Server` (GenServer):**
    *   **Responsabilidade:** É o processo central que gerencia o estado do EventBus.
    *   **Estado Interno:**
        *   Tabela de Assinaturas: Mapeamento de tópicos de eventos para uma lista de PIDs de assinantes.
        *   Fila de Eventos (Opcional): Uma fila interna (ou delegada a um sistema de filas externo) para eventos aguardando dispatch.
        *   Histórico de Eventos: Buffer circular por tópico para eventos recentes (se habilitado).
        *   Configurações: Limites, políticas de retry, etc.
    *   **Interações:** Recebe chamadas de `publish`, `subscribe`, `unsubscribe`. Delega o dispatch real para `DispatcherWorkers` ou `Task.Supervisor`.
2.  **`DeeperHub.Core.EventBus.DispatcherWorker` (Pool de Workers ou `Task.Supervisor`):**
    *   **Responsabilidade:** Enviar eventos para os PIDs dos assinantes de forma isolada.
    *   **Interações:** Recebe um evento e uma lista de PIDs de assinantes do `EventBus.Server`. Tenta enviar a mensagem para cada PID. Reporta sucesso/falha de volta para o `EventBus.Server` (para lógica de retry ou DLQ).
3.  **`DeeperHub.Core.EventBus.RetryManager` (GenServer ou Worker):**
    *   **Responsabilidade:** Gerenciar eventos que falharam na entrega e precisam ser reenviados.
    *   **Estado Interno:** Fila de eventos para retry com timestamps da próxima tentativa.
    *   **Interações:** Recebe eventos falhados do `DispatcherWorker`. Agenda reenvios e os envia de volta para o `DispatcherWorker`.
4.  **`DeeperHub.Core.EventBus.StorageAdapter` (Behaviour e Implementações):**
    *   **Responsabilidade:** Abstrair a persistência de eventos para histórico ou garantia de entrega.
    *   **Implementações:** `EtsStorage` (para histórico em memória), `DbStorage` (para persistência em banco de dados), `NoOpStorage`.

### 3.2. Estrutura de Diretórios (Proposta)

```
core/event_bus/
├── event_bus.ex                  # Fachada Pública: publish, subscribe, etc.
├── server.ex                     # GenServer principal
├── dispatcher_worker.ex          # Worker para enviar eventos
├── retry_manager.ex              # GenServer para gerenciar retries
├── event.ex                      # Struct para representar um evento (topic, payload, metadata)
│
├── storage/
│   ├── storage_adapter.ex        # Behaviour para adaptadores de armazenamento
│   ├── ets_storage.ex            # Implementação com ETS
│   └── db_storage.ex             # Implementação com Banco de Dados
│
└── supervisor.ex                 # Supervisor para os processos do EventBus
```

### 3.3. Decisões de Design Importantes

*   **Desacoplamento Total:** Nenhum publicador precisa conhecer os assinantes, e vice-versa.
*   **Entrega Assíncrona:** A publicação de eventos é uma operação rápida que não bloqueia o publicador. A entrega é feita em background.
*   **Resiliência de Assinantes:** A falha de um assinante em processar um evento não deve impedir a entrega para outros assinantes nem bloquear o EventBus.
*   **Configurabilidade:** Políticas de retry, limites de histórico e outros comportamentos são configuráveis via `Core.ConfigManager`.
*   **Observabilidade:** Métricas e logs detalhados são cruciais para entender o fluxo de eventos e diagnosticar problemas.

## 🛠️ 4. Casos de Uso Principais

*   **Notificação de Criação de Usuário:**
    *   `DeeperHub.Accounts` publica `DeeperHub.Core.EventBus.publish(\"user.created\", %{user_id: 123, email: \"a@b.com\"})`.
    *   `DeeperHub.Notifications` (inscrito em `\"user.created\"`) recebe o evento e envia um email de boas-vindas.
    *   `DeeperHub.Audit` (inscrito em `\"user.created\"`) recebe o evento e registra uma entrada de auditoria.
*   **Atualização de Cache em Tempo Real:**
    *   Um módulo de gerenciamento de `Servidores` publica `DeeperHub.Core.EventBus.publish(\"server.updated\", %{server_id: 456, changes: %{name: \"Novo Nome\"}})`.
    *   O `DeeperHub.Core.Cache` ou um serviço de cache específico (inscrito em `\"server.updated\"`) recebe o evento e invalida/atualiza a entrada de cache para o servidor 456.
*   **Processamento Assíncrono de Pedidos:**
    *   Módulo `DeeperHub.Orders` publica `DeeperHub.Core.EventBus.publish(\"order.placed\", %{order_id: 789, items: [...]})`.
    *   `DeeperHub.InventoryService` (inscrito) reserva itens.
    *   `DeeperHub.PaymentService` (inscrito) processa o pagamento.
    *   `DeeperHub.Notifications` (inscrito) envia confirmação ao usuário.

## 🌊 5. Fluxos Importantes

### 5.1. Fluxo de Publicação e Entrega de Evento

1.  **Publicador:** Um módulo (ex: `DeeperHub.Accounts`) chama `DeeperHub.Core.EventBus.publish(\"user.created\", payload, opts)`.
2.  **`EventBus.Server`:**
    *   Recebe a chamada `publish`.
    *   Cria uma `Event` struct com `topic`, `payload`, `metadata` (timestamp, event_id único).
    *   Se o histórico estiver habilitado, armazena o evento no buffer do tópico correspondente.
    *   Consulta a tabela de assinaturas para encontrar todos os PIDs inscritos no tópico `\"user.created\"` (ou padrões correspondentes como `\"user.*\"`).
3.  **Dispatch:**
    *   Para cada PID assinante, o `EventBus.Server` envia uma tarefa para um `DispatcherWorker` (ou usa `Task.async`).
    *   A tarefa contém o `Event` struct e o PID do assinante.
4.  **`DispatcherWorker`:**
    *   Tenta enviar o evento para o PID do assinante (ex: `send(subscriber_pid, {:event, topic, payload, metadata})`).
    *   **Sucesso:** Notifica o `EventBus.Server` (para métricas de entrega).
    *   **Falha (assinante morreu/ocupado):**
        *   Se a lógica de retry estiver habilitada para o evento/tópico, envia o evento e os detalhes da falha para o `RetryManager`.
        *   Senão, registra a falha (para métricas).
5.  **Assinante:**
    *   Recebe a mensagem `{:event, topic, payload, metadata}` em seu `handle_info/2`.
    *   Processa o evento.

### 5.2. Fluxo de Assinatura

1.  **Assinante:** Um processo (ex: um GenServer de `DeeperHub.Notifications`) chama `DeeperHub.Core.EventBus.subscribe(\"user.created\", self(), opts)` durante sua inicialização (`init/1`).
2.  **`EventBus.Server`:**
    *   Recebe a chamada `subscribe`.
    *   Adiciona o `self()` (PID do assinante) à lista de assinantes do tópico `\"user.created\"`.
    *   Monitora o PID do assinante para remoção automática em caso de término.
    *   Se `opts[:receive_past]` for `true`, recupera os eventos recentes do histórico para o tópico e os envia para o novo assinante.

### 5.3. Fluxo de Retentativa de Entrega

1.  **`DispatcherWorker`:** Detecta falha na entrega para um assinante.
2.  **`RetryManager`:**
    *   Recebe o evento e os detalhes da falha (ex: número de tentativas, último erro).
    *   Incrementa o contador de tentativas.
    *   Se o número máximo de tentativas não foi excedido:
        *   Calcula o próximo intervalo de retry (ex: backoff exponencial).
        *   Agenda o reenvio do evento para o `DispatcherWorker` após o intervalo.
    *   Se o número máximo de tentativas foi excedido:
        *   Move o evento para uma Dead-Letter Queue (DLQ) (se configurada).
        *   Registra a falha permanente.
3.  **`DispatcherWorker` (Reenvio):** Recebe o evento do `RetryManager` e tenta reenviá-lo.

## 📡 6. API (Funções Públicas)

### 6.1. `DeeperHub.Core.EventBus.publish(topic :: String.t() | atom() | list(atom()), payload :: term(), opts :: keyword()) :: :ok | {:error, term()}`

*   **Descrição:** Publica um evento no barramento para todos os assinantes interessados.
*   **`@spec`:** `publish(topic :: String.t() | atom() | list(atom()), payload :: term(), opts :: keyword()) :: :ok | {:error, term()}`
*   **Parâmetros:**
    *   `topic` (String | atom | list(atom)): O tópico do evento (ex: `\"user.created\"`, `:payment_processed`, `[:order, :item, :shipped]`).
    *   `payload` (term): Os dados associados ao evento. Deve ser um termo serializável se a persistência ou distribuição entre nós for usada.
    *   `opts` (keyword list): Opções adicionais:
        *   `:metadata` (map): Metadados personalizados a serem incluídos no evento. (Padrão: `%{}`)
        *   `:event_id` (String.t): Um ID de evento customizado. Se não fornecido, um UUID será gerado.
        *   `:timestamp` (DateTime.t): Timestamp customizado para o evento. Se não fornecido, `DateTime.utc_now()` será usado.
        *   `:retry_enabled` (boolean): Sobrescreve a configuração global de retry para este evento. (Padrão: usa config global)
        *   `:max_attempts` (pos_integer): Sobrescreve o número máximo de tentativas para este evento. (Padrão: usa config global)
        *   `:persistent` (boolean): Se este evento deve ser persistido (requer adaptador de storage configurado). (Padrão: `false`)
*   **Retorno:**
    *   `:ok`: Se o evento foi aceito para publicação.
    *   `{:error, reason}`: Se houve um erro ao tentar publicar (ex: validação do tópico/payload falhou).
*   **Exemplo de Uso (Elixir):**
    ```elixir
    payload = %{user_id: \"user123\", registration_method: \"email\"}
    metadata = %{source_module: MyModule, trace_id: \"trace-xyz\"}
    DeeperHub.Core.EventBus.publish(\"user.registered\", payload, metadata: metadata)
    ```

### 6.2. `DeeperHub.Core.EventBus.subscribe(topic_pattern :: String.t() | atom() | list(atom()), subscriber :: pid() | module() | {module(), term()} | {atom(), node()}, opts :: keyword()) :: :ok | {:error, term()}`

*   **Descrição:** Registra um `subscriber` para receber eventos que correspondam ao `topic_pattern`.
*   **`@spec`:** `subscribe(topic_pattern :: String.t() | atom() | list(atom()), subscriber :: pid() | module() | {module(), term()} | {atom(), node()}, opts :: keyword()) :: :ok | {:error, term()}`
*   **Parâmetros:**
    *   `topic_pattern` (String | atom | list(atom)): O padrão do tópico para assinar. Pode incluir wildcards (`*` para um segmento, `**` para múltiplos segmentos, ou conforme a implementação de matching).
    *   `subscriber`: O processo ou entidade que receberá os eventos.
        *   `pid()`: O PID do processo assinante.
        *   `module()`: Um módulo que implementa um callback `handle_event(topic, payload, metadata)`.
        *   `{module(), term()}`: Um módulo e um estado inicial para um worker dinâmico a ser iniciado.
        *   `{atom(), node()}`: Nome registrado de um processo (local ou remoto).
    *   `opts` (keyword list): Opções adicionais:
        *   `:receive_past` (boolean): Se `true`, envia os últimos N eventos do histórico para este tópico ao assinante. (Padrão: `false`)
        *   `:max_past_events` (pos_integer): Número máximo de eventos passados a serem enviados se `:receive_past` for `true`. (Padrão: config global)
        *   `:queue_opts` (keyword): Opções para a fila individual do assinante (se aplicável pela implementação).
*   **Retorno:**
    *   `:ok`: Assinatura bem-sucedida.
    *   `{:error, reason}`: Falha na assinatura.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    # Em um GenServer
    def init(_args) do
      DeeperHub.Core.EventBus.subscribe(\"user.*\", self())
      {:ok, %{}}
    end

    def handle_info({:event, topic, payload, metadata}, state) do
      Logger.info(\"Evento recebido: #{inspect(topic)} com payload: #{inspect(payload)}\", metadata)
      {:noreply, state}
    end
    ```

### 6.3. `DeeperHub.Core.EventBus.unsubscribe(topic_pattern :: String.t() | atom() | list(atom()), subscriber :: pid() | module() | {atom(), node()}) :: :ok`

*   **Descrição:** Remove uma assinatura específica.
*   **`@spec`:** `unsubscribe(topic_pattern :: String.t() | atom() | list(atom()), subscriber :: pid() | module() | {atom(), node()}) :: :ok`
*   **Parâmetros:**
    *   `topic_pattern`: O padrão do tópico da assinatura a ser removida.
    *   `subscriber`: O processo ou entidade que estava inscrito.
*   **Retorno:** `:ok`.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    DeeperHub.Core.EventBus.unsubscribe(\"user.*\", self())
    ```

### 6.4. `DeeperHub.Core.EventBus.unsubscribe_all(subscriber :: pid() | module() | {atom(), node()}) :: :ok`

*   **Descrição:** Remove todas as assinaturas de um `subscriber`.
*   **`@spec`:** `unsubscribe_all(subscriber :: pid() | module() | {atom(), node()}) :: :ok`
*   **Parâmetros:**
    *   `subscriber`: O processo ou entidade cujas assinaturas serão removidas.
*   **Retorno:** `:ok`.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    DeeperHub.Core.EventBus.unsubscribe_all(self())
    ```

### 6.5. `DeeperHub.Core.EventBus.get_event_history(topic :: String.t() | atom() | list(atom()), opts :: keyword()) :: {:ok, list(Event.t())} | {:error, :not_found | term()}` (Nova Funcionalidade)

*   **Descrição:** Recupera o histórico recente de eventos para um tópico específico. Requer que o histórico de eventos esteja habilitado e configurado.
*   **`@spec`:** `get_event_history(topic :: String.t() | atom() | list(atom()), opts :: keyword()) :: {:ok, list(map())} | {:error, :not_found | term()}`
*   **Parâmetros:**
    *   `topic`: O tópico exato do evento.
    *   `opts` (keyword list): Opções adicionais:
        *   `:limit` (pos_integer): Número máximo de eventos a retornar. (Padrão: config global de histórico)
        *   `:since_event_id` (String.t): Retorna eventos publicados após este ID de evento.
*   **Retorno:**
    *   `{:ok, events_list}`: Lista dos eventos históricos.
    *   `{:error, :not_found}`: Se o tópico não tiver histórico ou não existir.
    *   `{:error, :history_disabled}`: Se o histórico de eventos não estiver habilitado.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    case DeeperHub.Core.EventBus.get_event_history(\"user.created\", limit: 5) do
      {:ok, events} -> IO.inspect(events)
      {:error, reason} -> Logger.warning(\"Não foi possível obter histórico: #{reason}\")
    end
    ```

## ⚙️ 7. Configuração

O módulo `EventBus` é configurado através do `DeeperHub.Core.ConfigManager`.

*   **ConfigManager:**
    *   `[:core, :event_bus, :enabled]` (Boolean): Habilita/desabilita completamente o EventBus. (Padrão: `true`)
    *   `[:core, :event_bus, :history_enabled]` (Boolean): Habilita o armazenamento de histórico de eventos. (Padrão: `false`)
    *   `[:core, :event_bus, :history_limit_per_topic]` (Integer): Número máximo de eventos a serem mantidos no histórico por tópico. (Padrão: `100`)
    *   `[:core, :event_bus, :retry_enabled]` (Boolean): Habilita a lógica de retentativa para entrega de eventos. (Padrão: `true`)
    *   `[:core, :event_bus, :retry_max_attempts]` (Integer): Número máximo de tentativas de entrega. (Padrão: `5`)
    *   `[:core, :event_bus, :retry_base_interval_ms]` (Integer): Intervalo base (em ms) para a primeira retentativa. (Padrão: `1000`)
    *   `[:core, :event_bus, :retry_max_interval_ms]` (Integer): Intervalo máximo (em ms) entre retentativas (para backoff exponencial). (Padrão: `60000`)
    *   `[:core, :event_bus, :retry_backoff_strategy]` (Atom): Estratégia de backoff (:exponential, :fixed). (Padrão: `:exponential`)
    *   `[:core, :event_bus, :dispatcher_pool_size]` (Integer): Número de workers no pool de dispatchers. (Padrão: `System.schedulers_online() * 2`)
    *   `[:core, :event_bus, :storage_adapter]` (Module): Módulo adaptador para persistência de eventos (ex: `DeeperHub.Core.EventBus.Storage.DbStorage`). (Padrão: `DeeperHub.Core.EventBus.Storage.EtsStorage` para histórico em memória, ou `DeeperHub.Core.EventBus.Storage.NoOpStorage` se desabilitado)
    *   `[:core, :event_bus, :dlq_enabled]` (Boolean): Habilita Dead-Letter Queue para eventos que falham persistentemente. (Padrão: `false`)
    *   `[:core, :event_bus, :dlq_adapter]` (Module): Módulo adaptador para a DLQ. (Padrão: `nil`)

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.ConfigManager`: Para obter configurações de runtime.
*   `DeeperHub.Core.Logger`: Para registrar atividades e erros.
*   `DeeperHub.Core.Metrics`: Para emitir métricas de desempenho e saúde.
*   `DeeperHub.Core.Supervisor` (indireta): Para ser supervisionado.

### 8.2. Bibliotecas Externas

*   `Jason` (opcional): Se os payloads dos eventos precisarem ser serializados/desserializados para armazenamento persistente ou comunicação entre nós.
*   Pode depender de um cliente de sistema de filas (ex: `AMQP` para RabbitMQ, `Brody` para Kafka) se um `StorageAdapter` correspondente for usado para persistência avançada.

## 🤝 9. Como Usar / Integração

**Publicando um Evento:**
Qualquer módulo pode publicar um evento chamando a função `publish/3`.
```elixir
# Em um módulo qualquer
alias DeeperHub.Core.EventBus

def process_order(order) do
  # ... lógica de processamento ...
  EventBus.publish(\"order.processed\", %{order_id: order.id, status: \"completed\"})
  {:ok, order}
end
```

**Assinando Eventos (em um GenServer):**
```elixir
defmodule MyApp.OrderNotifier do
  use GenServer
  alias DeeperHub.Core.EventBus
  alias DeeperHub.Core.Logger # Exemplo

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    Logger.info(\"OrderNotifier iniciando e assinando eventos...\")
    EventBus.subscribe(\"order.processed\", self())
    EventBus.subscribe(\"order.shipped\", self())
    # Assinar outros eventos relevantes
    {:ok, %{}}
  end

  @impl true
  def handle_info({:event, topic, payload, _metadata}, state) do
    Logger.info(\"Evento recebido no OrderNotifier: #{inspect(topic)}\", payload: payload)
    case topic do
      \"order.processed\" ->
        # Enviar notificação de pedido processado
        Logger.info(\"Enviando notificação de pedido processado para order_id: #{payload.order_id}\")
      \"order.shipped\" ->
        # Enviar notificação de pedido enviado
        Logger.info(\"Enviando notificação de pedido enviado para order_id: #{payload.order_id}\")
      _ ->
        :ok
    end
    {:noreply, state}
  end

  # Outros callbacks do GenServer...
end
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testes unitários para o `EventBus.Server` devem cobrir a lógica de gerenciamento de assinaturas, enfileiramento e histórico.
*   Testes para os `DispatcherWorker`s devem focar na entrega de mensagens e tratamento de falhas de assinantes.
*   Testes para o `RetryManager` devem verificar a lógica de agendamento e limites de retry.
*   Testes de integração devem simular a publicação e o recebimento de eventos por múltiplos assinantes, incluindo cenários de falha e retry.
*   Localização dos testes: `test/deeper_hub/core/event_bus/`

### 10.2. Métricas

*   **Contadores:**
    *   `deeper_hub.core.event_bus.event.published.count` (tags: `topic`): Número de eventos publicados.
    *   `deeper_hub.core.event_bus.event.delivered.count` (tags: `topic`, `subscriber_id`): Número de eventos entregues com sucesso a um assinante.
    *   `deeper_hub.core.event_bus.event.delivery_failed.count` (tags: `topic`, `subscriber_id`, `reason`): Número de falhas na entrega.
    *   `deeper_hub.core.event_bus.event.retried.count` (tags: `topic`, `subscriber_id`): Número de vezes que a entrega de um evento foi retentada.
    *   `deeper_hub.core.event_bus.event.dlq.count` (tags: `topic`): Número de eventos enviados para a Dead-Letter Queue.
    *   `deeper_hub.core.event_bus.subscriber.added.count` (tags: `topic`): Número de novas assinaturas.
    *   `deeper_hub.core.event_bus.subscriber.removed.count` (tags: `topic`): Número de assinaturas removidas.
*   **Gauges:**
    *   `deeper_hub.core.event_bus.queue.size.gauge` (tags: `topic` (opcional)): Tamanho da fila de eventos pendentes.
    *   `deeper_hub.core.event_bus.retry_queue.size.gauge`: Tamanho da fila de retentativas.
    *   `deeper_hub.core.event_bus.subscribers.active.gauge` (tags: `topic`): Número de assinantes ativos por tópico.
    *   `deeper_hub.core.event_bus.history.size.gauge` (tags: `topic`): Tamanho do buffer de histórico por tópico.
*   **Histogramas/Timers:**
    *   `deeper_hub.core.event_bus.publish.duration_ms` (Histograma): Duração para processar uma chamada de `publish`.
    *   `deeper_hub.core.event_bus.dispatch.duration_ms` (Histograma, tags: `topic`): Duração para despachar um evento para todos os seus assinantes (excluindo o tempo de processamento do assinante).
    *   `deeper_hub.core.event_bus.event_processing_latency_ms` (Histograma, tags: `topic`): Latência entre a publicação e a entrega bem-sucedida de um evento.

### 10.3. Logs

*   **Nível INFO:**
    *   Publicação de novos eventos (tópico, ID do evento, metadados relevantes).
    *   Assinatura/Cancelamento de assinatura (tópico, PID/nome do assinante).
    *   Entrega bem-sucedida de evento para um assinante.
    *   Início e fim de um ciclo de retry para um evento.
*   **Nível WARNING:**
    *   Falha na entrega de um evento para um assinante (antes de retry).
    *   Payload de evento grande que pode impactar performance.
    *   Fila de eventos ou fila de retry atingindo um limiar alto.
*   **Nível ERROR:**
    *   Falha persistente na entrega de um evento após todas as retentativas (movido para DLQ ou descartado).
    *   Erro interno no `EventBus.Server` ou workers.
    *   Falha ao persistir evento (se storage persistente estiver configurado).

### 10.4. Telemetria

O `EventBus` emite eventos Telemetry para permitir instrumentação fina e observabilidade.

*   `[:deeper_hub, :core, :event_bus, :publish, :start | :stop | :exception]`
    *   Medições: `%{duration: native_time}` (no `:stop`)
    *   Metadados: `%{topic: topic, payload_size: size, event_id: event_id, opts: opts}`
*   `[:deeper_hub, :core, :event_bus, :subscribe, :success | :failure]`
    *   Metadados: `%{topic_pattern: pattern, subscriber: subscriber, opts: opts, reason: reason_if_failure}`
*   `[:deeper_hub, :core, :event_bus, :dispatch, :start | :stop | :exception]` (para o lote de dispatch de um evento)
    *   Medições: `%{duration: native_time}`
    *   Metadados: `%{topic: topic, event_id: event_id, subscriber_count: count}`
*   `[:deeper_hub, :core, :event_bus, :delivery, :success | :failure | :retry]` (para entrega a um assinante individual)
    *   Metadados: `%{topic: topic, event_id: event_id, subscriber: subscriber, attempt: attempt_num, error: error_if_failure}`

## ❌ 11. Tratamento de Erros

*   **Falha de Assinante:** Se um processo assinante falhar ao receber ou processar um evento (ex: `send` para um PID morto, ou o assinante crasha), o `DispatcherWorker` detecta isso.
    *   O evento é encaminhado para o `RetryManager` se as retentativas estiverem habilitadas.
    *   A falha não impacta a entrega para outros assinantes do mesmo evento.
*   **Retries Excedidos:** Se um evento falhar em todas as tentativas de reenvio, ele é movido para uma Dead-Letter Queue (DLQ) configurada (se houver) ou descartado. Um log de erro é gerado.
*   **`EventBus.Server` Crash:** Sendo um GenServer supervisionado, será reiniciado pelo supervisor.
    *   Assinaturas em memória (ETS) serão perdidas e precisarão ser refeitas pelos assinantes ao reiniciarem.
    *   Eventos em filas internas em memória serão perdidos. Para evitar isso, um `StorageAdapter` com persistência (ex: DB, sistema de filas externo) seria necessário para a fila de eventos.
*   **Tópico Inválido ou Payload Inválido:** A função `publish/3` pode retornar `{:error, reason}` se o tópico ou payload não passarem em validações básicas.

## 🛡️ 12. Considerações de Segurança

*   **Sensibilidade do Payload:** Os payloads dos eventos podem conter dados sensíveis. Se o histórico de eventos ou a persistência de eventos estiverem habilitados, considerar:
    *   Criptografar payloads sensíveis antes de publicá-los.
    *   Filtrar dados sensíveis dos payloads antes do armazenamento no histórico/DLQ.
*   **Controle de Acesso à Publicação/Assinatura (Avançado):** Em sistemas maiores ou com múltiplos tenants, pode ser necessário controlar quais módulos/usuários podem publicar ou assinar determinados tópicos. Isso não parece ser uma necessidade inicial aqui, mas é uma consideração futura.
*   **Abuso de Publicação:** Um módulo defeituoso publicando um grande volume de eventos pode sobrecarregar o EventBus. Limites de taxa na publicação ou no tamanho da fila podem ser considerados, embora aumentem a complexidade.
*   **Segurança do Assinante:** Assinantes maliciosos ou comprometidos podem ganhar acesso a informações através dos eventos. O design deve garantir que os eventos contenham apenas as informações necessárias para os casos de uso legítimos.

## 🧑‍💻 13. Contribuição

*   **Nomeação de Tópicos:** Use um padrão consistente para nomear tópicos, por exemplo: `dominio.entidade.acao` (ex: `accounts.user.created`, `payments.transaction.succeeded`).
*   **Payloads de Eventos:** Defina structs ou mapas bem definidos para os payloads de cada tipo de evento. Considere versionar os schemas dos payloads se grandes mudanças forem esperadas.
*   **Idempotência de Assinantes:** Assinantes devem, idealmente, ser idempotentes no processamento de eventos, pois em alguns cenários de falha/retry, um evento pode ser entregue mais de uma vez.
*   **Testes:** Ao adicionar novos eventos ou assinantes, garanta que os testes cubram os fluxos de publicação e consumo.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar um `StorageAdapter` para persistir eventos em um banco de dados, garantindo a entrega mesmo após reinícios.
*   [ ] Desenvolver uma Dead-Letter Queue (DLQ) para eventos que falham consistentemente, permitindo análise e reprocessamento manual.
*   [ ] Adicionar suporte para filtragem de eventos no lado do assinante (assinante especifica um filtro além do tópico).
*   [ ] Explorar a integração com um sistema de filas externo mais robusto (RabbitMQ, Kafka) para cenários de alta carga ou necessidade de garantias de entrega mais fortes.
*   [ ] Adicionar uma interface de administração (Console ou Web) para visualizar o estado do EventBus, filas, assinantes e gerenciar a DLQ.
*   [ ] Implementar ordenação de eventos garantida por tópico (se necessário para casos de uso específicos).
*   [ ] Considerar \"eventos de resposta\" ou coreografia de saga para fluxos de trabalho mais complexos.

---

*Última atualização: 2025-05-11*

---

Este é um exemplo detalhado para o `DeeperHub.Core.EventBus`. Posso continuar com o próximo módulo, talvez o `DeeperHub.Core.ConfigManager` ou algum outro de sua preferência?"""),
            ],
        ),
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(text="""proximo"""),
            ],
        ),
        types.Content(
            role="model",
            parts=[
                types.Part.from_text(text="""Excelente! Vamos prosseguir com a documentação do módulo `DeeperHub.Core.ConfigManager`. Este é outro componente crucial, pois centraliza a forma como o sistema acessa suas configurações.

---

