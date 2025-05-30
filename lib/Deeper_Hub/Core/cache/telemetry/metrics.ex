defmodule DeeperHub.Core.Cache.Telemetry.Metrics do
  @moduledoc """
  Módulo para definição e coleta de métricas do sistema de cache.
  
  Este módulo fornece funções para definir, coletar e visualizar
  métricas de desempenho do sistema de cache, incluindo estatísticas
  de uso, taxas de acerto/erro, e tempo de resposta.
  """
  
  alias DeeperHub.Core.Cache.Telemetry.Reporter
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
  
      iex> DeeperHub.Core.Cache.Telemetry.Metrics.print_report(:my_cache)
      === Relatório de Estatísticas do Cache ===
      Tamanho: 42 entradas
      Memória: 1.24 MB
      Hit rate: 87.5%
      ...
      :ok
  """
  @spec print_report(atom()) :: :ok | {:error, term()}
  def print_report(cache_name) do
    case Reporter.get_metrics(cache_name) do
      {:ok, metrics} ->
        # Formata memória para exibição amigável
        memory_str = format_bytes(metrics.memory)
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
        IO.puts("Timestamp: #{format_timestamp(metrics.timestamp)}")
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
    
    case Reporter.get_metrics(cache_name) do
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
  
  @doc """
  Registra métricas do cache no Prometheus, se disponível.
  
  ## Parâmetros
  
    * `cache_name` - Nome do cache a ser monitorado
  
  ## Retorno
  
    * `:ok` - Métricas registradas com sucesso
    * `{:error, reason}` - Erro durante o registro
  """
  @spec register_prometheus_metrics(atom()) :: :ok | {:error, term()}
  def register_prometheus_metrics(cache_name) do
    # TODO: Integração com Prometheus está desativada até que a biblioteca seja adicionada
    # Retorna erro informando que o Prometheus não está disponível
    Logger.info("Métricas Prometheus desativadas para cache: #{inspect(cache_name)}", 
                module: __MODULE__)
    {:error, :prometheus_not_available}
  end
  
  # Recebe mensagem para atualizar métricas
  def handle_info({:update_cache_metrics, cache_name}, state) do
    # Atualiza métricas do Prometheus
    update_prometheus_metrics(cache_name)
    
    # Agenda próxima atualização
    Process.send_after(self(), {:update_cache_metrics, cache_name}, 15_000)
    
    {:noreply, state}
  end
  
  # Funções privadas
  
  # Stub para atualização de métricas do Prometheus
  defp update_prometheus_metrics(cache_name) do
    # TODO: Implementar quando a biblioteca Prometheus estiver disponível
    
    # Retorna o resultado da operação de métricas
    case Reporter.get_metrics(cache_name) do
      {:ok, _metrics} -> :ok
      {:error, _reason} -> {:error, :metrics_unavailable}
    end
  end
  
  # Formata bytes para exibição amigável
  defp format_bytes(bytes) when is_integer(bytes) do
    cond do
      bytes < 1024 -> "#{bytes} B"
      bytes < 1024 * 1024 -> "#{Float.round(bytes / 1024, 2)} KB"
      bytes < 1024 * 1024 * 1024 -> "#{Float.round(bytes / (1024 * 1024), 2)} MB"
      true -> "#{Float.round(bytes / (1024 * 1024 * 1024), 2)} GB"
    end
  end
  
  # Formata timestamp para exibição amigável
  defp format_timestamp(timestamp) when is_integer(timestamp) do
    {:ok, datetime} = DateTime.from_unix(div(timestamp, 1000), :second)
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S")
  end
end
