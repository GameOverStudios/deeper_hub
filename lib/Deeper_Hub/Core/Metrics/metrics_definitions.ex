defmodule Deeper_Hub.Core.Metrics.MetricsDefinitions do
  @moduledoc """
  Define métricas para o Deeper_Hub.
  Este módulo contém definições de métricas que podem ser utilizadas com o Telemetry.Metrics.
  """

  alias Telemetry.Metrics

  @doc """
  Retorna uma lista de métricas para monitoramento do banco de dados.
  """
  def database_metrics do
    [
      # Métricas de consulta
      Metrics.distribution(
        [:deeper_hub, :database, :query, :duration],
        unit: {:native, :millisecond},
        description: "Duração das consultas de banco de dados",
        tags: [:operation, :table]
      ),
      Metrics.counter(
        [:deeper_hub, :database, :query, :count],
        description: "Número total de consultas realizadas",
        tags: [:operation, :table]
      ),
      Metrics.sum(
        [:deeper_hub, :database, :query, :rows],
        description: "Número de linhas processadas em consultas",
        tags: [:operation, :table]
      ),

      # Métricas de transação
      Metrics.counter(
        [:deeper_hub, :database, :transaction, :count],
        description: "Número total de transações realizadas",
        tags: [:status]
      ),
      Metrics.distribution(
        [:deeper_hub, :database, :transaction, :duration],
        unit: {:native, :millisecond},
        description: "Duração das transações de banco de dados",
        tags: [:status]
      ),

      # Métricas de conexão
      Metrics.last_value(
        [:deeper_hub, :database, :connection, :count],
        description: "Número atual de conexões com o banco de dados",
        tags: [:status]
      )
    ]
  end

  @doc """
  Retorna uma lista de métricas para monitoramento do repositório.
  """
  def repository_metrics do
    [
      Metrics.counter(
        [:deeper_hub, :repository, :operation, :count],
        description: "Número total de operações de repositório realizadas",
        tags: [:operation, :entity]
      ),
      Metrics.distribution(
        [:deeper_hub, :repository, :operation, :duration],
        unit: {:native, :millisecond},
        description: "Duração das operações de repositório",
        tags: [:operation, :entity]
      )
    ]
  end

  @doc """
  Retorna uma lista de métricas para monitoramento de cache.
  """
  def cache_metrics do
    [
      Metrics.counter(
        [:deeper_hub, :cache, :hit, :count],
        description: "Número de cache hits",
        tags: [:key]
      ),
      Metrics.counter(
        [:deeper_hub, :cache, :miss, :count],
        description: "Número de cache misses",
        tags: [:key]
      ),
      Metrics.counter(
        [:deeper_hub, :cache, :update, :count],
        description: "Número de atualizações de cache",
        tags: [:key]
      )
    ]
  end

  @doc """
  Retorna todas as métricas definidas.
  """
  def metrics do
    database_metrics() ++ repository_metrics() ++ cache_metrics()
  end
end
