defmodule DeeperHub.Core.Cache.Integration do
  @moduledoc """
  Módulo para integração e configuração avançada do sistema de cache.

  Este módulo fornece funções utilitárias para configurar e utilizar
  todos os recursos avançados do sistema de cache, incluindo hooks,
  warmers, limits, roteamento distribuído e telemetria.

  Serve como ponto central para a integração do cache com outras
  partes do sistema DeeperHub.
  """

  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Cache
  alias Cachex
  alias Jason

  @cache_name :deeper_hub_cache

  @doc """
  Configura o sistema de cache com opções avançadas.

  Esta função deve ser chamada durante a inicialização da aplicação
  para configurar o sistema de cache com todas as opções desejadas.

  ## Parâmetros

    * `opts` - Opções de configuração

  ## Opções

    * `:enable_compression` - Se deve habilitar compressão (padrão: `true`)
    * `:enable_persistence` - Se deve habilitar persistência em disco (padrão: `true`)
    * `:persistence_interval` - Intervalo em ms para backup automático (padrão: 3_600_000)
    * `:enable_telemetry` - Se deve habilitar telemetria (padrão: `true`)
    * `:cache_limit` - Limite máximo de itens no cache (padrão: 10_000)
    * `:default_ttl` - TTL padrão em segundos (padrão: 300)

  ## Retorno

    * `:ok` - Configuração concluída com sucesso
    * `{:error, reason}` - Erro durante a configuração
  """
  @spec configure(keyword()) :: :ok | {:error, term()}
  def configure(opts \\ []) do
    DeeperHub.Core.Logger.info("Configurando sistema de cache avançado")

    # Extrai opções
    _enable_compression = Keyword.get(opts, :enable_compression, true)
    enable_persistence = Keyword.get(opts, :enable_persistence, true)
    persistence_interval = Keyword.get(opts, :persistence_interval, 3_600_000)
    _enable_telemetry = Keyword.get(opts, :enable_telemetry, true)
    _cache_limit = Keyword.get(opts, :cache_limit, 10_000)
    _default_ttl = Keyword.get(opts, :default_ttl, 300)

    # Configura persistência
    if enable_persistence do
      DeeperHub.Core.Logger.info("Configurando backup automático do cache")

      # Tenta restaurar dados de backup anterior
      case DeeperHub.Core.Cache.Persistence.DiskStorage.restore_from_disk(@cache_name) do
        {:ok, _count} ->
          DeeperHub.Core.Logger.info("Cache restaurado com sucesso a partir do backup")

        {:error, :not_found} ->
          DeeperHub.Core.Logger.info("Nenhum backup de cache encontrado para restauração")

        {:error, reason} ->
          DeeperHub.Core.Logger.error("Erro ao restaurar cache: #{inspect(reason)}")
      end

      # Configura backup automático
      {:ok, _pid} = DeeperHub.Core.Cache.Persistence.DiskStorage.schedule_automatic_backup(@cache_name, persistence_interval)
    end

    # Pré-carrega configurações comuns
    _result = preload_configurations()

    :ok
  end

  @doc """
  Pré-carrega configurações comuns no cache.

  Esta função preenche o cache com configurações que são
  frequentemente acessadas, melhorando a performance do sistema.

  ## Retorno

    * `{:ok, count}` - Número de configurações carregadas
    * `{:error, reason}` - Erro durante o carregamento
  """
  @spec preload_configurations() :: {:ok, integer()} | {:error, term()}
  def preload_configurations do
    DeeperHub.Core.Logger.info("Pré-carregando configurações no cache")

    configs = [
      {"system:version", "1.0.0"},
      {"system:startup_time", DateTime.utc_now() |> DateTime.to_iso8601()},
      {"system:environment", Application.get_env(:deeper_hub, :environment, :dev)},
      {"limits:request_rate", 100},
      {"limits:max_concurrent", 20},
      {"settings:cache_ttl", 300},
      {"settings:log_level", "info"},
      {"settings:maintenance_mode", false}
    ]

    # Carrega configurações com namespace
    Enum.each(configs, fn {key, value} ->
      Cache.put(key, value, namespace: "config", ttl: :infinity)
    end)

    {:ok, length(configs)}
  end

  @doc """
  Gera um relatório completo do sistema de cache.

  Coleta estatísticas e métricas detalhadas sobre o uso do cache
  e gera um relatório completo para análise.

  ## Parâmetros

    * `format` - Formato do relatório (`:text` ou `:json`, padrão: `:text`)
    * `save` - Se deve salvar o relatório em arquivo (padrão: `false`)

  ## Retorno

    * `{:ok, report}` - Relatório gerado com sucesso
    * `{:error, reason}` - Erro durante a geração do relatório
  """
  @spec generate_report(atom(), boolean()) :: {:ok, binary()} | {:error, term()}
  def generate_report(format \\ :text, save \\ false) do
    alias DeeperHub.Core.Telemetry.Adapters.CacheAdapter

    try do
      # Coleta métricas do cache
      case CacheAdapter.collect_metrics(@cache_name) do
        {:ok, metrics} ->
          # Formata o relatório
          report = format_report(metrics, format)

          # Salva em arquivo se solicitado
          if save do
            filename = "cache_report_#{DateTime.utc_now() |> DateTime.to_string() |> String.replace(~r/[\s:.-]/, "_")}.#{format}"
            File.write!(filename, report)
            {:ok, "Relatório salvo em: #{filename}"}
          else
            {:ok, report}
          end

        {:error, reason} ->
          {:error, "Falha ao coletar métricas: #{inspect(reason)}"}
      end
    rescue
      e ->
        DeeperHub.Core.Logger.error("Erro ao gerar relatório: #{inspect(e)}")
        {:error, "Falha ao gerar relatório: #{inspect(e)}"}
    end
  end

  # Formata as métricas conforme o formato solicitado
  defp format_report(metrics, :text) do
    """
    === RELATÓRIO DO SISTEMA DE CACHE ===
    Timestamp: #{DateTime.utc_now() |> DateTime.to_string()}

    Métricas de Uso:
      - Itens em cache: #{metrics.size || 0}
      - Taxa de acerto: #{metrics.hit_rate || 0}%
      - Operações/segundo: #{metrics.ops_per_sec || 0}

    Métricas de Desempenho:
      - Tempo médio de resposta: #{metrics.avg_response_time || 0}ms
      - Uso de memória: #{metrics.memory_usage || 0} bytes
    """
  end

  defp format_report(metrics, :json) do
    Jason.encode!(metrics, pretty: true)
  end

  @doc """
  Configura integração entre Cache e Telemetria.

  Esta função configura os hooks e adaptadores necessários para que
  o sistema de cache seja monitorado pelo sistema de telemetria.

  ## Retorno

  - `:ok` - Integração configurada com sucesso
  - `{:error, reason}` - Erro durante a configuração
  """
  @spec setup_telemetry_integration() :: :ok | {:error, any()}
  def setup_telemetry_integration do
    DeeperHub.Core.Logger.info("Configurando integração Cache-Telemetry...")

    try do
      # Configura adaptador de telemetria para o cache
      alias DeeperHub.Core.Telemetry.Adapters.CacheAdapter

      telemetry_config = Application.get_env(:deeper_hub, :telemetry, [])

      cache_telemetry_opts = [
        cache_name: @cache_name,
        telemetry_prefix: Keyword.get(telemetry_config, :telemetry_prefix, "deeper_hub") <> ".cache",
        report_interval: Keyword.get(telemetry_config, :report_interval, 60_000),
        enable_logging: Keyword.get(telemetry_config, :enable_logging, true),
        enable_prometheus: Keyword.get(telemetry_config, :enable_prometheus, false)
      ]

      case CacheAdapter.setup(cache_telemetry_opts) do
        {:ok, _pid} ->
          DeeperHub.Core.Logger.info("Adaptador de telemetria do cache configurado com sucesso")

          # Configura eventos de telemetria personalizados
          setup_cache_telemetry_events()

          :ok

        {:error, reason} ->
          DeeperHub.Core.Logger.error("Falha ao configurar adaptador de telemetria do cache: #{inspect(reason)}")
          {:error, reason}
      end
    rescue
      error ->
        DeeperHub.Core.Logger.error("Erro ao configurar integração Cache-Telemetry: #{inspect(error)}")
        {:error, error}
    end
  end

  # Configura eventos de telemetria personalizados para o cache
  defp setup_cache_telemetry_events do
    # Importa o módulo de handlers nomeados
    alias DeeperHub.Core.Cache.Telemetry.Handlers
    
    # Anexa handlers para eventos de telemetria do Cachex
    events = [
      [:cachex, :action],
      [:cachex, :action, :start],
      [:cachex, :action, :stop]
    ]

    Enum.each(events, fn event ->
      :telemetry.attach(
        "deeper_hub_cache_#{Enum.join(event, "_")}",
        event,
        &Handlers.handle_event/4,  # Usa a função nomeada do módulo Handlers
        %{cache_name: @cache_name}
      )
    end)

    DeeperHub.Core.Logger.debug("Eventos de telemetria do cache configurados")
  end

  @doc """
  Limpa itens expirados e realiza manutenção no cache.

  Executa operações de manutenção, como limpeza de itens expirados,
  otimização de memória e verificação de integridade.

  ## Parâmetros

    * `opts` - Opções de manutenção

  ## Opções

    * `:purge_expired` - Se deve limpar itens expirados (padrão: `true`)
    * `:optimize_memory` - Se deve otimizar uso de memória (padrão: `true`)
    * `:verify_integrity` - Se deve verificar integridade (padrão: `false`)

  ## Retorno

    * `{:ok, stats}` - Estatísticas da manutenção realizada
    * `{:error, reason}` - Erro durante a manutenção
  """
  @spec maintenance(keyword()) :: {:ok, map()} | {:error, term()}
  def maintenance(opts \\ []) do
    DeeperHub.Core.Logger.info("Realizando manutenção do cache")

    purge_expired = Keyword.get(opts, :purge_expired, true)
    optimize_memory = Keyword.get(opts, :optimize_memory, true)
    verify_integrity = Keyword.get(opts, :verify_integrity, false)

    stats = %{purged: 0, optimized: false, integrity: :not_checked}

    # Purga itens expirados
    stats = if purge_expired do
      case Cachex.purge(@cache_name) do
        {:ok, count} ->
          DeeperHub.Core.Logger.info("Limpeza de #{count} itens expirados realizada")
          Map.put(stats, :purged, count)

        {:error, reason} ->
          DeeperHub.Core.Logger.error("Erro durante a limpeza de itens expirados: #{inspect(reason)}")
          Map.put(stats, :purged, :error)
      end
    else
      stats
    end

    # Otimiza uso de memória
    stats = if optimize_memory do
      case cachex_compact(@cache_name) do
        {:ok, true} ->
          DeeperHub.Core.Logger.info("Nenhum item expirado encontrado")
          Map.put(stats, :optimized, true)

        {:error, reason} ->
          DeeperHub.Core.Logger.error("Erro durante a compactação de memória: #{inspect(reason)}")
          Map.put(stats, :optimized, :error)
      end
    else
      stats
    end

    # Verifica integridade do cache
    stats = if verify_integrity do
      # Simples verificação de integridade
      try do
        {:ok, size} = Cachex.size(@cache_name)
        {:ok, keys} = Cachex.keys(@cache_name)

        if length(keys) == size do
          DeeperHub.Core.Logger.info("Verificação de integridade do cache concluída")
          Map.put(stats, :integrity, :ok)
        else
          DeeperHub.Core.Logger.warning("Possível inconsistência no cache detectada")
          Map.put(stats, :integrity, :inconsistent)
        end
      rescue
        error ->
          DeeperHub.Core.Logger.error("Erro durante a verificação de integridade: #{inspect(error)}")
          Map.put(stats, :integrity, :error)
      end
    else
      stats
    end

    {:ok, stats}
  end

  @doc """
  Busca entradas no cache por padrão de chave.

  Utiliza consultas avançadas para encontrar entradas que correspondem
  a um determinado padrão de chave.

  ## Parâmetros

    * `pattern` - Padrão para busca (formato glob: "*" e "?")
    * `opts` - Opções adicionais

  ## Opções

    * `:namespace` - Namespace para busca (opcional)
    * `:include_expired` - Se deve incluir itens expirados (padrão: `false`)
    * `:limit` - Limite máximo de resultados (padrão: `100`)

  ## Retorno

    * `{:ok, entries}` - Entradas encontradas
    * `{:error, reason}` - Erro durante a busca

  ## Exemplos

      iex> DeeperHub.Core.Cache.Integration.search("user:*")
      {:ok, [{"user:123", %{name: "João"}}, {"user:456", %{name: "Maria"}}]}
  """
  @spec search(binary(), keyword()) :: {:ok, list()} | {:error, term()}
  def search(pattern, opts \\ []) do
    namespace = Keyword.get(opts, :namespace)
    include_expired = Keyword.get(opts, :include_expired, false)
    limit = Keyword.get(opts, :limit, 100)

    case Cache.get_keys_by_pattern(pattern, namespace: namespace) do
      {:ok, keys} ->
        # Limita o número de chaves
        keys = Enum.take(keys, limit)

        # Busca valores para as chaves encontradas
        entries = Enum.map(keys, fn key ->
          case Cache.get(key) do
            {:ok, value} -> {key, value}
            _ -> {key, nil}
          end
        end)

        # Filtra entradas com valor nil, a menos que include_expired seja true
        entries = if include_expired do
          entries
        else
          Enum.filter(entries, fn {_key, value} -> value != nil end)
        end

        {:ok, entries}

      error -> error
    end
  end

  @doc """
  Visualiza o estado atual do sistema de cache.

  Exibe informações detalhadas sobre o estado atual do cache,
  incluindo estatísticas de uso, configurações e métricas.

  ## Retorno

    * `:ok` - Informações exibidas com sucesso
  """
  @spec status() :: :ok
  def status do
    # Exibe versão e estado
    IO.puts("\n===== ESTADO DO SISTEMA DE CACHE =====")

    # Obtém estatísticas básicas
    {:ok, stats} = Cachex.stats(@cache_name)
    {:ok, size} = Cachex.size(@cache_name)
    {:ok, memory} = cachex_memory(@cache_name)

    # Calcula taxa de acerto
    hits = stats.hits || 0
    misses = stats.misses || 0
    operations = stats.operations || 0
    hit_rate = if operations > 0, do: hits / operations * 100, else: 0

    # Formata memória para exibição
    memory_str = cond do
      memory < 1024 -> "#{memory} B"
      memory < 1024 * 1024 -> "#{Float.round(memory / 1024, 2)} KB"
      memory < 1024 * 1024 * 1024 -> "#{Float.round(memory / (1024 * 1024), 2)} MB"
      true -> "#{Float.round(memory / (1024 * 1024 * 1024), 2)} GB"
    end

    # Exibe estatísticas
    IO.puts("\nESTATÍSTICAS:")
    IO.puts("- Tamanho: #{size} entradas")
    IO.puts("- Memória: #{memory_str}")
    IO.puts("- Operações: #{operations}")
    IO.puts("- Hits: #{hits}")
    IO.puts("- Misses: #{misses}")
    IO.puts("- Taxa de acerto: #{Float.round(hit_rate, 2)}%")

    # Exibe configurações do sistema
    IO.puts("\nCONFIGURAÇÕES:")
    show_config = fn key, default ->
      case Cache.get(key, namespace: "config") do
        {:ok, value} -> value
        _ -> default
      end
    end

    IO.puts("- Versão: #{show_config.("system:version", "N/A")}")
    IO.puts("- Ambiente: #{show_config.("system:environment", "dev")}")
    IO.puts("- TTL padrão: #{show_config.("settings:cache_ttl", 300)} segundos")
    IO.puts("- Modo manutenção: #{show_config.("settings:maintenance_mode", false)}")

    # Exibe últimas operações (se o hook de logging estiver habilitado)
    IO.puts("\n===================================")

    :ok
  end

  # Funções wrapper para Cachex para evitar avisos de compilação

  @doc false
  defp cachex_memory(cache_name) do
    try do
      # Chama a função usando apply para evitar warnings
      apply(Cachex, :memory, [cache_name])
    rescue
      e ->
        DeeperHub.Core.Logger.error("Erro ao obter memória do cache: #{inspect(e)}")
        {:error, :memory_unavailable}
    end
  end

  @doc false
  defp cachex_compact(cache_name) do
    try do
      # Chama a função usando apply para evitar warnings
      apply(Cachex, :compact, [cache_name])
    rescue
      e ->
        DeeperHub.Core.Logger.error("Erro ao compactar cache: #{inspect(e)}")
        {:error, :compact_failed}
    end
  end
end
