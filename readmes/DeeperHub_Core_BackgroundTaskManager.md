# Módulo: `Deeper_Hub.Core.BackgroundTaskManager` 🚀

## 📜 1. Visão Geral do Módulo `Deeper_Hub.Core.BackgroundTaskManager`

O módulo `Deeper_Hub.Core.BackgroundTaskManager` é o sistema centralizado para **gerenciar e executar tarefas em segundo plano (background tasks)** no Deeper_Hub. Ele permite que a aplicação enfileire trabalhos para execução assíncrona, desacoplando operações demoradas ou não críticas do fluxo principal de interação do usuário.

Isso é crucial para manter a responsividade da aplicação, processar grandes volumes de dados, interagir com serviços externos lentos e agendar tarefas recorrentes. O BackgroundTaskManager abstrai a biblioteca ou o mecanismo de enfileiramento subjacente (ex: Oban, Exq, Broadway, ou um sistema customizado baseado em GenServer/ETS). 😊

*(Nota: A documentação original tem `Deeper_Hub.BackgroundTasks` com vários submódulos como `BackgroundTasksFacade`, `Adapters.BackgroundTasksAdapter`, `Services.DefaultBackgroundTaskService`, etc. Esta documentação consolida a fachada em `Deeper_Hub.Core.BackgroundTaskManager` e assume que a lógica de serviço e adaptação pode residir em `Deeper_Hub.BackgroundTasks.*` como um submódulo do Core ou um contexto de domínio próprio, dependendo da complexidade desejada.)*

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Enfileiramento de Tarefas (`enqueue_task/3` ou `schedule_task/3`):**
    *   Permitir que qualquer módulo da aplicação enfileire uma tarefa para execução assíncrona.
    *   Especificar o módulo e função do \"worker\" a ser executado e seus argumentos.
*   **Agendamento de Tarefas (`schedule_recurring_task/4`):**
    *   Agendar tarefas para execução em um momento específico no futuro.
    *   Agendar tarefas recorrentes (ex: usando sintaxe cron).
*   **Execução de Tarefas:**
    *   Gerenciar um pool de workers para processar tarefas da fila.
    *   Garantir que as tarefas sejam executadas de forma isolada e confiável.
*   **Gerenciamento de Filas (Opcional, dependendo do backend):**
    *   Suporte a múltiplas filas com diferentes prioridades.
*   **Políticas de Retentativa:**
    *   Implementar retentativas automáticas para tarefas que falham, com backoff exponencial configurável.
    *   Definir um número máximo de tentativas.
*   **Tratamento de Falhas e Dead-Letter Queue (DLQ):**
    *   Mover tarefas que falham consistentemente para uma DLQ para análise manual.
*   **Monitoramento e Status de Tarefas (`get_task_status/2`):**
    *   Permitir a consulta do status de tarefas individuais (pendente, em execução, concluída, falha).
    *   Fornecer estatísticas sobre o sistema de tarefas (número de tarefas na fila, workers ativos, taxa de erro, etc.) (`get_statistics/1`).
*   **Cancelamento de Tarefas (`cancel_task/2`, `cancel_recurring_task/2`):**
    *   Permitir o cancelamento de tarefas pendentes ou agendadas.
*   **Abstração de Backend:**
    *   Fornecer uma interface (`BackgroundTasksBehaviour`) para que diferentes backends de enfileiramento (Oban, Exq, etc.) possam ser usados.
*   **Observabilidade:**
    *   Registrar logs detalhados sobre o ciclo de vida das tarefas.
    *   Emitir métricas sobre o desempenho do sistema de tarefas.
*   **Limpeza de Tarefas Antigas (`cleanup_old_tasks/2`):**
    *   Remover registros de tarefas concluídas ou falhas antigas para manter o sistema limpo.
*   **Idempotência (Responsabilidade do Worker):**
    *   Os workers devem ser projetados para serem idempotentes, se possível, para lidar com reprocessamentos.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`Deeper_Hub.Core.BackgroundTaskManager` (Fachada Pública):**
    *   Ponto de entrada para enfileirar, agendar e gerenciar tarefas.
    *   Delega para o `BackgroundTasksAdapter` configurado.
