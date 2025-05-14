defmodule Deeper_Hub.Core.Metrics.MetricsViewer do
  @moduledoc """
  Módulo para visualização e análise das métricas coletadas.

  Este módulo fornece funções para consultar, filtrar e analisar as métricas
  coletadas pelo sistema, facilitando a identificação de gargalos e problemas
  de desempenho.
  """
  alias Deeper_Hub.Core.Metrics.DatabaseMetrics
  alias Deeper_Hub.Core.Logger

  @doc """
  Gera um resumo das métricas de banco de dados por tabela.

  ## Parâmetros

    - `table`: Nome da tabela (opcional). Se não for fornecido, retorna métricas de todas as tabelas.

  ## Retorno

  Um mapa com as seguintes informações para cada tabela:
    - Total de operações
    - Tempo médio de execução por tipo de operação
    - Taxa de sucesso/erro
    - Tamanho médio dos resultados
  """
  @spec database_summary(atom() | nil) :: map()
  def database_summary(table \\ nil) do
    try do
      # Obtém as métricas de operações de banco de dados
      db_metrics =
        if table do
          %{table => DatabaseMetrics.get_table_metrics(table)}
        else
          # Transforma as métricas de operação em um formato mais amigável
          DatabaseMetrics.get_operation_metrics()
          |> Enum.map(fn {table, _operations} ->
            {table, DatabaseMetrics.get_table_metrics(table)}
          end)
          |> Map.new()
        end

      # Processa as métricas para gerar um resumo
      db_metrics
      |> Enum.map(fn {table, metrics} ->
        {table, process_table_metrics(metrics)}
      end)
      |> Map.new()
    rescue
      e ->
        Logger.error("Falha ao gerar resumo de métricas de banco de dados", %{
          module: __MODULE__,
          error: e,
          stacktrace: __STACKTRACE__
        })

        %{}
    end
  end

  @doc """
  Identifica as operações mais lentas no banco de dados.

  ## Parâmetros

    - `limit`: Número máximo de operações a serem retornadas (padrão: 5)
    - `min_count`: Número mínimo de execuções para considerar uma operação (padrão: 10)

  ## Retorno

  Uma lista de mapas, cada um contendo:
    - Tabela
    - Operação
    - Tempo médio de execução
    - Número de execuções
  """
  @spec slowest_operations(integer(), integer()) :: list(map())
  def slowest_operations(limit \\ 5, min_count \\ 10) do
    try do
      # Obtém as métricas de operações de banco de dados
      db_metrics = DatabaseMetrics.get_operation_metrics()

      # Extrai as operações com seus tempos médios
      operations =
        Enum.flat_map(db_metrics, fn {table, ops} ->
          Enum.map(ops, fn {op, stats} ->
            %{
              table: table,
              operation: op,
              avg_time: stats[:avg_time] || 0,
              count: stats[:count] || 0
            }
          end)
        end)

      # Filtra operações com número mínimo de execuções
      # e ordena pelo tempo médio (do maior para o menor)
      operations
      |> Enum.filter(fn %{count: count} -> count >= min_count end)
      |> Enum.sort_by(fn %{avg_time: avg_time} -> avg_time end, :desc)
      |> Enum.take(limit)
    rescue
      e ->
        Logger.error("Falha ao identificar operações mais lentas", %{
          module: __MODULE__,
          error: e,
          stacktrace: __STACKTRACE__
        })

        []
    end
  end

  @doc """
  Gera um relatório de desempenho para uma tabela específica.

  ## Parâmetros

    - `table`: Nome da tabela

  ## Retorno

  Um mapa com análise detalhada do desempenho da tabela, incluindo:
    - Estatísticas gerais (total de operações, tempo médio, etc.)
    - Análise por tipo de operação
    - Recomendações de otimização (se aplicável)
  """
  @spec table_performance_report(atom()) :: map()
  def table_performance_report(table) do
    try do
      # Obtém as métricas da tabela
      metrics = DatabaseMetrics.get_table_metrics(table)

      # Processa as métricas para gerar um relatório detalhado
      summary = process_table_metrics(metrics)

      # Analisa o desempenho e gera recomendações
      recommendations = generate_recommendations(table, metrics)

      # Combina as informações em um relatório completo
      Map.merge(summary, %{
        table: table,
        detailed_metrics: metrics,
        recommendations: recommendations
      })
    rescue
      e ->
        Logger.error("Falha ao gerar relatório de desempenho para tabela", %{
          module: __MODULE__,
          table: table,
          error: e,
          stacktrace: __STACKTRACE__
        })

        %{
          table: table,
          error: "Falha ao gerar relatório: #{inspect(e)}"
        }
    end
  end

  # Funções privadas

  # Processa as métricas de uma tabela para gerar um resumo
  defp process_table_metrics(metrics) do
    operations = metrics[:operations] || %{}
    result_sizes = metrics[:result_sizes] || %{}

    # Calcula o total de operações
    total_operations =
      operations
      |> Enum.map(fn {_, stats} -> stats[:count] || 0 end)
      |> Enum.sum()

    # Calcula o tempo médio por tipo de operação
    avg_times =
      operations
      |> Enum.map(fn {op, stats} -> {op, stats[:avg_time] || 0} end)
      |> Map.new()

    # Calcula a taxa de sucesso/erro
    success_rate =
      if total_operations > 0 do
        total_success =
          operations
          |> Enum.map(fn {_, stats} -> stats[:success] || 0 end)
          |> Enum.sum()

        total_success / total_operations
      else
        0
      end

    # Calcula o tamanho médio dos resultados
    avg_result_sizes =
      result_sizes
      |> Enum.map(fn {op, stats} -> {op, stats[:avg] || 0} end)
      |> Map.new()

    # Retorna o resumo
    %{
      total_operations: total_operations,
      avg_times: avg_times,
      success_rate: success_rate,
      avg_result_sizes: avg_result_sizes
    }
  end

  # Gera recomendações de otimização com base nas métricas
  defp generate_recommendations(_table, metrics) do
    operations = metrics[:operations] || %{}
    result_sizes = metrics[:result_sizes] || %{}

    recommendations = []

    # Verifica operações lentas
    recommendations =
      Enum.reduce(operations, recommendations, fn {op, stats}, acc ->
        avg_time = stats[:avg_time] || 0
        count = stats[:count] || 0

        cond do
          avg_time > 500 and count > 10 ->
            ["A operação #{op} está muito lenta (#{avg_time}ms em média). Considere otimizar." | acc]

          avg_time > 200 and count > 50 ->
            ["A operação #{op} está moderadamente lenta (#{avg_time}ms em média) e é executada frequentemente. Considere otimizar." | acc]

          true ->
            acc
        end
      end)

    # Verifica resultados grandes
    recommendations =
      Enum.reduce(result_sizes, recommendations, fn {op, stats}, acc ->
        avg_size = stats[:avg] || 0

        if op == :all and avg_size > 1000 do
          ["A operação #{op} retorna muitos registros (#{avg_size} em média). Considere usar paginação." | acc]
        else
          acc
        end
      end)

    # Verifica taxa de erro
    recommendations =
      Enum.reduce(operations, recommendations, fn {op, stats}, acc ->
        count = stats[:count] || 0
        error = stats[:error] || 0

        if count > 0 and error / count > 0.1 do
          ["A operação #{op} tem uma alta taxa de erro (#{error}/#{count}). Verifique o tratamento de erros." | acc]
        else
          acc
        end
      end)

    # Retorna as recomendações
    recommendations
  end
end
