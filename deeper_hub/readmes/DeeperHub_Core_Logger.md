# Módulo: `Deeper_Hub.Core.Logger` 🚀

## 📜 1. Visão Geral do Módulo `Deeper_Hub.Core.Logger`

O módulo `Deeper_Hub.Core.Logger` serve como a fachada centralizada e padronizada para todas as operações de logging dentro do sistema Deeper_Hub. Ele abstrai a implementação de logging subjacente (que pode ser o `Logger` padrão do Elixir, um backend customizado, ou integração com serviços externos como Logstash, Datadog, etc.), fornecendo uma API consistente para todos os módulos da aplicação.

Seu principal objetivo é garantir que os logs sejam estruturados, ricos em contexto, e facilmente pesquisáveis, facilitando a depuração, monitoramento e análise do comportamento do sistema. 😊

*(Nota: A documentação original mencionava `Deeper_Hub.Logger` e `Deeper_Hub.Core.LoggerFacade`, e também `Deeper_Hub.Core.Services.LoggerFacade`. Esta documentação consolida a ideia de uma única fachada principal `Deeper_Hub.Core.Logger` que delega para uma implementação mais robusta, como o `Deeper_Hub.Shared.Logging.StructuredLogger` mencionado.)*

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Interface de Logging Unificada:**
    *   Fornecer funções para diferentes níveis de severidade: `debug/3`, `info/3`, `warn/3`, `error/3`, `critical/3` (e potencialmente `emergency/3`, `notice/3` como visto na documentação original).
    *   Aceitar uma mensagem e um mapa de metadados para logs estruturados.
*   **Enriquecimento Automático de Logs:**
    *   Adicionar automaticamente informações contextuais a cada log, como:
        *   Timestamp.
        *   Nível de severidade.
        *   Módulo de origem.
        *   Nome da função e aridade (opcional, via macro).
        *   PID do processo.
        *   ID de Correlação/Trace ID (se integrado com `DistributedTracing`).
*   **Suporte a Contexto de Logging:**
    *   Permitir que os módulos definam metadados de contexto que são automaticamente incluídos em todos os logs subsequentes dentro daquele processo ou escopo (via `Deeper_Hub.Shared.Logging.Context`).
*   **Formatação Estruturada:**
    *   Garantir que os logs sejam formatados de maneira consistente (ex: JSON) para facilitar a análise por ferramentas de logging.
*   **Configurabilidade de Backends:**
    *   Permitir a configuração de múltiplos backends de logging (console, arquivo, serviço externo) através do `Deeper_Hub.Core.ConfigManager`.
    *   Suportar diferentes níveis de log por backend.
*   **Sanitização de Dados Sensíveis (Integração):**
    *   Integrar com um serviço de sanitização (como `Deeper_Hub.Security.LogSanitizer`) para remover ou mascarar dados sensíveis dos logs antes da escrita.
*   **Integração com Métricas:**
    *   Opcionalmente, registrar métricas sobre o volume e tipos de logs gerados.
*   **Emojis Configuráveis (Nice-to-have):**
    *   Permitir a configuração de emojis para diferentes níveis de log para melhorar a legibilidade no console (via `Deeper_Hub.Logger.Config`).

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`Deeper_Hub.Core.Logger` (Fachada Pública):**
    *   **Responsabilidade:** É a API pública que todos os módulos usam para registrar logs.
    *   **Interações:**
        *   Coleta informações de contexto (módulo, função) automaticamente (potencialmente usando macros).
        *   Obtém o contexto de logging do processo (via `Deeper_Hub.Shared.Logging.Context`).
        *   Obtém o ID de correlação (via `Deeper_Hub.Shared.Logging.DistributedTracing`).
        *   Chama o `Deeper_Hub.Core.Logger.Adapter` para processar e enviar o log.