2.  **`Deeper_Hub.BackgroundTasks.Adapters.BackgroundTasksAdapter` (Behaviour e Implementações):**
    *   **Responsabilidade:** Abstrair a biblioteca de enfileiramento subjacente.
    *   **Comportamento (`BackgroundTasksBehaviour`):** Define a interface.
    *   **Implementações:**
        *   `ObanAdapter`: Para integrar com a biblioteca Oban.
        *   `ExqAdapter`: Para integrar com Exq (baseado em Redis).
        *   `SimpleEtsQueueAdapter` (GenServer/ETS): Uma implementação leve para cenários mais simples ou testes, sem persistência robusta entre reinícios.
        *   `NoOpAdapter`: Não executa tarefas, útil para desabilitar em certos ambientes.
3.  **Workers de Tarefas (Definidos pela Aplicação):**
    *   Módulos Elixir que implementam a lógica de uma tarefa específica. Eles geralmente seguem um comportamento esperado pelo backend de enfileiramento (ex: `Oban.Worker`).
    *   Ex: `Deeper_Hub.Notifications.Workers.EmailWorker`, `Deeper_Hub.Audit.Workers.LogProcessingWorker`.
4.  **Backend de Enfileiramento (Externo ou Embutido):**
    *   O sistema real que armazena as filas e gerencia os workers (ex: PostgreSQL para Oban, Redis para Exq, ou ETS para uma solução simples).
5.  **`Deeper_Hub.BackgroundTasks.Supervisor` (ou `UnifiedSupervisor`):**
    *   Supervisiona os processos do adaptador de tarefas (se for um GenServer) e quaisquer workers de gerenciamento interno (ex: `CleanupWorker`). O backend de enfileiramento (como Oban) geralmente tem seu próprio supervisor.
6.  **`Deeper_Hub.BackgroundTasks.Integrations.AuditIntegration`, `EventIntegration`, `MetricsIntegration`, `NotificationIntegration`:**
    *   Submódulos para integrar o sistema de tarefas com auditoria, eventos, métricas e notificações.
7.  **Configurações (via `Deeper_Hub.Core.ConfigManager`):**
    *   Qual adaptador usar, configurações de conexão para o backend (Redis URL, DB Repo), configurações de fila, políticas de retry padrão, etc.

### 3.2. Estrutura de Diretórios (Proposta para `BackgroundTasks` como submódulo do Core ou contexto)

Se for um contexto próprio:
```
background_tasks/
├── background_task_manager.ex      # Fachada Pública (Core.BackgroundTaskManager)
│
├── adapters/
│   ├── background_tasks_adapter.ex   # Behaviour e Default Adapter (que usa uma implementação)
│   ├── oban_adapter.ex
│   └── simple_ets_queue_adapter.ex
│
├── services/                       # (Se a lógica do adapter for complexa)
│   └── default_background_tasks_service.ex # Exemplo de serviço que usa o adapter
│
├── integrations/
│   ├── audit_integration.ex
│   ├── event_integration.ex
│   ├── metrics_integration.ex
│   └── notification_integration.ex
│
├── schema/                         # Schemas Ecto se o backend (ex: Oban) usar o DB
│   └── oban_jobs_schema.ex         # (Geralmente definido pela biblioteca Oban)
│
├── supervisor.ex
└── telemetry.ex
```
Ou se a fachada `Core.BackgroundTaskManager` delega diretamente para adaptadores em `BackgroundTasks`:
```
core/
└── background_task_manager.ex      # Fachada Pública

background_tasks/    # Lógica e adaptadores
├── adapters/
│   ├── background_tasks_adapter.ex   # Behaviour
│   ├── oban_adapter.ex
│   └── ...
├── integrations/
│   └── ...
├── supervisor.ex
└── telemetry.ex
```

### 3.3. Decisões de Design Importantes

*   **Escolha do Backend:** A escolha da biblioteca de enfileiramento (Oban, Exq, Broadway, etc.) é uma decisão arquitetural chave e depende dos requisitos de persistência, confiabilidade, monitoramento e complexidade. Oban (com PostgreSQL) é uma escolha popular e robusta em Elixir.
*   **Idempotência dos Workers:** Os workers devem ser projetados para serem idempotentes sempre que possível, pois as tarefas podem ser reexecutadas devido a falhas ou reinícios.
*   **Serialização de Argumentos:** Os argumentos das tarefas devem ser serializáveis (termos simples, mapas, listas) para serem armazenados na fila.
*   **Concorrência e Recursos:** Configurar o número de workers e filas para balancear o processamento de tarefas com os recursos disponíveis do sistema.

