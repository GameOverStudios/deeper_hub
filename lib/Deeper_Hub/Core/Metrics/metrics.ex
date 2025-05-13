defmodule Deeper_Hub.Core.Metrics do
  @moduledoc """
  Módulo para coleta e gerenciamento de métricas do sistema.
  
  Este módulo fornece funcionalidades para registrar, coletar e consultar métricas
  de desempenho e uso do sistema, permitindo monitoramento e análise de performance.
  
  ## Características
  
  - Registro de tempo de execução de operações
  - Contagem de operações por tipo
  - Métricas de uso de recursos
  - Suporte para exportação de métricas
  
  ## Uso Básico
  
  ```elixir
  # Registrar uma métrica de tempo
  Metrics.record_execution_time(:database_operation, :insert, 15.5)
  
  # Incrementar um contador
  Metrics.increment_counter(:database_operation, :query_count)
  
  # Obter métricas coletadas
  metrics = Metrics.get_metrics(:database_operation)
  ```
  """
  
  alias Deeper_Hub.Core.Logger
  
  # Tipos de métricas suportadas
  @type metric_category :: atom()
  @type metric_name :: atom()
  @type metric_value :: number()
  @type metric_data :: %{required(metric_name()) => metric_value()}
  @type metrics_collection :: %{required(metric_category()) => metric_data()}
  
  # Estado inicial para métricas
  @metrics_table :metrics_data
  
  @doc """
  Inicializa o sistema de métricas.
  
  Deve ser chamado durante a inicialização da aplicação.
  """
  @spec initialize() :: :ok
  def initialize do
    # Inicializa a tabela ETS para armazenar métricas em memória
    :ets.new(@metrics_table, [:set, :public, :named_table])
    Logger.info("Sistema de métricas inicializado", %{module: __MODULE__})
    :ok
  end
  
  @doc """
  Registra o tempo de execução de uma operação.
  
  ## Parâmetros
  
  - `category`: Categoria da métrica (ex: :database, :http, :cache)
  - `name`: Nome da métrica (ex: :query_time, :request_time)
  - `time_ms`: Tempo de execução em milissegundos
  
  ## Exemplos
  
  ```elixir
  Metrics.record_execution_time(:database, :query_time, 25.3)
  ```
  """
  @spec record_execution_time(metric_category(), metric_name(), float()) :: :ok
  def record_execution_time(category, name, time_ms) when is_atom(category) and is_atom(name) and is_number(time_ms) do
    update_metric(category, name, time_ms, :execution_time)
    :ok
  end
  
  @doc """
  Incrementa um contador de operações.
  
  ## Parâmetros
  
  - `category`: Categoria da métrica (ex: :database, :http, :cache)
  - `name`: Nome da métrica (ex: :query_count, :request_count)
  - `increment`: Valor a incrementar (padrão: 1)
  
  ## Exemplos
  
  ```elixir
  Metrics.increment_counter(:database, :query_count)
  Metrics.increment_counter(:http, :error_count, 5)
  ```
  """
  @spec increment_counter(metric_category(), metric_name(), integer()) :: :ok
  def increment_counter(category, name, increment \\ 1) when is_atom(category) and is_atom(name) and is_integer(increment) do
    # Obtém o valor atual ou 0 se não existir
    current_value = get_metric_value(category, name) || 0
    # Atualiza com o novo valor
    update_metric(category, name, current_value + increment, :counter)
    :ok
  end
  
  @doc """
  Registra um valor de métrica.
  
  ## Parâmetros
  
  - `category`: Categoria da métrica (ex: :database, :memory, :cpu)
  - `name`: Nome da métrica (ex: :memory_usage, :cpu_usage)
  - `value`: Valor da métrica
  
  ## Exemplos
  
  ```elixir
  Metrics.record_value(:system, :memory_usage, 1024)
  ```
  """
  @spec record_value(metric_category(), metric_name(), number()) :: :ok
  def record_value(category, name, value) when is_atom(category) and is_atom(name) and is_number(value) do
    update_metric(category, name, value, :value)
    :ok
  end
  
  @doc """
  Obtém todas as métricas de uma categoria específica.
  
  ## Parâmetros
  
  - `category`: Categoria da métrica (ex: :database, :http, :cache)
  
  ## Retorno
  
  Um mapa com todas as métricas da categoria especificada.
  
  ## Exemplos
  
  ```elixir
  metrics = Metrics.get_metrics(:database)
  # => %{query_time: 25.3, query_count: 10}
  ```
  """
  @spec get_metrics(metric_category()) :: metric_data()
  def get_metrics(category) when is_atom(category) do
    case :ets.lookup(@metrics_table, category) do
      [{^category, metrics}] -> metrics
      [] -> %{}
    end
  end
  
  @doc """
  Obtém o valor de uma métrica específica.
  
  ## Parâmetros
  
  - `category`: Categoria da métrica (ex: :database, :http, :cache)
  - `name`: Nome da métrica (ex: :query_time, :request_count)
  
  ## Retorno
  
  O valor da métrica ou nil se não existir.
  
  ## Exemplos
  
  ```elixir
  value = Metrics.get_metric_value(:database, :query_count)
  # => 10
  ```
  """
  @spec get_metric_value(metric_category(), metric_name()) :: metric_value() | nil
  def get_metric_value(category, name) when is_atom(category) and is_atom(name) do
    case get_metrics(category) do
      metrics when is_map(metrics) -> Map.get(metrics, name)
      _ -> nil
    end
  end
  
  @doc """
  Limpa todas as métricas de uma categoria específica.
  
  ## Parâmetros
  
  - `category`: Categoria da métrica (ex: :database, :http, :cache)
  
  ## Exemplos
  
  ```elixir
  Metrics.clear_metrics(:database)
  ```
  """
  @spec clear_metrics(metric_category()) :: :ok
  def clear_metrics(category) when is_atom(category) do
    :ets.delete(@metrics_table, category)
    :ok
  end
  
  @doc """
  Limpa todas as métricas do sistema.
  
  ## Exemplos
  
  ```elixir
  Metrics.clear_all_metrics()
  ```
  """
  @spec clear_all_metrics() :: :ok
  def clear_all_metrics do
    :ets.delete_all_objects(@metrics_table)
    :ok
  end
  
  @doc """
  Exporta todas as métricas para um formato específico.
  
  ## Parâmetros
  
  - `format`: Formato de exportação (:json, :csv, :prometheus)
  
  ## Retorno
  
  As métricas no formato especificado.
  
  ## Exemplos
  
  ```elixir
  json = Metrics.export_metrics(:json)
  ```
  """
  @spec export_metrics(atom()) :: String.t()
  def export_metrics(format \\ :json) do
    # Coleta todas as métricas
    metrics = collect_all_metrics()
    
    # Exporta no formato especificado
    case format do
      :json -> Jason.encode!(metrics)
      :csv -> export_to_csv(metrics)
      :prometheus -> export_to_prometheus(metrics)
      _ -> Jason.encode!(metrics) # Padrão para JSON
    end
  end
  
  # Funções privadas
  
  defp update_metric(category, name, value, _type) do
    # Obtém as métricas atuais da categoria ou cria um mapa vazio
    current_metrics = get_metrics(category)
    
    # Atualiza o mapa de métricas com o novo valor
    updated_metrics = Map.put(current_metrics, name, value)
    
    # Armazena o mapa atualizado
    :ets.insert(@metrics_table, {category, updated_metrics})
  end
  
  defp collect_all_metrics do
    # Coleta todas as categorias de métricas
    :ets.tab2list(@metrics_table)
    |> Enum.into(%{}, fn {category, metrics} -> {category, metrics} end)
  end
  
  defp export_to_csv(metrics) do
    # Implementação básica de exportação para CSV
    metrics
    |> Enum.map(fn {category, values} ->
      values
      |> Enum.map(fn {name, value} ->
        "#{category},#{name},#{value}"
      end)
    end)
    |> List.flatten()
    |> Enum.join("\n")
  end
  
  defp export_to_prometheus(metrics) do
    # Implementação básica de exportação para formato Prometheus
    metrics
    |> Enum.map(fn {category, values} ->
      values
      |> Enum.map(fn {name, value} ->
        "#{category}_#{name} #{value}"
      end)
    end)
    |> List.flatten()
    |> Enum.join("\n")
  end
end
