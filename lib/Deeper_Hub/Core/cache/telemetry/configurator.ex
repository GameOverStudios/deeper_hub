defmodule DeeperHub.Core.Cache.Telemetry.Configurator do
  @moduledoc """
  Módulo para configuração do sistema de telemetria do cache.
  
  Este módulo é responsável por configurar os eventos de telemetria,
  definir quais métricas serão coletadas e como serão processadas.
  """
  
  alias DeeperHub.Core.Cache.Telemetry.Reporter
  alias DeeperHub.Core.Cache.Telemetry.Metrics
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  
  @doc """
  Configura o sistema de telemetria para o cache.
  
  Inicializa o reporter, configura handlers de telemetria e
  prepara as métricas para serem coletadas.
  
  ## Parâmetros
  
    * `cache_name` - Nome do cache a ser monitorado
    * `opts` - Opções adicionais de configuração
  
  ## Opções
  
    * `:telemetry_prefix` - Prefixo para eventos de telemetria (padrão: "deeper_hub.cache")
    * `:report_interval` - Intervalo em milissegundos para geração de relatórios (padrão: 60_000)
    * `:enable_logging` - Se deve habilitar logging de métricas (padrão: true)
    * `:enable_prometheus` - Se deve integrar com Prometheus (padrão: false)
  
  ## Retorno
  
    * `{:ok, pid}` - Configuração concluída com sucesso
    * `{:error, reason}` - Erro durante a configuração
  """
  @spec setup(atom(), keyword()) :: {:ok, pid()} | {:error, term()}
  def setup(cache_name, opts \\ []) do
    Logger.info("Configurando telemetria para cache: #{cache_name}", module: __MODULE__)
    
    # Extrai opções
    prefix = Keyword.get(opts, :telemetry_prefix, "deeper_hub.cache")
    report_interval = Keyword.get(opts, :report_interval, 60_000)
    enable_logging = Keyword.get(opts, :enable_logging, true)
    enable_prometheus = Keyword.get(opts, :enable_prometheus, false)
    
    # Inicializa o reporter
    :ok = Reporter.init(cache_name, [
      interval: report_interval,
      prefix: prefix
    ])
    
    # Configura handlers para eventos de telemetria
    attach_handlers(cache_name, prefix, enable_logging)
    
    # Integra com Prometheus se solicitado
    if enable_prometheus do
      Metrics.register_prometheus_metrics(cache_name)
    end
    
    # Inicia processo para coleta periódica
    {:ok, pid} = Task.start_link(fn -> 
      collect_metrics_loop(cache_name, report_interval, enable_logging)
    end)
    
    {:ok, pid}
  end
  
  @doc """
  Para o sistema de telemetria para o cache.
  
  Remove handlers e interrompe a coleta de métricas.
  
  ## Parâmetros
  
    * `prefix` - Prefixo usado na configuração (padrão: "deeper_hub.cache")
  
  ## Retorno
  
    * `:ok` - Sistema de telemetria parado com sucesso
  """
  @spec stop(binary()) :: :ok
  def stop(prefix \\ "deeper_hub.cache") do
    # Remove handlers de telemetria
    detach_handlers(prefix)
    
    # Para o reporter
    Reporter.stop(prefix)
    
    :ok
  end
  
  @doc """
  Gera um relatório detalhado de uso do cache.
  
  Coleta métricas detalhadas e gera um relatório completo,
  incluindo análise de desempenho.
  
  ## Parâmetros
  
    * `cache_name` - Nome do cache a ser analisado
    * `opts` - Opções adicionais para geração do relatório
  
  ## Opções
  
    * `:format` - Formato do relatório (`:text` ou `:json`, padrão: `:text`)
    * `:save_to_file` - Se deve salvar o relatório em arquivo (padrão: `false`)
    * `:file_path` - Caminho do arquivo para salvar (opcional)
  
  ## Retorno
  
    * `{:ok, report}` - Relatório gerado com sucesso
    * `{:error, reason}` - Erro durante a geração do relatório
  """
  @spec generate_report(atom(), keyword()) :: {:ok, map() | binary()} | {:error, term()}
  def generate_report(cache_name, opts \\ []) do
    format = Keyword.get(opts, :format, :text)
    save_to_file = Keyword.get(opts, :save_to_file, false)
    
    try do
      case Reporter.get_metrics(cache_name) do
        {:ok, metrics} ->
          # Formata relatório de acordo com o formato solicitado
          report = case format do
            :json -> 
              Jason.encode!(metrics, pretty: true)
              
            :text ->
              """
              =============== RELATÓRIO DE CACHE ===============
              Cache: #{cache_name}
              Timestamp: #{format_timestamp(metrics.timestamp)}
              
              ESTATÍSTICAS GERAIS:
              - Tamanho: #{metrics.size} entradas
              - Memória: #{format_bytes(metrics.memory)}
              - Hit rate: #{format_percentage(metrics.hit_rate)}
              
              OPERAÇÕES:
              - Hits: #{metrics.hits}
              - Misses: #{metrics.misses}
              - Total: #{metrics.operations}
              
              EXPIRAÇÃO:
              - Itens expirados: #{metrics.expired_count}
              ==================================================
              """
          end
          
          # Salva em arquivo se solicitado
          if save_to_file do
            file_path = Keyword.get(opts, :file_path) || 
                       "cache_report_#{cache_name}_#{:os.system_time(:second)}.#{if format == :json, do: "json", else: "txt"}"
            
            :ok = File.write!(file_path, report)
            Logger.info("Relatório salvo em: #{file_path}", module: __MODULE__)
          end
          
          {:ok, report}
          
        {:error, _} = error -> error
      end
    rescue
      error ->
        Logger.error("Erro ao gerar relatório: #{inspect(error)}", module: __MODULE__)
        {:error, error}
    end
  end
  
  # Funções privadas
  
  # Configura handlers para eventos de telemetria
  defp attach_handlers(cache_name, prefix, enable_logging) do
    # Handler para métricas periódicas
    :telemetry.attach(
      "#{prefix}.periodic-metrics-handler",
      [:"#{prefix}.periodic_metrics"],
      &handle_periodic_metrics/4,
      %{cache_name: cache_name, enable_logging: enable_logging}
    )
    
    # Handler para operações de cache
    :telemetry.attach(
      "#{prefix}.operation-handler",
      [:"#{prefix}.operation"],
      &handle_operation/4,
      %{cache_name: cache_name, enable_logging: enable_logging}
    )
  end
  
  # Remove handlers de telemetria
  defp detach_handlers(prefix) do
    :telemetry.detach("#{prefix}.periodic-metrics-handler")
    :telemetry.detach("#{prefix}.operation-handler")
  end
  
  # Loop para coleta periódica de métricas
  defp collect_metrics_loop(cache_name, interval, enable_logging) do
    # Coleta métricas
    {:ok, _} = Reporter.get_metrics(cache_name)
    
    # Registra em log se habilitado
    if enable_logging do
      # A cada 10 ciclos (10x o intervalo padrão), exibe relatório completo
      if :rand.uniform(10) == 1 do
        Metrics.print_report(cache_name)
      end
    end
    
    # Aguarda intervalo e repete
    :timer.sleep(interval)
    collect_metrics_loop(cache_name, interval, enable_logging)
  end
  
  # Handler para métricas periódicas
  defp handle_periodic_metrics(_event, measurements, metadata, config) do
    %{cache_name: cache_name, enable_logging: enable_logging} = config
    
    if enable_logging && metadata[:cache_name] == cache_name do
      # Log básico de métricas em nível debug
      size = measurements[:size] || 0
      memory = measurements[:memory] || 0
      hit_rate = measurements[:hit_rate] || 0
      
      Logger.debug(
        "Métricas de cache: tamanho=#{size}, memória=#{format_bytes(memory)}, hit_rate=#{format_percentage(hit_rate)}",
        module: __MODULE__
      )
    end
  end
  
  # Handler para operações de cache
  defp handle_operation(_event, measurements, metadata, config) do
    %{cache_name: cache_name, enable_logging: enable_logging} = config
    
    if enable_logging && metadata[:cache_name] == cache_name do
      # Log de operações lentas em nível warning
      duration = measurements[:duration] || 0
      
      if duration > 100_000_000 do # 100ms em nanossegundos
        operation = metadata[:operation] || "desconhecida"
        duration_ms = duration / 1_000_000
        
        Logger.warn(
          "Operação de cache lenta: #{operation} (#{duration_ms}ms)",
          module: __MODULE__
        )
      end
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
  
  # Formata porcentagem para exibição amigável
  defp format_percentage(value) when is_number(value) do
    :io_lib.format("~.2f%", [value * 100])
  end
  
  # Formata timestamp para exibição amigável
  defp format_timestamp(timestamp) when is_integer(timestamp) do
    {:ok, datetime} = DateTime.from_unix(div(timestamp, 1000), :second)
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S")
  end
end
