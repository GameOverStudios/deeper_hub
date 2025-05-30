defmodule DeeperHub.Core.Cache.Supervisor do
  @moduledoc """
  Supervisor para o sistema de cache do DeeperHub.
  
  Este supervisor é responsável por iniciar e monitorar os processos
  relacionados ao sistema de cache, garantindo sua resiliência.
  
  Utiliza o supervisor do Cachex para gerenciar a árvore de processos do cache,
  garantindo que mesmo em caso de falhas, o sistema se recupere automaticamente.
  """
  
  use Supervisor
  
  import Cachex.Spec
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  # Aliases para módulos necessários
  
  @cache_name :deeper_hub_cache
  @default_ttl 300  # 5 minutos em segundos
  
  @doc """
  Inicia o supervisor do sistema de cache.
  
  ## Parâmetros
  
    * `opts` - Opções de configuração (opcional)
      * `:compressed` - Se verdadeiro, habilita a compressão ETS (padrão: `true`)
      * `:stats` - Se verdadeiro, habilita as estatísticas de cache (padrão: `true`)
      * `:transactions` - Se verdadeiro, habilita transações (padrão: `true`)
      * `:expiry_interval` - Intervalo em milissegundos para limpar itens expirados (padrão: 60000)
      * `:default_ttl` - TTL padrão em segundos para itens do cache (padrão: 300)
      * `:telemetry` - Se verdadeiro, habilita a telemetria do cache (padrão: `true`)
      * `:telemetry_report_interval` - Intervalo em milissegundos para relatórios de telemetria (padrão: 60000)
      * `:telemetry_logging` - Se verdadeiro, habilita logging de telemetria (padrão: `true`)
      * `:prometheus_integration` - Se verdadeiro, integra com Prometheus (padrão: `false`)
      * `:cache_limit` - Limite máximo de itens no cache (padrão: 10000)
  
  ## Retorno
  
    * `{:ok, pid}` - Supervisor iniciado com sucesso
    * `{:error, reason}` - Falha ao iniciar o supervisor
  """
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @impl true
  def init(opts) do
    Logger.info("Iniciando supervisor do sistema de cache...", module: __MODULE__)
    
    # Opções padrão
    compressed = Keyword.get(opts, :compressed, true)
    use_stats = Keyword.get(opts, :stats, true)
    use_transactions = Keyword.get(opts, :transactions, true)
    expiry_interval = Keyword.get(opts, :expiry_interval, 60_000)
    default_ttl = Keyword.get(opts, :default_ttl, @default_ttl)
    
    # Opções de telemetria
    enable_telemetry = Keyword.get(opts, :telemetry, true)
    telemetry_report_interval = Keyword.get(opts, :telemetry_report_interval, 60_000)
    enable_telemetry_logging = Keyword.get(opts, :telemetry_logging, true)
    prometheus_integration = Keyword.get(opts, :prometheus_integration, false)
    
    # Configura hooks para logging e estatísticas
    hooks = [
      hook(module: DeeperHub.Core.Cache.Hooks.LoggerHook, name: :hook_logger)
    ]
    
    # Adiciona hook de estatísticas se habilitado
    hooks = if use_stats do
      [hook(module: Cachex.Stats, name: :stats_logger) | hooks]
    else
      hooks
    end
    
    # Configura limites do cache (LRU por padrão)
    cache_limit = Keyword.get(opts, :cache_limit, 10_000)
    
    # Adiciona hooks para implementação LRU (Least Recently Used)
    hooks = [
      hook(module: Cachex.Limit.Accessed),
      hook(module: Cachex.Limit.Scheduled, args: {
        cache_limit,  # tamanho máximo do cache
        [],           # opções para `Cachex.prune/3`
        []            # opções para `Cachex.Limit.Scheduled`
      }) | hooks
    ]
    
    # Configura opções de aquecimento (warmers)
    warmers = []
    
    # Configura as opções do cache
    cache_opts = [
      compressed: compressed,
      transactions: use_transactions,
      hooks: hooks,
      stats: use_stats,
      warmers: warmers,
      expiration: expiration(
        interval: expiry_interval,
        default: :timer.seconds(default_ttl),
        lazy: true
      )
    ]
    
    # Lista de processos filhos a serem supervisionados
    children = [
      # Inicia o Cachex com as opções configuradas
      {Cachex, [@cache_name, cache_opts]}
    ]
    
    # Inicializa o supervisor
    result = Supervisor.init(children, strategy: :one_for_one)
    
    # Configura telemetria após inicialização do cache (async)
    if enable_telemetry do
      Task.start(fn ->
        # Pequena pausa para garantir que o cache já esteja inicializado
        Process.sleep(1000)
        DeeperHub.Core.Logger.info("Inicializando telemetria para o sistema de cache")
        alias DeeperHub.Core.Telemetry.Adapters.CacheAdapter
        CacheAdapter.setup([
          cache_name: @cache_name,
          telemetry_prefix: "deeper_hub.cache",
          report_interval: telemetry_report_interval,
          enable_logging: enable_telemetry_logging,
          enable_prometheus: prometheus_integration
        ])
      end)
    end
    
    # Retorna o resultado da inicialização do supervisor
    result
  end
end
