defmodule Deeper_Hub.Core.Metrics.MetricsIntegration do
  @moduledoc """
  Módulo responsável pela integração do sistema de métricas com o restante da aplicação.
  
  Este módulo fornece funções para inicializar o sistema de métricas e exportar
  relatórios periódicos de desempenho.
  """
  
  alias Deeper_Hub.Core.Metrics
  alias Deeper_Hub.Core.Metrics.DatabaseMetrics
  alias Deeper_Hub.Core.Logger
  
  @doc """
  Inicializa o sistema de métricas e configura a exportação periódica de relatórios.
  
  ## Parâmetros
  
    - `export_interval`: Intervalo em milissegundos para exportação de relatórios (padrão: 3600000 - 1 hora)
    - `export_format`: Formato de exportação dos relatórios (padrão: :json)
    - `export_path`: Caminho para salvar os relatórios exportados (padrão: "logs/metrics")
  
  ## Retorno
  
    - `:ok` se a inicialização for bem-sucedida
    - `{:error, reason}` em caso de falha
  """
  @spec initialize(integer(), atom(), String.t()) :: :ok | {:error, term()}
  def initialize(export_interval \\ 3_600_000, export_format \\ :json, export_path \\ "logs/metrics") do
    try do
      # Inicializa o sistema de métricas
      :ok = Metrics.initialize()
      
      # Configura a exportação periódica de relatórios
      if export_interval > 0 do
        schedule_metrics_export(export_interval, export_format, export_path)
      end
      
      Logger.info("Sistema de métricas inicializado com sucesso", %{
        module: __MODULE__,
        export_interval: export_interval,
        export_format: export_format,
        export_path: export_path
      })
      
      :ok
    rescue
      e ->
        Logger.error("Falha ao inicializar o sistema de métricas", %{
          module: __MODULE__,
          error: e,
          stacktrace: __STACKTRACE__
        })
        
        {:error, e}
    end
  end
  
  @doc """
  Gera um relatório completo de métricas do sistema.
  
  ## Parâmetros
  
    - `format`: Formato do relatório (:map, :json, :csv, :prometheus)
  
  ## Retorno
  
    - O relatório no formato especificado
  """
  @spec generate_report(atom()) :: map() | String.t()
  def generate_report(format \\ :map) do
    # Obtém métricas gerais
    general_metrics = Metrics.get_all_metrics()
    
    # Obtém métricas de banco de dados
    db_metrics = DatabaseMetrics.get_operation_metrics()
    
    # Combina as métricas em um relatório completo
    report = %{
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      general: general_metrics,
      database: db_metrics
    }
    
    # Exporta o relatório no formato solicitado
    case format do
      :map -> report
      :json -> Jason.encode!(report)
      :csv -> export_to_csv(report)
      :prometheus -> export_to_prometheus(report)
      _ -> report
    end
  end
  
  @doc """
  Salva um relatório de métricas em um arquivo.
  
  ## Parâmetros
  
    - `report`: O relatório a ser salvo
    - `format`: Formato do relatório (:json, :csv, :prometheus)
    - `path`: Diretório para salvar o relatório
  
  ## Retorno
  
    - `{:ok, filename}` se o salvamento for bem-sucedido
    - `{:error, reason}` em caso de falha
  """
  @spec save_report(map() | String.t(), atom(), String.t()) :: {:ok, String.t()} | {:error, term()}
  def save_report(report, format, path) do
    try do
      # Cria o diretório se não existir
      File.mkdir_p!(path)
      
      # Gera um nome de arquivo baseado na data e hora atual
      timestamp = DateTime.utc_now() |> DateTime.to_string() |> String.replace(~r/[:\s]/, "-")
      filename = "#{path}/metrics_#{timestamp}.#{format}"
      
      # Converte o relatório para o formato especificado se for um mapa
      content = if is_map(report), do: generate_report(format), else: report
      
      # Salva o relatório no arquivo
      File.write!(filename, content)
      
      Logger.info("Relatório de métricas salvo com sucesso", %{
        module: __MODULE__,
        filename: filename,
        format: format
      })
      
      {:ok, filename}
    rescue
      e ->
        Logger.error("Falha ao salvar relatório de métricas", %{
          module: __MODULE__,
          error: e,
          stacktrace: __STACKTRACE__
        })
        
        {:error, e}
    end
  end
  
  # Funções privadas
  
  # Agenda a exportação periódica de relatórios de métricas
  defp schedule_metrics_export(interval, format, path) do
    # Inicia um processo para exportar métricas periodicamente
    spawn(fn -> metrics_export_loop(interval, format, path) end)
  end
  
  # Loop de exportação de métricas
  defp metrics_export_loop(interval, format, path) do
    # Gera e salva o relatório
    report = generate_report(format)
    save_report(report, format, path)
    
    # Aguarda o intervalo especificado
    :timer.sleep(interval)
    
    # Continua o loop
    metrics_export_loop(interval, format, path)
  end
  
  # Exporta o relatório para formato CSV
  defp export_to_csv(report) do
    # Implementação simplificada para converter o relatório para CSV
    # Em uma implementação real, seria necessário um algoritmo mais robusto
    headers = ["category", "metric", "value"]
    
    rows =
      Enum.flat_map(report.general, fn {category, metrics} ->
        Enum.map(metrics, fn {metric, value} ->
          [to_string(category), to_string(metric), inspect(value)]
        end)
      end) ++
      Enum.flat_map(report.database, fn {table, operations} ->
        Enum.map(operations, fn {operation, stats} ->
          [to_string(table), to_string(operation), inspect(stats)]
        end)
      end)
    
    ([headers] ++ rows)
    |> Enum.map(&Enum.join(&1, ","))
    |> Enum.join("\n")
  end
  
  # Exporta o relatório para formato Prometheus
  defp export_to_prometheus(report) do
    # Implementação simplificada para converter o relatório para formato Prometheus
    # Em uma implementação real, seria necessário seguir o formato exato do Prometheus
    Enum.flat_map(report.general, fn {category, metrics} ->
      Enum.map(metrics, fn {metric, value} ->
        metric_name = "deeper_hub_#{category}_#{metric}"
        value_str = if is_map(value), do: to_string(value[:total]), else: to_string(value)
        "# HELP #{metric_name} Metric for #{category}.#{metric}\n" <>
        "# TYPE #{metric_name} gauge\n" <>
        "#{metric_name} #{value_str}"
      end)
    end) ++
    Enum.flat_map(report.database, fn {table, operations} ->
      Enum.flat_map(operations, fn {operation, stats} ->
        Enum.map(stats, fn {stat, value} ->
          metric_name = "deeper_hub_db_#{table}_#{operation}_#{stat}"
          "# HELP #{metric_name} Database metric for #{table}.#{operation}.#{stat}\n" <>
          "# TYPE #{metric_name} gauge\n" <>
          "#{metric_name} #{value}"
        end)
      end)
    end)
    |> Enum.join("\n")
  end
end
