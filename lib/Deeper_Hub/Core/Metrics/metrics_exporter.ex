defmodule Deeper_Hub.Core.Metrics.MetricsExporter do
  @moduledoc """
  Módulo para exportação de métricas para diferentes formatos e sistemas externos.
  
  Este módulo fornece funcionalidades para exportar as métricas coletadas pelo sistema
  para diversos formatos (JSON, CSV, Prometheus) e para sistemas externos de monitoramento.
  """
  
  alias Deeper_Hub.Core.Metrics
  alias Deeper_Hub.Core.Metrics.DatabaseMetrics
  alias Deeper_Hub.Core.Logger
  
  @doc """
  Exporta todas as métricas do sistema para o formato especificado.
  
  ## Parâmetros
  
    - `format`: Formato de exportação (:json, :csv, :prometheus)
  
  ## Retorno
  
    - Uma string contendo as métricas no formato especificado
  """
  @spec export_all_metrics(atom()) :: String.t()
  def export_all_metrics(format \\ :json) do
    try do
      # Obtém todas as métricas
      general_metrics = Metrics.get_all_metrics()
      db_metrics = DatabaseMetrics.get_operation_metrics()
      
      # Combina as métricas em um único mapa
      all_metrics = %{
        timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
        general: general_metrics,
        database: db_metrics
      }
      
      # Exporta para o formato solicitado
      case format do
        :json -> export_to_json(all_metrics)
        :csv -> export_to_csv(all_metrics)
        :prometheus -> export_to_prometheus(all_metrics)
        _ -> export_to_json(all_metrics)
      end
    rescue
      e ->
        Logger.error("Falha ao exportar métricas", %{
          module: __MODULE__,
          format: format,
          error: e,
          stacktrace: __STACKTRACE__
        })
        
        "Error: #{inspect(e)}"
    end
  end
  
  @doc """
  Exporta métricas de banco de dados para o formato especificado.
  
  ## Parâmetros
  
    - `table`: Nome da tabela (opcional). Se não for fornecido, exporta métricas de todas as tabelas.
    - `format`: Formato de exportação (:json, :csv, :prometheus)
  
  ## Retorno
  
    - Uma string contendo as métricas no formato especificado
  """
  @spec export_database_metrics(atom() | nil, atom()) :: String.t()
  def export_database_metrics(table \\ nil, format \\ :json) do
    try do
      # Obtém as métricas de banco de dados
      db_metrics = 
        if table do
          %{table => DatabaseMetrics.get_table_metrics(table)}
        else
          DatabaseMetrics.get_operation_metrics()
        end
      
      # Adiciona timestamp
      metrics_with_timestamp = %{
        timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
        database: db_metrics
      }
      
      # Exporta para o formato solicitado
      case format do
        :json -> export_to_json(metrics_with_timestamp)
        :csv -> export_to_csv(metrics_with_timestamp)
        :prometheus -> export_to_prometheus(metrics_with_timestamp)
        _ -> export_to_json(metrics_with_timestamp)
      end
    rescue
      e ->
        Logger.error("Falha ao exportar métricas de banco de dados", %{
          module: __MODULE__,
          table: table,
          format: format,
          error: e,
          stacktrace: __STACKTRACE__
        })
        
        "Error: #{inspect(e)}"
    end
  end
  
  @doc """
  Salva as métricas exportadas em um arquivo.
  
  ## Parâmetros
  
    - `content`: Conteúdo a ser salvo
    - `format`: Formato do conteúdo (:json, :csv, :prometheus)
    - `path`: Diretório onde o arquivo será salvo
    - `filename`: Nome do arquivo (opcional). Se não for fornecido, um nome será gerado automaticamente.
  
  ## Retorno
  
    - `{:ok, filepath}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  @spec save_to_file(String.t(), atom(), String.t(), String.t() | nil) :: {:ok, String.t()} | {:error, term()}
  def save_to_file(content, format, path, filename \\ nil) do
    try do
      # Cria o diretório se não existir
      File.mkdir_p!(path)
      
      # Gera um nome de arquivo se não for fornecido
      actual_filename = 
        if filename do
          filename
        else
          timestamp = DateTime.utc_now() |> DateTime.to_string() |> String.replace(~r/[:\s]/, "-")
          "metrics_#{timestamp}.#{format}"
        end
      
      # Caminho completo do arquivo
      filepath = Path.join(path, actual_filename)
      
      # Salva o conteúdo no arquivo
      File.write!(filepath, content)
      
      Logger.info("Métricas exportadas salvas com sucesso", %{
        module: __MODULE__,
        filepath: filepath,
        format: format
      })
      
      {:ok, filepath}
    rescue
      e ->
        Logger.error("Falha ao salvar métricas exportadas", %{
          module: __MODULE__,
          path: path,
          filename: filename,
          format: format,
          error: e,
          stacktrace: __STACKTRACE__
        })
        
        {:error, e}
    end
  end
  
  # Funções privadas
  
  # Exporta métricas para formato JSON
  defp export_to_json(metrics) do
    Jason.encode!(metrics, pretty: true)
  end
  
  # Exporta métricas para formato CSV
  defp export_to_csv(metrics) do
    # Função para extrair métricas em formato plano
    extract_metrics = fn ->
      f = fn f, map, prefix ->
        Enum.flat_map(map, fn {key, value} ->
          new_prefix = if prefix == "", do: to_string(key), else: "#{prefix}.#{key}"
          
          cond do
            is_map(value) and not Map.has_key?(value, :count) ->
              f.(f, value, new_prefix)
            
            is_map(value) ->
              # Métricas com estatísticas (count, total, avg)
              Enum.map(value, fn {stat_key, stat_value} ->
                {
                  "#{new_prefix}.#{stat_key}",
                  (if is_float(stat_value), do: Float.round(stat_value, 4), else: stat_value)
                }
              end)
            
            true ->
              # Valores simples
              [{new_prefix, value}]
          end
        end)
      end
      f
    end.()
    
    # Extrai métricas gerais
    general_metrics = 
      if Map.has_key?(metrics, :general) do
        extract_metrics.(extract_metrics, metrics.general, "general")
      else
        []
      end
    
    # Extrai métricas de banco de dados
    db_metrics = 
      if Map.has_key?(metrics, :database) do
        extract_metrics.(extract_metrics, metrics.database, "database")
      else
        []
      end
    
    # Combina todas as métricas
    all_metrics = 
      [{"timestamp", metrics.timestamp}] ++ general_metrics ++ db_metrics
    
    # Cria o cabeçalho CSV
    headers = ["metric", "value"]
    
    # Cria as linhas CSV
    rows = Enum.map(all_metrics, fn {metric, value} -> [metric, to_string(value)] end)
    
    # Combina tudo em uma string CSV
    ([headers] ++ rows)
    |> Enum.map(&Enum.join(&1, ","))
    |> Enum.join("\n")
  end
  
  # Exporta métricas para formato Prometheus
  defp export_to_prometheus(metrics) do
    # Função para extrair métricas em formato Prometheus
    extract_prometheus_metrics = fn ->
      f = fn f, map, prefix ->
        Enum.flat_map(map, fn {key, value} ->
          metric_name = if prefix == "", do: "deeper_hub_#{key}", else: "#{prefix}_#{key}"
          
          cond do
            is_map(value) and not Map.has_key?(value, :count) ->
              f.(f, value, metric_name)
            
            is_map(value) ->
              # Métricas com estatísticas (count, total, avg)
              Enum.map(value, fn {stat_key, stat_value} ->
                full_metric_name = "#{metric_name}_#{stat_key}"
                value_str = (if is_float(stat_value), do: Float.round(stat_value, 4), else: stat_value)
                
                "# HELP #{full_metric_name} Metric for #{metric_name}.#{stat_key}\n" <>
                "# TYPE #{full_metric_name} gauge\n" <>
                "#{full_metric_name} #{value_str}"
              end)
            
            true ->
              # Valores simples
              [
                "# HELP #{metric_name} Metric for #{metric_name}\n" <>
                "# TYPE #{metric_name} gauge\n" <>
                "#{metric_name} #{value}"
              ]
          end
        end)
      end
      f
    end.()
    
    # Extrai métricas gerais
    general_metrics = 
      if Map.has_key?(metrics, :general) do
        extract_prometheus_metrics.(extract_prometheus_metrics, metrics.general, "deeper_hub")
      else
        []
      end
    
    # Extrai métricas de banco de dados
    db_metrics = 
      if Map.has_key?(metrics, :database) do
        extract_prometheus_metrics.(extract_prometheus_metrics, metrics.database, "deeper_hub_db")
      else
        []
      end
    
    # Combina todas as métricas
    (general_metrics ++ db_metrics)
    |> Enum.join("\n\n")
  end
end
