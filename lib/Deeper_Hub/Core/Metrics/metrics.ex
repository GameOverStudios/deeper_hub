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
    # Inicializa a tabela ETS para armazenar métricas em memória, se ainda não existir
    if not table_exists?(@metrics_table) do
      :ets.new(@metrics_table, [:set, :public, :named_table])
      Logger.info("Sistema de métricas inicializado", %{module: __MODULE__})
    end
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
    # Obtém a métrica atual ou um mapa vazio se não existir
    current_metric = get_metric_value(category, name)
    # Calcula o novo valor do contador
    new_count = (current_metric[:count] || 0) + increment
    # Atualiza a métrica
    update_metric(category, name, new_count, :counter)
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
  
  - `category`: Categoria das métricas a serem obtidas
  
  ## Retorno
  
  Um mapa contendo todas as métricas da categoria especificada.
  
  ## Exemplos
  
  ```elixir
  metrics = Metrics.get_metrics(:database)
  ```
  """
  @spec get_metrics(atom()) :: map()
  def get_metrics(category) when is_atom(category) do
    ensure_metrics_table_exists()
    
    case :ets.lookup(@metrics_table, category) do
      [{^category, metrics}] -> metrics
      [] -> %{}
    end
  end
  
  @doc """
  Obtém todas as métricas de todas as categorias.
  
  ## Retorno
  
  Um mapa contendo todas as métricas do sistema, organizadas por categoria.
  
  ## Exemplos
  
  ```elixir
  all_metrics = Metrics.get_all_metrics()
  ```
  """
  @spec get_all_metrics() :: map()
  def get_all_metrics do
    ensure_metrics_table_exists()
    
    # Obtém todas as categorias de métricas
    categories = :ets.tab2list(@metrics_table)
    
    # Converte a lista de tuplas em um mapa e transforma os valores para o formato esperado pelos testes
    categories
    |> Enum.map(fn {category, metrics} -> 
      # Transforma as métricas desta categoria
      transformed_metrics = transform_metrics_for_report(metrics)
      {category, transformed_metrics}
    end)
    |> Enum.into(%{})
  end
  
  # Função auxiliar para transformar as métricas no formato esperado pelos testes
  defp transform_metrics_for_report(metrics) do
    Enum.map(metrics, fn {key, value} ->
      # Verifica o tipo de métrica e transforma de acordo
      transformed_value = cond do
        # Para contadores, retorna apenas o valor do contador
        is_map(value) && Map.has_key?(value, :count) && !Map.has_key?(value, :last_value) ->
          value[:count]
          
        # Para valores, mantém o mapa completo
        true ->
          value
      end
      
      {key, transformed_value}
    end)
    |> Enum.into(%{})
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
  @spec get_metric_value(metric_category(), metric_name()) :: map() | nil
  def get_metric_value(category, name) when is_atom(category) and is_atom(name) do
    case get_metrics(category) do
      metrics when is_map(metrics) -> 
        # Retorna o mapa completo da métrica ou cria um novo se não existir
        Map.get(metrics, name, %{count: 0, total: 0})
      _ -> %{count: 0, total: 0}
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
    # Certifica-se de que a tabela existe antes de tentar limpar
    ensure_metrics_table_exists()
    try do
      :ets.delete(@metrics_table, category)
    rescue
      _ -> :ok  # Ignora erros ao tentar limpar a categoria
    end
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
    # Certifica-se de que a tabela existe antes de tentar limpar
    ensure_metrics_table_exists()
    try do
      :ets.delete_all_objects(@metrics_table)
    rescue
      _ -> :ok  # Ignora erros ao tentar limpar a tabela
    end
    :ok
  end
  
  @doc """
  Limpa todas as métricas do sistema.
  
  Aliás para clear_all_metrics/0, fornecido para compatibilidade com os testes.
  
  ## Exemplos
  
  ```elixir
  Metrics.clear_metrics()
  ```
  """
  @spec clear_metrics() :: :ok
  def clear_metrics do
    # Certifica-se de que a tabela existe antes de tentar limpar
    ensure_metrics_table_exists()
    clear_all_metrics()
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
  
  defp update_metric(category, name, value, type) do
    # Obtém as métricas atuais da categoria ou cria um mapa vazio
    current_metrics = get_metrics(category)
    
    # Obtém a métrica atual ou cria uma nova
    current_metric = Map.get(current_metrics, name, %{count: 0, total: 0, min: nil, max: nil})
    
    # Atualiza a métrica com base no tipo
    updated_metric = case type do
      :execution_time ->
        %{
          count: current_metric[:count] + 1,
          total: current_metric[:total] + value,
          min: min(current_metric[:min] || value, value),
          max: max(current_metric[:max] || value, value),
          avg: (current_metric[:total] + value) / (current_metric[:count] + 1)
        }
      
      :counter ->
        %{
          count: value,
          total: value
        }
      
      :value ->
        %{
          count: current_metric[:count] + 1,
          total: current_metric[:total] + value,
          last_value: value,
          avg: (current_metric[:total] + value) / (current_metric[:count] + 1)
        }
      
      _ ->
        %{
          count: current_metric[:count] + 1,
          total: value
        }
    end
    
    # Atualiza o mapa de métricas com o novo valor
    updated_metrics = Map.put(current_metrics, name, updated_metric)
    
    # Armazena o mapa atualizado
    :ets.insert(@metrics_table, {category, updated_metrics})
  end
  
  defp collect_all_metrics do
    # Certifica-se de que a tabela existe antes de tentar coletar
    ensure_metrics_table_exists()
    # Coleta todas as categorias de métricas
    :ets.tab2list(@metrics_table)
    |> Enum.into(%{}, fn {category, metrics} -> {category, metrics} end)
  end
  
  # Verifica se uma tabela ETS existe
  defp table_exists?(table_name) do
    case :ets.info(table_name) do
      :undefined -> false
      _ -> true
    end
  end

  # Garante que a tabela de métricas existe
  defp ensure_metrics_table_exists do
    try do
      if :ets.info(@metrics_table) == :undefined do
        # Se a tabela não existir, cria uma nova
        :ets.new(@metrics_table, [:set, :public, :named_table])
        Logger.info("Tabela de métricas inicializada", %{module: __MODULE__})
      end
      :ok
    rescue
      _ ->
        # Se houver qualquer erro, tenta criar a tabela novamente
        try do
          :ets.new(@metrics_table, [:set, :public, :named_table])
          Logger.info("Tabela de métricas inicializada após erro", %{module: __MODULE__})
        rescue
          _ -> :ok  # Ignora se a tabela já existir ou outro erro ocorrer
        end
    end
  end
  
  defp export_to_csv(metrics) do
    # Implementação básica de exportação para CSV
    header = "categoria,metrica,contagem,total,media"
    rows = metrics
    |> Enum.map(fn {category, values} ->
      values
      |> Enum.map(fn {name, metric_data} ->
        count = metric_data[:count] || 0
        total = metric_data[:total] || 0
        avg = metric_data[:avg] || (if count > 0, do: total / count, else: 0)
        "#{category},#{name},#{count},#{total},#{avg}"
      end)
    end)
    |> List.flatten()
    
    [header | rows] |> Enum.join("\n")
  end
  
  defp export_to_prometheus(metrics) do
    # Implementação básica de exportação para formato Prometheus
    metrics
    |> Enum.map(fn {category, values} ->
      values
      |> Enum.map(fn {name, metric_data} ->
        count = metric_data[:count] || 0
        total = metric_data[:total] || 0
        avg = metric_data[:avg] || (if count > 0, do: total / count, else: 0)
        [
          "# TYPE #{category}_#{name}_count counter",
          "#{category}_#{name}_count #{count}",
          "# TYPE #{category}_#{name}_total counter",
          "#{category}_#{name}_total #{total}",
          "# TYPE #{category}_#{name}_avg gauge",
          "#{category}_#{name}_avg #{avg}"
        ]
      end)
    end)
    |> List.flatten()
    |> Enum.join("\n")
  end
end