## 🛠️ 4. Casos de Uso Principais

*   **Envio de Email de Boas-Vindas:**
    *   Após um usuário se registrar, `Deeper_Hub.Accounts` enfileira uma tarefa: `BackgroundTaskManager.enqueue_task(Deeper_Hub.Notifications.Workers.EmailWorker, :send_welcome_email, [user_id])`.
    *   O `EmailWorker` executa assincronamente, constrói e envia o email.
*   **Processamento de Upload de Vídeo:**
    *   Usuário faz upload de um vídeo. O controller API salva o arquivo e enfileira uma tarefa: `BackgroundTaskManager.enqueue_task(MyApp.VideoProcessingWorker, :process_video, [video_id, %{target_formats: [\"mp4\", \"webm\"]}])`.
    *   O `VideoProcessingWorker` realiza a transcodificação demorada em background.
*   **Limpeza Diária de Dados:**
    *   Uma tarefa recorrente é agendada: `BackgroundTaskManager.schedule_recurring_task(MyApp.DataCleanupWorker, :cleanup_old_records, [], \"0 3 * * *\")` (às 3 da manhã todos os dias).
*   **Sincronização com API Externa:**
    *   `BackgroundTaskManager.enqueue_task(MyApp.ExternalSyncWorker, :sync_product_data, [product_id], opts_with_retry)`.

## 🌊 5. Fluxos Importantes

### Fluxo de Enfileiramento e Execução de Tarefa (Exemplo com Oban-like)

1.  **Módulo Chamador:** Chama `Deeper_Hub.Core.BackgroundTaskManager.enqueue_task(MyApp.MyWorker, :perform, [arg1, arg2], opts)`.
2.  **`Core.BackgroundTaskManager` (Fachada):** Delega para o `BackgroundTasksAdapter`.
3.  **`BackgroundTasksAdapter` (ex: `ObanAdapter`):**
    *   Cria um novo job Oban (ou o formato do backend) com os argumentos serializados, nome do worker, opções de fila, retentativas, etc.
    *   Insere o job no banco de dados (PostgreSQL, no caso do Oban).
    *   Retorna `{:ok, task_id}` (ID do job Oban).
4.  **Backend de Enfileiramento (Oban):**
    *   Workers Oban (processos separados) monitoram o banco de dados por novos jobs em suas filas.
    *   Um worker disponível pega o job.
    *   Desserializa os argumentos.
    *   Chama a função `perform/1` (ou `perform/2` com o job) do `MyApp.MyWorker` com os argumentos.
5.  **`MyApp.MyWorker`:**
    *   Executa a lógica da tarefa.
    *   **Sucesso:** Retorna `{:ok, result}` ou `:ok`. O backend marca o job como `completed`.
    *   **Falha (Exceção):** O backend captura a exceção, marca o job como `retryable` (ou `discarded` se exceder retentativas), registra o erro, e agenda uma retentativa conforme a política.
    *   **Falha (Retorno `{:error, reason}`):** Similar à exceção.

## 📡 6. API (Funções Públicas da Fachada `Deeper_Hub.Core.BackgroundTaskManager`)

*(Baseado na documentação original, consolidando e clarificando)*

### 6.1. `Deeper_Hub.Core.BackgroundTaskManager.enqueue_task(worker_module :: module(), function_atom :: atom(), args :: list(), opts :: keyword()) :: {:ok, String.t()} | {:error, term()}`