2.  **`Deeper_Hub.Core.Logger.Adapter` (Behaviour e Implementação Padrão):**
    *   **Responsabilidade:** Abstrair a lógica de processamento e envio de logs para os backends.
    *   **Comportamento (`LoggerBehaviour`):** Define a interface que os adaptadores devem implementar.
    *   **Implementação Padrão (`DefaultLoggerAdapter` ou `StructuredLoggerAdapter`):**
        *   Pode ser um GenServer para enfileirar logs e processá-los assincronamente (para evitar bloqueio).
        *   Formata a mensagem e os metadados em uma estrutura padronizada (ex: JSON).
        *   Integra com o `LogSanitizer` para remover dados sensíveis.
        *   Itera sobre os backends configurados e envia o log formatado para cada um que corresponda ao nível de severidade.
3.  **`Deeper_Hub.Shared.Logging.StructuredLogger` (GenServer, ex-`Deeper_Hub.Logger.StructuredLogger`):**
    *   **Responsabilidade:** Pode ser a implementação central do `DefaultLoggerAdapter`. Gerencia múltiplos backends de logging e despacha mensagens de log formatadas com contexto e metadados.
    *   **Estado Interno:** Lista de backends configurados, filtros por backend.
4.  **Backends de Logging (Exemplos):**
    *   `Logger.Backends.Console`: Backend padrão do Elixir para o console.
    *   `Logger.Backends.File`: Para escrever logs em arquivos.
    *   Adaptadores customizados para serviços como Datadog, Logstash, Sentry, etc.
5.  **`Deeper_Hub.Shared.Logging.Context`:**
    *   **Responsabilidade:** Gerenciar metadados de contexto por processo.
6.  **`Deeper_Hub.Logger.Config` (Opcional, para Emojis):**
    *   **Responsabilidade:** Gerenciar a configuração de emojis para níveis de log.

### 3.2. Estrutura de Diretórios (Proposta)

```
core/logger/
├── logger.ex                     # Fachada Pública
├── adapter.ex                    # Behaviour e Default Adapter (ou StructuredLoggerAdapter)
│
├── backends/                     # (Opcional) Adaptadores customizados para backends
│   └── datadog_backend.ex
│
└── supervisor.ex                 # Supervisor para os processos do Logger (ex: StructuredLogger GenServer)

shared/logging/    # Módulos compartilhados de logging
├── structured_logger.ex          # Implementação central do GenServer de logging
├── context.ex
└── distributed_tracing.ex        # Se o trace_id for gerenciado aqui

logger/            # (Opcional) Se manter separação para Config de Emojis
├── config.ex                     # Configuração de Emojis
└── interface.ex                  # Interface simplificada (se necessária)
```

### 3.3. Decisões de Design Importantes

*   **Log Estruturado como Padrão:** Todos os logs devem ser estruturados (ex: JSON) para facilitar a consulta e análise por ferramentas automatizadas.
*   **Contexto é Rei:** Enriquecer logs com o máximo de contexto relevante (automático e manual) é crucial para depuração.
*   **Desempenho:** O logging não deve impactar significativamente o desempenho das operações principais. O processamento e envio para backends remotos deve ser assíncrono.
*   **Sanitização Obrigatória:** Dados sensíveis *nunca* devem vazar para os logs. A integração com um `LogSanitizer` é fundamental.
*   **Configurabilidade:** Níveis de log e backends devem ser facilmente configuráveis por ambiente e, idealmente, em tempo de execução para alguns casos.

## 🛠️ 4. Casos de Uso Principais

*   **Desenvolvedor Depura um Fluxo:** Um desenvolvedor usa `Logger.debug(\"Estado da variável X\", %{variable_x: data})` para inspecionar o estado durante a execução.
*   **Operação Concluída com Sucesso:** Um serviço registra `Logger.info(\"Pedido processado com sucesso\", %{order_id: 123, user_id: 456})`.
*   **Condição Inesperada mas Não Crítica:** O sistema detecta uma configuração opcional ausente e registra `Logger.warn(\"Configuração de cache não encontrada, usando padrão.\", %{cache_type: :local})`.
*   **Erro Tratado:** Uma API externa retorna um erro esperado, e o sistema registra `Logger.error(\"Falha ao buscar dados da API externa\", %{api: \"WeatherService\", error: \"timeout\", retry_attempt: 2})`.
*   **Falha Crítica:** O banco de dados fica indisponível. `Logger.critical(\"Conexão com banco de dados perdida!\", %{db_host: \"...\", error_details: e})`.

