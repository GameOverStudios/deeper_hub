defmodule DeeperHub.Core.Cache.Telemetry.CacheConfigurator do
  @moduledoc """
  Módulo para configuração do sistema de telemetria específico do cache.
  
  Este módulo estende o configurador de telemetria base do DeeperHub
  com funcionalidades específicas para monitoramento do sistema de cache.
  """
  
  alias DeeperHub.Core.Telemetry.Configurator, as: BaseConfigurator
  alias DeeperHub.Core.Cache.Telemetry.Reporter, as: CacheReporter
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  
  @doc """
  Configura o sistema de telemetria para o cache.
  
  ## Parâmetros
  
    * `cache_name` - Nome do cache a ser monitorado
    * `opts` - Opções adicionais de configuração
  
  ## Opções
  
    * `:telemetry_prefix` - Prefixo para eventos de telemetria (padrão: "deeper_hub.cache")
    * `:report_interval` - Intervalo em milissegundos para geração de relatórios (padrão: 60_000)
    * `:enable_logging` - Se deve habilitar logging de métricas (padrão: true)
    * `:enable_prometheus` - Se deve integrar com Prometheus (padrão: false)
  
  ## Retorno
  
    * `{:ok, pid}` - Configurado com sucesso
    * `{:error, reason}` - Erro durante a configuração
  """
  @spec setup(atom(), keyword()) :: {:ok, pid()} | {:error, term()}
  def setup(cache_name, opts \\ []) do
    # Opções de configuração com valores padrão específicos para cache
    opts = Keyword.merge([
      telemetry_prefix: "deeper_hub.cache",
      report_interval: 60_000,
      enable_logging: true,
      enable_prometheus: false
    ], opts)
    
    # Configura o sistema de telemetria base
    case BaseConfigurator.setup(cache_name, opts) do
      {:ok, pid} ->
        # Configura métricas específicas do cache
        setup_cache_specific_metrics(cache_name, opts)
        
        Logger.info("Sistema de telemetria configurado para o cache: #{inspect(cache_name)}", 
                   module: __MODULE__)
        
        {:ok, pid}
        
      {:error, _} = error -> error
    end
  end
  
  @doc """
  Gera um relatório de métricas para o cache.
  
  ## Parâmetros
  
    * `cache_name` - Nome do cache a ser analisado
    * `opts` - Opções adicionais
  
  ## Opções
  
    * `:format` - Formato do relatório (`:text`, `:json`) (padrão: `:text`)
    * `:save_to_file` - Se deve salvar em arquivo (padrão: `false`)
    * `:file_path` - Caminho do arquivo para salvar (opcional)
  
  ## Retorno
  
    * `{:ok, report}` - Relatório gerado com sucesso
    * `{:ok, file_path}` - Relatório salvo em arquivo com sucesso
    * `{:error, reason}` - Erro durante a geração
  """
  @spec generate_report(atom(), keyword()) :: {:ok, binary() | map()} | {:ok, binary()} | {:error, term()}
  def generate_report(cache_name, opts \\ []) do
    format = Keyword.get(opts, :format, :text)
    save_to_file = Keyword.get(opts, :save_to_file, false)
    
    try do
      case CacheReporter.get_metrics(cache_name) do
        {:ok, metrics} ->
          # Formata o relatório de acordo com o formato solicitado
          report = case format do
            :text -> format_text_report(cache_name, metrics)
            :json -> Jason.encode!(metrics, pretty: true)
            _ -> raise ArgumentError, "Formato de relatório não suportado: #{inspect(format)}"
          end
          
          # Salva em arquivo, se solicitado
          if save_to_file do
            file_path = Keyword.get(opts, :file_path) || 
                         "cache_metrics_#{cache_name}_#{:os.system_time(:second)}.#{if format == :json, do: "json", else: "txt"}"
            
            case File.write(file_path, report) do
              :ok -> 
                Logger.info("Relatório de métricas do cache salvo em: #{file_path}", 
                          module: __MODULE__)
                {:ok, file_path}
                
              {:error, reason} = error ->
                Logger.error("Erro ao salvar relatório de métricas do cache: #{inspect(reason)}", 
                           module: __MODULE__)
                error
            end
          else
            {:ok, report}
          end
          
        {:error, _} = error -> error
      end
    rescue
      e ->
        Logger.error("Erro ao gerar relatório de métricas do cache: #{inspect(e)}", 
                    module: __MODULE__)
        {:error, e}
    end
  end
  
  @doc """
  Para o sistema de telemetria para o cache.
  
  ## Parâmetros
  
    * `cache_name` - Nome do cache
  
  ## Retorno
  
    * `:ok` - Parado com sucesso
  """
  @spec teardown(atom()) :: :ok
  def teardown(cache_name) do
    BaseConfigurator.teardown(cache_name)
    Logger.info("Sistema de telemetria desativado para o cache: #{inspect(cache_name)}", 
               module: __MODULE__)
    :ok
  end
  
  # Funções privadas
  
  # Configura métricas específicas do cache
  defp setup_cache_specific_metrics(cache_name, opts) do
    _prefix = Keyword.get(opts, :telemetry_prefix)
    
    # Configurações específicas para métricas de cache
    Logger.debug("Métricas específicas do cache configuradas para: #{inspect(cache_name)}", 
                module: __MODULE__)
    :ok
  end
  
  # Formata relatório de métricas do cache como texto
  defp format_text_report(cache_name, metrics) do
    # Formata valores para exibição amigável
    memory_str = DeeperHub.Core.Telemetry.Metrics.format_bytes(metrics.memory)
    hit_rate_percent = :io_lib.format("~.2f%", [metrics.hit_rate * 100])
    timestamp_str = DeeperHub.Core.Telemetry.Metrics.format_timestamp(metrics.timestamp)
    
    """
    === Relatório de Estatísticas do Cache ===
    Cache: #{cache_name}
    Timestamp: #{timestamp_str}
    Tamanho: #{metrics.size} entradas
    Memória: #{memory_str}
    Hit rate: #{hit_rate_percent}
    Hits: #{metrics.hits}
    Misses: #{metrics.misses}
    Total de operações: #{metrics.operations}
    Itens expirados: #{metrics.expired_count}
    ==========================================
    """
  end
end
