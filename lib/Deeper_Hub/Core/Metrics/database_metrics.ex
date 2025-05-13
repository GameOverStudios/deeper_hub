defmodule Deeper_Hub.Core.Metrics.DatabaseMetrics do
  @moduledoc """
  Módulo específico para métricas relacionadas a operações de banco de dados.
  
  Este módulo fornece funções para registrar e analisar métricas específicas
  de operações de banco de dados, como inserções, consultas, atualizações e exclusões.
  
  ## Características
  
  - Registro de tempo de execução de operações CRUD
  - Contagem de operações por tipo e tabela
  - Métricas de sucesso e falha
  - Análise de desempenho de consultas
  
  ## Uso Interno
  
  Este módulo é principalmente utilizado internamente pelos módulos de acesso a dados,
  como o `Repository` e o `Pagination`.
  """
  
  alias Deeper_Hub.Core.Metrics
  
  @doc """
  Registra o início de uma operação de banco de dados.
  
  Retorna um timestamp que deve ser passado para `complete_operation/4`
  quando a operação for concluída.
  
  ## Parâmetros
  
  - `table`: Nome da tabela (átomo)
  - `operation`: Tipo de operação (:insert, :find, :update, :delete, :all, :match)
  
  ## Retorno
  
  Um timestamp representando o momento de início da operação.
  
  ## Exemplos
  
  ```elixir
  timestamp = DatabaseMetrics.start_operation(:users, :insert)
  # ... executa a operação ...
  DatabaseMetrics.complete_operation(:users, :insert, :success, timestamp)
  ```
  """
  @spec start_operation(atom(), atom()) :: integer()
  def start_operation(table, operation) when is_atom(table) and is_atom(operation) do
    # Incrementa o contador de operações iniciadas
    Metrics.increment_counter(:database, :"#{table}_#{operation}_started")
    Metrics.increment_counter(:database, :total_operations_started)
    
    # Retorna o timestamp atual em milissegundos
    System.monotonic_time(:millisecond)
  end
  
  @doc """
  Registra a conclusão de uma operação de banco de dados.
  
  ## Parâmetros
  
  - `table`: Nome da tabela (átomo)
  - `operation`: Tipo de operação (:insert, :find, :update, :delete, :all, :match)
  - `result`: Resultado da operação (:success, :error)
  - `start_time`: Timestamp retornado por `start_operation/2`
  
  ## Exemplos
  
  ```elixir
  timestamp = DatabaseMetrics.start_operation(:users, :insert)
  # ... executa a operação ...
  DatabaseMetrics.complete_operation(:users, :insert, :success, timestamp)
  ```
  """
  @spec complete_operation(atom(), atom(), atom(), integer()) :: :ok
  def complete_operation(table, operation, result, start_time) 
      when is_atom(table) and is_atom(operation) and is_atom(result) and is_integer(start_time) do
    # Calcula o tempo de execução
    end_time = System.monotonic_time(:millisecond)
    execution_time = end_time - start_time
    
    # Registra o tempo de execução
    Metrics.record_execution_time(:database, :"#{table}_#{operation}_time", execution_time)
    
    # Incrementa o contador de operações concluídas
    Metrics.increment_counter(:database, :"#{table}_#{operation}_#{result}")
    Metrics.increment_counter(:database, :"total_operations_#{result}")
    
    # Registra o tempo médio (aproximado)
    update_average_time(table, operation, execution_time)
    
    :ok
  end
  
  @doc """
  Registra uma métrica de tamanho de resultado.
  
  ## Parâmetros
  
  - `table`: Nome da tabela (átomo)
  - `operation`: Tipo de operação (:all, :match, :paginate)
  - `count`: Número de registros retornados
  
  ## Exemplos
  
  ```elixir
  DatabaseMetrics.record_result_size(:users, :all, 42)
  ```
  """
  @spec record_result_size(atom(), atom(), non_neg_integer()) :: :ok
  def record_result_size(table, operation, count) 
      when is_atom(table) and is_atom(operation) and is_integer(count) and count >= 0 do
    # Registra o tamanho do resultado
    Metrics.record_value(:database, :"#{table}_#{operation}_result_size", count)
    
    # Atualiza o tamanho máximo de resultado
    update_max_result_size(table, operation, count)
    
    :ok
  end
  
  @doc """
  Obtém um relatório de métricas de banco de dados para uma tabela específica.
  
  ## Parâmetros
  
  - `table`: Nome da tabela (átomo)
  
  ## Retorno
  
  Um mapa contendo métricas agregadas para a tabela especificada.
  
  ## Exemplos
  
  ```elixir
  report = DatabaseMetrics.get_table_report(:users)
  ```
  """
  @spec get_table_report(atom()) :: map()
  def get_table_report(table) when is_atom(table) do
    metrics = Metrics.get_metrics(:database)
    
    # Filtra e agrupa métricas relacionadas à tabela especificada
    table_prefix = "#{table}_"
    
    metrics
    |> Enum.filter(fn {key, _value} -> 
      key_str = Atom.to_string(key)
      String.starts_with?(key_str, table_prefix)
    end)
    |> Enum.into(%{})
  end
  
  @doc """
  Obtém um relatório geral de métricas de banco de dados.
  
  ## Retorno
  
  Um mapa contendo métricas agregadas para todas as operações de banco de dados.
  
  ## Exemplos
  
  ```elixir
  report = DatabaseMetrics.get_general_report()
  ```
  """
  @spec get_general_report() :: map()
  def get_general_report do
    Metrics.get_metrics(:database)
  end
  
  # Funções privadas
  
  defp update_average_time(table, operation, execution_time) do
    # Obtém o tempo médio atual e o número de operações
    avg_key = :"#{table}_#{operation}_avg_time"
    count_key = :"#{table}_#{operation}_count"
    
    current_avg = Metrics.get_metric_value(:database, avg_key) || 0
    current_count = Metrics.get_metric_value(:database, count_key) || 0
    
    # Calcula o novo tempo médio
    new_count = current_count + 1
    new_avg = ((current_avg * current_count) + execution_time) / new_count
    
    # Atualiza as métricas
    Metrics.record_value(:database, avg_key, new_avg)
    Metrics.record_value(:database, count_key, new_count)
  end
  
  defp update_max_result_size(table, operation, count) do
    max_key = :"#{table}_#{operation}_max_result_size"
    current_max = Metrics.get_metric_value(:database, max_key) || 0
    
    if count > current_max do
      Metrics.record_value(:database, max_key, count)
    end
  end
end
