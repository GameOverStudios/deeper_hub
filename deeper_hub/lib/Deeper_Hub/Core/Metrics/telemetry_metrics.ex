defmodule Deeper_Hub.Core.Metrics.TelemetryMetrics do
  @moduledoc """
  Define as métricas de telemetria para o sistema Deeper_Hub.

  Este módulo centraliza a definição de todas as métricas que serão coletadas
  pelo sistema de telemetria, utilizando a biblioteca `Telemetry.Metrics`.

  ## Funcionalidades

  * 📊 Definição de métricas para monitoramento do sistema
  * 🔄 Configuração de métricas periódicas (VM, processos, etc)
  * 📈 Suporte a diferentes tipos de métricas (contador, resumo, último valor, etc)
  * 🏷️ Agrupamento de métricas por tags para análise detalhada

  ## Tipos de Métricas

  * **Counter**: Conta o número total de eventos emitidos
  * **Sum**: Mantém a soma de uma medição selecionada
  * **LastValue**: Mantém o valor mais recente de uma medição
  * **Summary**: Calcula estatísticas como máximo, média, percentis, etc
  * **Distribution**: Constrói um histograma de uma medição selecionada

  ## Exemplo de Uso

  ```elixir
  # Iniciar o supervisor de métricas
  Deeper_Hub.Core.Metrics.Supervisor.start_link([])

  # As métricas serão automaticamente coletadas e reportadas
  # conforme a configuração do reporter
  ```
  """

  import Telemetry.Metrics

  @doc """
  Retorna a lista de métricas configuradas para o sistema.

  ## Retorno

  * Lista de métricas configuradas

  ## Exemplo

  ```elixir
  Deeper_Hub.Core.Metrics.TelemetryMetrics.metrics()
  ```
  """
  def metrics do
    [
      # Métricas da VM
      vm_metrics(),

      # Métricas de banco de dados
      database_metrics(),

      # Métricas de API
      api_metrics(),

      # Métricas de cache
      cache_metrics(),

      # Métricas de EventBus
      event_bus_metrics()
    ]
    |> List.flatten()
  end

  @doc """
  Retorna as medições periódicas que serão coletadas pelo sistema.

  ## Retorno

  * Lista de configurações de medições periódicas

  ## Exemplo

  ```elixir
  Deeper_Hub.Core.Metrics.TelemetryMetrics.periodic_measurements()
  ```
  """
  def periodic_measurements do
    [
      # Informações de processo para o sistema
      {:process_info,
       event: [:deeper_hub, :system],
       name: Deeper_Hub.Application,
       keys: [:message_queue_len, :memory, :reductions]},

      # Métricas de VM padrão
      {:vm, [:memory, :total]},
      {:vm, [:total_run_queue_lengths]}
    ]
  end

  # Métricas relacionadas à máquina virtual Erlang
  defp vm_metrics do
    [
      # Memória total utilizada
      last_value("vm.memory.total", unit: :byte,
        description: "Memória total utilizada pela VM"),

      # Comprimento total das filas de execução
      last_value("vm.total_run_queue_lengths.total",
        description: "Comprimento total das filas de execução"),

      # Comprimento das filas de execução da CPU
      last_value("vm.total_run_queue_lengths.cpu",
        description: "Comprimento das filas de execução da CPU"),

      # Comprimento das filas de execução de IO
      last_value("vm.total_run_queue_lengths.io",
        description: "Comprimento das filas de execução de IO")
    ]
  end

  # Métricas relacionadas ao banco de dados
  defp database_metrics do
    [
      # Tempo total de consulta
      summary("deeper_hub.repo.query.total_time",
        unit: {:native, :millisecond},
        description: "Tempo total gasto em consultas ao banco de dados"),

      # Tempo de decodificação
      summary("deeper_hub.repo.query.decode_time",
        unit: {:native, :millisecond},
        description: "Tempo gasto decodificando resultados de consultas"),

      # Tempo de consulta
      summary("deeper_hub.repo.query.query_time",
        unit: {:native, :millisecond},
        description: "Tempo gasto executando consultas no banco de dados"),

      # Tempo ocioso
      summary("deeper_hub.repo.query.idle_time",
        unit: {:native, :millisecond},
        description: "Tempo ocioso durante consultas ao banco de dados"),

      # Tempo na fila
      summary("deeper_hub.repo.query.queue_time",
        unit: {:native, :millisecond},
        description: "Tempo na fila antes da execução de consultas")
    ]
  end

  # Métricas relacionadas à API
  defp api_metrics do
    [
      # Duração das requisições
      summary("deeper_hub.api.request.duration",
        unit: {:native, :millisecond},
        tags: [:endpoint, :method],
        description: "Duração das requisições à API"),

      # Contador de requisições
      counter("deeper_hub.api.request.count",
        tags: [:endpoint, :method, :status],
        description: "Número total de requisições à API"),

      # Tamanho das respostas
      distribution("deeper_hub.api.response.size",
        unit: :byte,
        tags: [:endpoint],
        description: "Tamanho das respostas da API")
    ]
  end

  # Métricas relacionadas ao cache
  defp cache_metrics do
    [
      # Hits no cache
      counter("deeper_hub.cache.hit",
        tags: [:cache_name],
        description: "Número de hits no cache"),

      # Misses no cache
      counter("deeper_hub.cache.miss",
        tags: [:cache_name],
        description: "Número de misses no cache"),

      # Tamanho do cache
      last_value("deeper_hub.cache.size",
        tags: [:cache_name],
        description: "Número de itens no cache"),

      # Tempo de operações de cache
      summary("deeper_hub.cache.operation.duration",
        unit: {:native, :millisecond},
        tags: [:cache_name, :operation],
        description: "Duração das operações de cache")
    ]
  end

  # Métricas relacionadas ao EventBus
  defp event_bus_metrics do
    [
      # Contador de eventos publicados
      counter("deeper_hub.event_bus.publish",
        tags: [:topic],
        description: "Número de eventos publicados no barramento"),

      # Contador de eventos processados
      counter("deeper_hub.event_bus.process",
        tags: [:topic, :subscriber],
        description: "Número de eventos processados pelos assinantes"),

      # Tempo de processamento de eventos
      summary("deeper_hub.event_bus.process.duration",
        unit: {:native, :millisecond},
        tags: [:topic, :subscriber],
        description: "Tempo de processamento de eventos pelos assinantes"),

      # Contador de falhas no processamento
      counter("deeper_hub.event_bus.process.error",
        tags: [:topic, :subscriber, :reason],
        description: "Número de falhas no processamento de eventos")
    ]
  end
end