*   **Descrição:** Enfileira uma tarefa para execução assíncrona o mais rápido possível.
*   **`worker_module`:** O módulo do worker que contém a função a ser executada.
*   **`function_atom`:** O nome da função a ser executada no worker (ex: `:perform`).
*   **`args`:** Lista de argumentos a serem passados para a função do worker. Devem ser serializáveis.
*   **`opts`:**
    *   `:queue` (String.t | atom): Nome da fila para enfileirar a tarefa. (Padrão: fila default do backend)
    *   `:priority` (integer): Prioridade da tarefa (se suportado pelo backend).
    *   `:max_attempts` (integer): Número máximo de tentativas. (Padrão: config global)
    *   `:retry_delay_seconds` (integer): Atraso base para retentativas.
    *   `:timeout_seconds` (integer): Timeout de execução da tarefa.
    *   `:unique_for_seconds` (integer | nil): Se definido, garante que apenas uma tarefa com a mesma combinação worker/função/args seja enfileirada dentro deste período.
*   **Retorno:** `{:ok, task_id}` (ID único da tarefa/job) ou `{:error, reason}`.

### 6.2. `Deeper_Hub.Core.BackgroundTaskManager.schedule_task(worker_module :: module(), function_atom :: atom(), args :: list(), scheduled_at :: DateTime.t() | non_neg_integer(), opts :: keyword()) :: {:ok, String.t()} | {:error, term()}`

*   **Descrição:** Agenda uma tarefa para ser executada em um momento específico no futuro ou após um atraso.
*   **`scheduled_at`:** Um `DateTime.t()` para agendamento absoluto, ou um `non_neg_integer()` para segundos de atraso a partir de agora.
*   *(Outros parâmetros e `opts` similares a `enqueue_task/4`)*

### 6.3. `Deeper_Hub.Core.BackgroundTaskManager.schedule_recurring_task(task_name_id :: String.t(), worker_module :: module(), function_atom :: atom(), args :: list(), cron_expression :: String.t(), opts :: keyword()) :: {:ok, String.t()} | {:error, term()}`

*   **Descrição:** Agenda uma tarefa para execução recorrente usando uma expressão CRON.
*   **`task_name_id`:** Um ID único para identificar esta tarefa recorrente (para atualizações/cancelamento).
*   **`cron_expression`:** Ex: `\"0 * * * *\"` (a cada hora).
*   *(Outros parâmetros e `opts` similares a `enqueue_task/4`, mais opções de timezone, etc.)*

### 6.4. `Deeper_Hub.Core.BackgroundTaskManager.cancel_task(task_id :: String.t(), opts :: keyword()) :: :ok | {:error, :not_found | term()}`

*   **Descrição:** Tenta cancelar uma tarefa pendente ou agendada. Não garante o cancelamento se a tarefa já estiver em execução.
*   **`opts`:** `:reason` (String.t).

### 6.5. `Deeper_Hub.Core.BackgroundTaskManager.cancel_recurring_task(task_name_id :: String.t(), opts :: keyword()) :: :ok | {:error, :not_found | term()}`

*   **Descrição:** Cancela/desabilita uma tarefa recorrente.

### 6.6. `Deeper_Hub.Core.BackgroundTaskManager.get_task_status(task_id :: String.t(), opts :: keyword()) :: {:ok, TaskStatus.t()} | {:error, :not_found | term()}`

*   **Descrição:** Obtém o status atual de uma tarefa.
*   **`TaskStatus.t()`:** `%{id: String.t(), status: :pending | :running | :completed | :failed | :retryable | :discarded, queue: String.t, worker: module(), attempts: integer(), last_error: String.t() | nil, inserted_at: DateTime.t(), scheduled_at: DateTime.t() | nil}`.

### 6.7. `Deeper_Hub.Core.BackgroundTaskManager.list_tasks(opts :: keyword()) :: {:ok, list(TaskStatus.t()), Pagination.t()} | {:error, term()}`

*   **Descrição:** Lista tarefas com filtros e paginação.
*   **`opts`:** `:status`, `:queue`, `:worker_module`, `:page`, `:per_page`, `:sort_by`.
*   **`Pagination.t()`:** `%{total_entries: integer(), total_pages: integer(), page_number: integer(), page_size: integer()}`.

### 6.8. `Deeper_Hub.Core.BackgroundTaskManager.get_statistics(opts :: keyword()) :: {:ok, map()}`

*   **Descrição:** Retorna estatísticas sobre as filas e workers.
*   **Exemplo de Retorno:** `%{queues: %{\"default\" => %{pending: 100, running: 5, failed_today: 2}, ...}, workers_summary: %{total_busy: 5, total_idle: 15}}`.