## 🌊 5. Fluxos Importantes

### Fluxo de Registro de Log

1.  **Módulo Chamador:** Chama uma função da fachada `Deeper_Hub.Core.Logger` (ex: `Logger.info(message, metadata)`).
    *   Macros podem capturar `__MODULE__`, `__ENV__.function`.
2.  **`Deeper_Hub.Core.Logger` (Fachada):**
    *   Obtém o contexto de `Deeper_Hub.Shared.Logging.Context.get_all()`.
    *   Obtém o `trace_id` de `Deeper_Hub.Shared.Logging.DistributedTracing.current_trace_id()`.
    *   Combina os metadados fornecidos, contexto automático e contexto do processo.
    *   Encaminha a mensagem, nível e metadados combinados para o `Deeper_Hub.Core.Logger.Adapter`.
3.  **`Deeper_Hub.Core.Logger.Adapter` (ex: `StructuredLoggerAdapter`):**
    *   Recebe os dados do log.
    *   (Opcional) Enfileira o log para processamento assíncrono se for um GenServer.
    *   Formata o log em uma estrutura padronizada (ex: JSON), incluindo timestamp, nível, mensagem, módulo, função, trace_id, e todos os metadados.
    *   **Chama o `LogSanitizer` para remover/mascarar dados sensíveis do log formatado.**
    *   Para cada backend de logging configurado:
        *   Verifica se o nível do log atual é igual ou superior ao nível configurado para o backend.
        *   Se sim, envia o log sanitizado e formatado para o backend.
4.  **Backend de Logging:**
    *   Escreve o log no destino (console, arquivo, serviço externo).

## 📡 6. API (Funções Públicas da Fachada)

As funções principais já foram vistas na documentação original (`debug/3`, `info/3`, `warn/3`, `error/3`, `critical/3`). A principal mudança é a adição de `module` como primeiro argumento ou a captura automática via macro, e metadados como último argumento.

### Exemplo de API Refinada (usando módulo como primeiro argumento):

```elixir
defmodule Deeper_Hub.Core.Logger do
  # ... (macros para capturar __ENV__.function, etc. podem estar aqui) ...

  defp call_adapter(level, module, message_or_fun, metadata) do
    # Lógica para obter contexto, trace_id, etc.
    # Lógica para avaliar message_or_fun se for uma função
    # ...
    # Deeper_Hub.Core.Logger.Adapter.log(level, full_context_map_with_message)
  end

  def debug(module, message_or_fun, metadata \\\\ %{}) do
    call_adapter(:debug, module, message_or_fun, metadata)
  end

  def info(module, message_or_fun, metadata \\\\ %{}) do
    call_adapter(:info, module, message_or_fun, metadata)
  end

  def warn(module, message_or_fun, metadata \\\\ %{}) do
    call_adapter(:warn, module, message_or_fun, metadata)
  end

  def error(module, message_or_fun, metadata \\\\ %{}) do
    call_adapter(:error, module, message_or_fun, metadata)
  end

  def critical(module, message_or_fun, metadata \\\\ %{}) do
    call_adapter(:critical, module, message_or_fun, metadata)
  end

  # Funções para gerenciar contexto (delegam para Deeper_Hub.Shared.Logging.Context)
  def set_context(metadata_map), do: Deeper_Hub.Shared.Logging.Context.put(metadata_map)
  def put_context(key, value), do: Deeper_Hub.Shared.Logging.Context.put(key, value)
  def get_context(), do: Deeper_Hub.Shared.Logging.Context.get_all()
  def clear_context(), do: Deeper_Hub.Shared.Logging.Context.clear()

  # Funções para gerenciar trace_id (delegam para Deeper_Hub.Shared.Logging.DistributedTracing)
  def start_trace(name, metadata \\\\ %{}), do: Deeper_Hub.Shared.Logging.DistributedTracing.start_trace(name, metadata)
  # ... outros ...
end
```

## ⚙️ 7. Configuração

Configurações gerenciadas pelo `Deeper_Hub.Core.ConfigManager`:

*   `[:core, :logger, :level]` (Atom): Nível de log global padrão (ex: `:info`). (Padrão: `:info` para prod, `:debug` para dev).
*   `[:core, :logger, :format]` (Atom): Formato de log padrão (:json, :text). (Padrão: `:json` para prod, `:text` para dev).
*   `[:core, :logger, :backends]` (List de Maps): Configuração dos backends de logging.
    Exemplo:
    ```elixir
    [
      %{
        name: :console,
        adapter: Logger.Backends.Console,
        level: :debug, # Nível específico para este backend
        format: :text, # Formato específico
        metadata: [:request_id, :user_id] # Metadados a incluir
      },
      %{
        name: :file,
        adapter: Logger.Backends.File,
        path: \"/var/log/deeper_hub/app.log\",
        level: :info,
        format: :json,
        rotation: %{size: 10_000_000, keep: 5} # Rotação de 10MB, manter 5 arquivos
      },
      %{
        name: :datadog,
        adapter: MyApp.DatadogLoggerBackend, # Adaptador customizado
        api_key: {:system, \"DATADOG_API_KEY\"},
        level: :warn
      }
    ]
    ```
*   `[:core, :logger, :sanitizer, :enabled]` (Boolean): Habilita/desabilita a sanitização de logs. (Padrão: `true`)
*   `[:core, :logger, :sanitizer, :sensitive_keys]` (List de Strings/Atoms): Lista de chaves a serem sanitizadas.
*   `[:core, :logger, :context, :auto_include_pid]` (Boolean): Inclui PID automaticamente. (Padrão: `true`)
*   `[:core, :logger, :context, :auto_include_trace_id]` (Boolean): Inclui Trace ID automaticamente. (Padrão: `true`)
*   (Opcional, se `Deeper_Hub.Logger.Config` for usado) `[:logger, :emojis, :info]` (String): Emoji para logs de info.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `Deeper_Hub.Core.ConfigManager`: Para obter configurações de logging.
*   `Deeper_Hub.Shared.Logging.Context`: Para gerenciamento de contexto de log por processo.
*   `Deeper_Hub.Shared.Logging.DistributedTracing`: Para obter Trace IDs.
*   `Deeper_Hub.Security.LogSanitizer` (ou similar): Para sanitizar dados sensíveis.
*   `Deeper_Hub.Core.Supervisor` (indireta): Para supervisionar o `StructuredLogger` GenServer.

### 8.2. Bibliotecas Externas

*   `Logger` (Elixir Standard Library): Usado como base para a funcionalidade de logging.
*   `Jason` (ou similar): Se o formato de log JSON for o padrão.
*   Bibliotecas de clientes para serviços de logging externos (ex: `Dogstatsd` para Datadog), se aplicável.

## 🤝 9. Como Usar / Integração

**Registro Básico:**
```elixir
alias Deeper_Hub.Core.Logger

def my_function(user_id) do
  Logger.info(__MODULE__, \"Iniciando processamento para usuário.\", %{user_id: user_id})
  # ...
  Logger.debug(__MODULE__, \"Dados intermediários.\", %{data: some_data})
  # ...
  {:ok, \"resultado\"}
rescue
  e ->
    Logger.error(__MODULE__, \"Erro durante processamento.\", %{user_id: user_id, error: Exception.message(e), stacktrace: Exception.stacktrace(e)})
    {:error, :processing_failed}
end
```

