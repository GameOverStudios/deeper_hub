defmodule DeeperHub.Core.Cache.Telemetry.CacheMetrics do
  @moduledoc """
  Módulo para definição e coleta de métricas específicas do sistema de cache.
  
  Este módulo estende o sistema de telemetria base do DeeperHub com métricas
  específicas para o cache, como taxa de acerto, tamanho do cache e tempo
  de resposta de operações de cache.
  """
  
  alias DeeperHub.Core.Telemetry.Metrics, as: BaseMetrics
  alias DeeperHub.Core.Cache.Telemetry.Reporter, as: CacheReporter
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  
  @doc """
  Retorna as definições de métricas para o sistema de cache.
  
  Estas definições podem ser utilizadas com bibliotecas como
  :telemetry_metrics para visualização e monitoramento.
  
  ## Parâmetros
  
    * `prefix` - Prefixo para eventos de telemetria (padrão: "deeper_hub.cache")
  
  ## Retorno
  
    * Lista de definições de métricas
  """
  @spec definitions(binary()) :: list()
  def definitions(prefix \\ "deeper_hub.cache") do
    import Telemetry.Metrics
    
    [
      # Métricas de tamanho e memória
      last_value("#{prefix}.periodic_metrics.size", unit: {:native, :byte}),
      last_value("#{prefix}.periodic_metrics.memory", unit: {:native, :byte}),
      
      # Métricas de operações
      counter("#{prefix}.operation.count", 
              tags: [:cache_name, :operation]),
      sum("#{prefix}.operation.duration",
          tags: [:cache_name, :operation],
          unit: {:native, :millisecond}),
      
      # Métricas de hit/miss
      last_value("#{prefix}.periodic_metrics.hit_rate", 
                 unit: {:native, :percent}),
      counter("#{prefix}.periodic_metrics.hits"),
      counter("#{prefix}.periodic_metrics.misses"),
      
      # Métricas de expiração
      last_value("#{prefix}.periodic_metrics.expired_count")
    ]
  end
  
  @doc """
  Imprime um relatório com estatísticas do cache no console.
  
  Coleta as métricas atuais e exibe um relatório formatado.
  
  ## Parâmetros
  
    * `cache_name` - Nome do cache a ser analisado
  
  ## Retorno
  
    * `:ok` - Relatório exibido com sucesso
    * `{:error, reason}` - Erro durante a geração do relatório
  
  ## Exemplos
  
      iex> DeeperHub.Core.Cache.Telemetry.CacheMetrics.print_report(:deeper_hub_cache)
      === Relatório de Estatísticas do Cache ===
      Tamanho: 42 entradas
      Memória: 1.24 MB
      Hit rate: 87.5%
      ...
      :ok
  """
  @spec print_report(atom()) :: :ok | {:error, term()}
  def print_report(cache_name) do
    case CacheReporter.get_metrics(cache_name) do
      {:ok, metrics} ->
        # Formata memória para exibição amigável
        memory_str = BaseMetrics.format_bytes(metrics.memory)
        hit_rate_percent = :io_lib.format("~.2f%", [metrics.hit_rate * 100])
        
        # Imprime relatório
        IO.puts("=== Relatório de Estatísticas do Cache ===")
        IO.puts("Tamanho: #{metrics.size} entradas")
        IO.puts("Memória: #{memory_str}")
        IO.puts("Hit rate: #{hit_rate_percent}")
        IO.puts("Hits: #{metrics.hits}")
        IO.puts("Misses: #{metrics.misses}")
        IO.puts("Total de operações: #{metrics.operations}")
        IO.puts("Itens expirados: #{metrics.expired_count}")
        IO.puts("Timestamp: #{BaseMetrics.format_timestamp(metrics.timestamp)}")
        IO.puts("==========================================")
        
        :ok
        
      {:error, reason} = error ->
        Logger.error("Erro ao gerar relatório de estatísticas: #{inspect(reason)}", 
                    module: __MODULE__)
        error
    end
  end
  
  @doc """
  Registra um snapshot das métricas atuais do cache em um arquivo.
  
  Útil para análises históricas de desempenho.
  
  ## Parâmetros
  
    * `cache_name` - Nome do cache a ser analisado
    * `file_path` - Caminho do arquivo onde salvar (opcional)
  
  ## Retorno
  
    * `{:ok, file_path}` - Snapshot salvo com sucesso
    * `{:error, reason}` - Erro durante o salvamento
  """
  @spec save_snapshot(atom(), binary() | nil) :: {:ok, binary()} | {:error, term()}
  def save_snapshot(cache_name, file_path \\ nil) do
    # Define caminho do arquivo se não fornecido
    file_path = file_path || "cache_metrics_#{cache_name}_#{:os.system_time(:second)}.json"
    
    case CacheReporter.get_metrics(cache_name) do
      {:ok, metrics} ->
        # Serializa métricas para JSON
        json = Jason.encode!(metrics, pretty: true)
        
        # Salva no arquivo
        case File.write(file_path, json) do
          :ok -> 
            Logger.info("Snapshot de métricas do cache salvo em: #{file_path}", 
                      module: __MODULE__)
            {:ok, file_path}
            
          {:error, reason} = error ->
            Logger.error("Erro ao salvar snapshot de métricas: #{inspect(reason)}", 
                        module: __MODULE__)
            error
        end
        
      {:error, _} = error -> error
    end
  end
end