## ⚙️ 7. Configuração

Via `Deeper_Hub.Core.ConfigManager`:

*   **`[:core, :background_tasks, :enabled]`** (Boolean): Habilita/desabilita o sistema. (Padrão: `true`)
*   **`[:core, :background_tasks, :adapter]`** (Module): Módulo adaptador a ser usado (ex: `Deeper_Hub.BackgroundTasks.Adapters.ObanAdapter`). (Obrigatório se enabled)
*   **`[:core, :background_tasks, :default_queue_name]`** (String): Nome da fila padrão. (Padrão: `\"default\"`)
*   **`[:core, :background_tasks, :default_max_attempts]`** (Integer): Número máximo de tentativas padrão para tarefas. (Padrão: `5`)
*   **`[:core, :background_tasks, :default_retry_delay_seconds]`** (Integer): Atraso base para retentativas.
*   **`[:core, :background_tasks, :cleanup_worker, :retention_days_completed]`** (Integer): Retenção para jobs concluídos.
*   **`[:core, :background_tasks, :cleanup_worker, :retention_days_failed]`** (Integer): Retenção para jobs que falharam permanentemente.
*   **Configurações específicas do adaptador (prefixadas):**
    *   Ex: `[:core, :background_tasks, :oban_adapter, :repo]` (Módulo Ecto.Repo para Oban).
    *   Ex: `[:core, :background_tasks, :oban_adapter, :queues]` (Configuração de filas Oban).
    *   Ex: `[:core, :background_tasks, :exq_adapter, :redis_url]`.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `Deeper_Hub.Core.ConfigManager`: Para configurações.
*   `Deeper_Hub.Core.Logger`: Para logging.
*   `Deeper_Hub.Core.Metrics`: Para métricas.
*   `Deeper_Hub.Core.Supervisor` (indireta): Para supervisionar o adaptador e workers.
*   `Deeper_Hub.BackgroundTasks.Integrations.*`: Para auditoria, eventos, etc.

### 8.2. Bibliotecas Externas

*   A biblioteca de enfileiramento escolhida (ex: `Oban`, `Exq`).
*   `Jason` (ou similar) para serialização de argumentos de tarefas, se o backend exigir.

## 🤝 9. Como Usar / Integração