**Usando Contexto de Log:**
```elixir
alias Deeper_Hub.Core.Logger

def handle_request(conn, params) do
  request_id = conn.private[:request_id] # Exemplo de como obter um request_id
  Logger.set_context(%{request_id: request_id, user_id: conn.assigns.current_user_id})

  process_data(params) # Logger.info dentro de process_data incluirá request_id e user_id

  Logger.clear_context() # Limpar contexto ao final da requisição
  conn
end

defp process_data(params) do
  Logger.info(__MODULE__, \"Processando dados do formulário.\", %{form_params: params})
end
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar se os logs são formatados corretamente para diferentes níveis e com metadados.
*   Verificar se a sanitização de dados sensíveis está funcionando.
*   Testar a configuração e o direcionamento para diferentes backends.
*   Testar a funcionalidade de contexto de log.
*   Localização: `test/deeper_hub/core/logger/` e `test/deeper_hub/shared/logging/`.

### 10.2. Métricas

*   `deeper_hub.core.logger.logs_written.count` (tags: `level`, `backend_name`): Número de logs escritos.
*   `deeper_hub.core.logger.log_processing.duration_ms` (Histograma, tags: `backend_name`): Tempo para processar e enviar um log para um backend.
*   `deeper_hub.core.logger.logs_sanitized.count` (Contador): Número de logs que passaram pela sanitização.
*   `deeper_hub.core.logger.logs_dropped.count` (tags: `reason`, `backend_name`): Número de logs descartados (ex: devido a nível de log do backend).

### 10.3. Logs (do próprio Logger)

O sistema de logging em si também deve gerar logs sobre sua operação, especialmente em níveis mais altos:
*   **Nível INFO:** Inicialização do Logger, configuração de backends, rotação de arquivos de log.
*   **Nível WARNING:** Falha temporária ao escrever em um backend (com retentativa).
*   **Nível ERROR:** Falha persistente ao escrever em um backend, erro de configuração de backend, falha na sanitização.

### 10.4. Telemetria

Eventos Telemetry podem ser emitidos para:
*   `[:deeper_hub, :core, :logger, :log_processed, :start | :stop | :exception]`
    *   Metadados: `%{level: level, backend: backend_name, message_size: size, metadata_keys: keys}`

## ❌ 11. Tratamento de Erros

*   **Falha de Backend:** Se um backend de logging falhar (ex: serviço externo indisponível), o `Logger.Adapter` deve tratar o erro graciosamente, registrar a falha (possivelmente usando outro backend mais confiável como o console) e continuar tentando enviar para outros backends configurados. Não deve travar o processo chamador.
*   **Erro de Formatação/Sanitização:** Erros internos na formatação ou sanitização devem ser capturados, logados (de forma segura) e não devem impedir o fluxo da aplicação.

## 🛡️ 12. Considerações de Segurança

*   **Sanitização é Crucial:** A integração com o `LogSanitizer` é a principal medida de segurança para evitar vazamento de dados sensíveis.
*   **Níveis de Log em Produção:** O nível de log global e dos backends deve ser configurado apropriadamente para produção (geralmente `:info` ou `:warn`) para evitar excesso de logs e exposição de dados de debug.
*   **Acesso aos Logs:** Arquivos de log e plataformas de logging centralizado devem ter controle de acesso rigoroso.
*   **Não Logar Informação Desnecessária:** Evitar logar objetos completos ou estruturas de dados grandes se apenas algumas informações são relevantes.

## 🧑‍💻 13. Contribuição

*   Sempre use a fachada `Deeper_Hub.Core.Logger` para registrar logs.
*   Forneça metadados ricos e estruturados.
*   Use o nível de log apropriado para a mensagem.
*   Tenha cuidado para não logar dados sensíveis diretamente; confie na sanitização, mas seja consciente.
*   Para fluxos complexos, utilize `Logger.set_context/1` para enriquecer todos os logs dentro daquele fluxo com identificadores comuns.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar amostragem de logs de debug/info em produção para reduzir volume, mas ainda capturar informações úteis.
*   [ ] Adicionar a capacidade de alterar níveis de log de backends específicos em tempo de execução via `ConfigManager`.
*   [ ] Desenvolver mais `LogBackends` customizados para integrações populares (ex: ELK Stack, Splunk).
*   [ ] Permitir filtros mais avançados nos backends (ex: logar apenas certos módulos para um backend específico).
*   [ ] Melhorar a performance do processamento assíncrono de logs sob alta carga.

---

*Última atualização: 2025-05-11*

---

Próximo? Talvez `Deeper_Hub.Auth` ou `Deeper_Hub.Core.Metrics`?"""),
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
                types.Part.from_text(text="""Combinado! Vamos agora detalhar o `Deeper_Hub.Core.Metrics`, outro pilar da observabilidade.

---

