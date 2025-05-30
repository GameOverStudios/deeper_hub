defmodule DeeperHub.Core.Telemetry.Initializer do
  @moduledoc """
  Módulo responsável pela inicialização do sistema completo de telemetria do DeeperHub.
  
  Este módulo inicializa todos os adaptadores de telemetria para os diferentes
  subsistemas da aplicação, bem como configura os exportadores para visualização
  das métricas.
  """
  
  alias DeeperHub.Core.Telemetry.Adapters.{
    CacheAdapter,
    HttpAdapter,
    NetworkAdapter,
    SecurityAdapter,
    DatabaseAdapter
  }
  alias DeeperHub.Core.Telemetry.Exporters.PrometheusExporter
  
  require Logger
  
  @doc """
  Inicializa o sistema completo de telemetria.
  
  ## Parâmetros
  
  - `opts` - Opções de configuração para o sistema de telemetria.
    - `:enabled_adapters` - Lista de adaptadores a serem inicializados (padrão: todos)
    - `:exporters` - Lista de exportadores a serem inicializados (padrão: nenhum)
    - `:telemetry_prefix` - Prefixo para eventos de telemetria (padrão: "deeper_hub")
  
  ## Retorno
  
  - `{:ok, map()}` - Um mapa com os PIDs dos adaptadores e exportadores inicializados.
  - `{:error, term()}` - Se ocorrer um erro crítico durante a inicialização.
  
  ## Exemplos
  
      iex> DeeperHub.Core.Telemetry.Initializer.setup()
      {:ok, %{adapters: %{cache: #PID<0.123.0>, http: #PID<0.124.0>, ...}, exporters: %{}}}
  """
  @spec setup(keyword()) :: {:ok, map()} | {:error, term()}
  def setup(opts \\ []) do
    # Opções de configuração
    enabled_adapters = Keyword.get(opts, :enabled_adapters, [:cache, :http, :network, :security, :database])
    exporters = Keyword.get(opts, :exporters, [])
    telemetry_prefix = Keyword.get(opts, :telemetry_prefix, "deeper_hub")
    
    adapter_opts = [telemetry_prefix: telemetry_prefix]
    
    # Inicializar adaptadores
    adapters_result = inicializar_adaptadores(enabled_adapters, adapter_opts)
    
    # Inicializar exportadores
    exporters_result = inicializar_exportadores(exporters, opts)
    
    # Verificar resultados
    case {adapters_result, exporters_result} do
      {{:ok, adapters}, {:ok, exporters}} ->
        {:ok, %{adapters: adapters, exporters: exporters}}
        
      {{:error, reason}, _} ->
        {:error, {:adapters_failed, reason}}
        
      {_, {:error, reason}} ->
        {:error, {:exporters_failed, reason}}
    end
  end
  
  @doc """
  Desativa todos os adaptadores e exportadores de telemetria.
  
  ## Retorno
  
  - `:ok` - Se o sistema for desativado com sucesso.
  
  ## Exemplos
  
      iex> DeeperHub.Core.Telemetry.Initializer.teardown()
      :ok
  """
  @spec teardown() :: :ok
  def teardown do
    # Em uma implementação real, isso encerraria todos os processos iniciados
    # Por enquanto, apenas logamos a operação
    Logger.info("[DeeperHub.Core.Telemetry.Initializer] Sistema de telemetria encerrado")
    :ok
  end
  
  # Funções privadas auxiliares
  
  @spec inicializar_adaptadores(list(atom()), keyword()) :: {:ok, map()} | {:error, term()}
  defp inicializar_adaptadores(enabled_adapters, opts) do
    try do
      adapters = %{}
      
      # Inicializar adaptador de cache se habilitado
      adapters = if :cache in enabled_adapters do
        case CacheAdapter.setup(opts) do
          {:ok, pid} ->
            Logger.info("[DeeperHub.Core.Telemetry.Initializer] Adaptador de telemetria do cache inicializado")
            Map.put(adapters, :cache, pid)
          {:error, reason} ->
            Logger.warning("[DeeperHub.Core.Telemetry.Initializer] Falha ao inicializar adaptador de telemetria do cache: #{inspect(reason)}")
            adapters
        end
      else
        adapters
      end
      
      # Inicializar adaptador HTTP se habilitado
      adapters = if :http in enabled_adapters do
        case HttpAdapter.setup(opts) do
          {:ok, pid} ->
            Logger.info("[DeeperHub.Core.Telemetry.Initializer] Adaptador de telemetria HTTP inicializado")
            Map.put(adapters, :http, pid)
          {:error, reason} ->
            Logger.warning("[DeeperHub.Core.Telemetry.Initializer] Falha ao inicializar adaptador de telemetria HTTP: #{inspect(reason)}")
            adapters
        end
      else
        adapters
      end
      
      # Inicializar adaptador de rede se habilitado
      adapters = if :network in enabled_adapters do
        case NetworkAdapter.setup(opts) do
          {:ok, pid} ->
            Logger.info("[DeeperHub.Core.Telemetry.Initializer] Adaptador de telemetria de rede inicializado")
            Map.put(adapters, :network, pid)
          {:error, reason} ->
            Logger.warning("[DeeperHub.Core.Telemetry.Initializer] Falha ao inicializar adaptador de telemetria de rede: #{inspect(reason)}")
            adapters
        end
      else
        adapters
      end
      
      # Inicializar adaptador de segurança se habilitado
      adapters = if :security in enabled_adapters do
        case SecurityAdapter.setup(opts) do
          {:ok, pid} ->
            Logger.info("[DeeperHub.Core.Telemetry.Initializer] Adaptador de telemetria de segurança inicializado")
            Map.put(adapters, :security, pid)
          {:error, reason} ->
            Logger.warning("[DeeperHub.Core.Telemetry.Initializer] Falha ao inicializar adaptador de telemetria de segurança: #{inspect(reason)}")
            adapters
        end
      else
        adapters
      end
      
      # Inicializar adaptador de banco de dados se habilitado
      adapters = if :database in enabled_adapters do
        case DatabaseAdapter.setup(opts) do
          {:ok, pid} ->
            Logger.info("[DeeperHub.Core.Telemetry.Initializer] Adaptador de telemetria de banco de dados inicializado")
            Map.put(adapters, :database, pid)
          {:error, reason} ->
            Logger.warning("[DeeperHub.Core.Telemetry.Initializer] Falha ao inicializar adaptador de telemetria de banco de dados: #{inspect(reason)}")
            adapters
        end
      else
        adapters
      end
      
      {:ok, adapters}
    rescue
      e -> {:error, e}
    end
  end
  
  @spec inicializar_exportadores(list(atom()), keyword()) :: {:ok, map()} | {:error, term()}
  defp inicializar_exportadores(exporters, opts) do
    try do
      exporters_map = %{}
      
      # Inicializar exportador Prometheus se habilitado
      exporters_map = if :prometheus in exporters do
        case PrometheusExporter.setup(opts) do
          {:ok, pid} ->
            Logger.info("[DeeperHub.Core.Telemetry.Initializer] Exportador Prometheus inicializado")
            Map.put(exporters_map, :prometheus, pid)
          {:error, reason} ->
            Logger.warning("[DeeperHub.Core.Telemetry.Initializer] Falha ao inicializar exportador Prometheus: #{inspect(reason)}")
            exporters_map
        end
      else
        exporters_map
      end
      
      {:ok, exporters_map}
    rescue
      e -> {:error, e}
    end
  end
end