**Enfileirando uma Tarefa Simples:**
```elixir
defmodule MyApp.EmailService do
  alias Deeper_Hub.Core.BackgroundTaskManager

  def send_welcome_email_async(user_id) do
    BackgroundTaskManager.enqueue_task(
      MyApp.Workers.EmailSenderWorker, 
      :send_welcome, 
      [user_id],
      queue: \"emails\" # Opcional, usar fila específica
    )
  end
end

defmodule MyApp.Workers.EmailSenderWorker do
  # Se usando Oban: use Oban.Worker
  # Se usando um sistema simples, pode ser um módulo com uma função `perform`
  
  def perform(user_id) do # ou perform(%Oban.Job{args: %{\"user_id\" => user_id}})
    # ... lógica para buscar usuário e enviar email ...
    :ok
  end
end
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar o enfileiramento de tarefas e verificar se são processadas (usando um backend de teste ou mocks).
*   Testar a lógica de retentativa com workers que falham.
*   Testar o agendamento de tarefas futuras e recorrentes.
*   Testar o cancelamento de tarefas.
*   Testar a consulta de status e listagem de tarefas.
*   Localização: `test/deeper_hub/core/background_task_manager/` e `test/deeper_hub/background_tasks/`.

### 10.2. Métricas (via `BackgroundTasks.Integrations.MetricsIntegration`)

*   `deeper_hub.background_tasks.jobs.enqueued.count` (tags: `queue`, `worker_module`)
*   `deeper_hub.background_tasks.jobs.processed.count` (tags: `queue`, `worker_module`, `status` (`completed`, `failed`, `discarded`))
*   `deeper_hub.background_tasks.jobs.execution_time_ms` (Histograma, tags: `queue`, `worker_module`)
*   `deeper_hub.background_tasks.jobs.wait_time_ms` (Histograma, tags: `queue`, `worker_module`): Tempo na fila.
*   `deeper_hub.background_tasks.queue.size.gauge` (Gauge, tags: `queue_name`): Número de jobs pendentes.
*   `deeper_hub.background_tasks.workers.active.gauge` (Gauge, tags: `queue_name`): Número de workers ativos processando.
*   `deeper_hub.background_tasks.workers.available.gauge` (Gauge, tags: `queue_name`): Número de workers ociosos.

### 10.3. Logs

*   **Nível INFO:** Tarefa enfileirada, tarefa iniciada, tarefa concluída com sucesso. Execução de cleanup.
*   **Nível WARNING:** Tarefa falhou e será retentada. Fila atingindo alta capacidade.
*   **Nível ERROR:** Tarefa falhou após todas as tentativas e foi descartada (DLQ). Erro crítico no sistema de background tasks.

### 10.4. Telemetria (via biblioteca de backend ou `BackgroundTasks.Telemetry`)

As bibliotecas como Oban já emitem muitos eventos Telemetry. Se for uma implementação customizada, definir eventos como:
*   `[:deeper_hub, :background_tasks, :job, :enqueue]`
*   `[:deeper_hub, :background_tasks, :job, :start]`
*   `[:deeper_hub, :background_tasks, :job, :stop]` (com status de sucesso/falha)
*   `[:deeper_hub, :background_tasks, :job, :retry]`

## ❌ 11. Tratamento de Erros

*   **Falha no Worker:** O backend de enfileiramento deve capturar exceções nos workers, registrar o erro e aplicar a política de retentativa.
*   **Backend Indisponível:** Se o backend (ex: DB para Oban, Redis para Exq) estiver indisponível, o enfileiramento de novas tarefas falhará. A aplicação deve lidar com isso (ex: logar o erro e talvez tentar mais tarde, ou informar o usuário se a ação for crítica).
*   **Serialização de Argumentos:** Erros ao serializar/desserializar argumentos de tarefas devem ser tratados, geralmente resultando em falha da tarefa.

## 🛡️ 12. Considerações de Segurança

*   **Dados Sensíveis em Argumentos:** Evite passar dados altamente sensíveis como argumentos de tarefas, se possível. Se necessário, os dados devem ser criptografados ou referenciados por ID para serem buscados pelo worker de forma segura.
*   **Workers com Acesso Controlado:** Workers que realizam operações privilegiadas devem ser projetados com segurança em mente, validando seus argumentos e interagindo com outros serviços de forma segura.
*   **Segurança do Backend de Fila:** Proteger o acesso ao backend de fila (DB, Redis) é crucial.

## 🧑‍💻 13. Contribuição

*   Ao criar novos workers, certifique-se de que eles sejam idempotentes.
*   Defina configurações de fila, prioridade e retentativa apropriadas para cada tipo de tarefa.
*   Adicione logging e métricas relevantes dentro dos seus workers.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar uma UI administrativa para visualizar filas, gerenciar tarefas (cancelar, reenfileirar, ver detalhes de erro) e estatísticas. (Muitas bibliotecas como Oban já oferecem isso).
*   [ ] Adicionar suporte para \"workflows\" ou \"sagas\" onde múltiplas tarefas dependem umas das outras.
*   [ ] Permitir o cancelamento de tarefas que já estão em execução (se o worker suportar interrupção graciosa).
*   [ ] Melhorar o balanceamento de carga entre múltiplas instâncias da aplicação para processamento de tarefas.
*   [ ] Adicionar \"throttling\" de tarefas para evitar sobrecarregar APIs externas ou recursos internos.

---

*Última atualização: 2025-05-12*

---

Este módulo é um burro de carga para a aplicação, permitindo muita flexibilidade e resiliência.

O que gostaria de documentar a seguir? Talvez `Deeper_Hub.Shared.Utils` para cobrir os utilitários gerais, ou podemos começar com um módulo de domínio como `Deeper_Hub.Servers`?"""),
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
                types.Part.from_text(text="""Ok! Vamos para `Deeper_Hub.Servers`. Este será o nosso primeiro módulo de domínio \"principal\" a ser detalhado, e ele provavelmente usará muitos dos módulos Core e Security que já documentamos.

---

