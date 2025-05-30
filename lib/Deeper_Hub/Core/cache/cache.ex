defmodule DeeperHub.Core.Cache do
  alias DeeperHub.Core.Cache.Queries.QueryBuilder
  @moduledoc """
  Sistema de cache para o DeeperHub.

  Este módulo oferece uma interface unificada para operações de cache,
  utilizando Cachex como implementação subjacente. Ele é responsável por:

  - Armazenar e recuperar dados em cache
  - Gerenciar expiração de itens
  - Fornecer estatísticas de uso do cache
  - Oferecer suporte a namespaces para melhor organização
  - Habilitar hooks para operações de cache
  - Permitir transações seguras
  - Gerenciar cache distribuído em ambiente clusterizado
  - Aplicar políticas de limite de tamanho e recursos
  - Pré-carregar dados frequentemente utilizados

  O sistema de cache é essencial para otimizar o desempenho, reduzindo
  consultas ao banco de dados e acelerando operações frequentes.
  """

  import Cachex.Spec
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Cache.Hooks.LoggerHook
  alias DeeperHub.Core.Cache.Limits.LruPolicy
  alias DeeperHub.Core.Cache.Routing.DistributedRouter
  alias DeeperHub.Core.Cache.Warmers.ConfigWarmer

  @default_ttl 300  # 5 minutos em segundos
  @cache_name :deeper_hub_cache

  @doc """
  Inicializa o sistema de cache.

  Deve ser chamado durante a inicialização da aplicação para garantir
  que o cache esteja pronto para uso. Configura recursos avançados como
  hooks personalizados, políticas de limite, warmers e roteamento distribuído.

  ## Opções

    * `:compressed` - Se verdadeiro, habilita a compressão ETS para reduzir o uso de memória (padrão: `true`)
    * `:stats` - Se verdadeiro, habilita as estatísticas de cache (padrão: `true`)
    * `:transactions` - Se verdadeiro, habilita transações (padrão: `true`)
    * `:expiry_interval` - Intervalo em milissegundos para limpar itens expirados (padrão: 60000)
    * `:default_ttl` - TTL padrão em segundos para itens do cache (padrão: 300)
    * `:use_logger_hook` - Se verdadeiro, ativa o hook de log de operações (padrão: `true` em desenvolvimento, `false` em produção)
    * `:use_lru_limit` - Se verdadeiro, aplica política de limite LRU (padrão: `true`)
    * `:lru_limit` - Limite máximo de itens para a política LRU (padrão: baseado no ambiente)
    * `:use_distributed` - Se verdadeiro, ativa o cache distribuído (padrão: `true` se em cluster)
    * `:use_warmers` - Se verdadeiro, ativa pré-carregadores (padrão: `true`)

  ## Exemplos

      iex> DeeperHub.Core.Cache.init()
      :ok

      iex> DeeperHub.Core.Cache.init(use_lru_limit: true, lru_limit: 5000)
      :ok

  """
  @spec init(keyword()) :: :ok | {:error, term()}
  def init(opts \\ []) do
    DeeperHub.Core.Logger.info("Inicializando sistema de cache...")
    
    # Ambiente atual
    environment = Application.get_env(:deeper_hub, :environment, :development)
    
    # Opções padrão
    compressed = Keyword.get(opts, :compressed, true)
    use_stats = Keyword.get(opts, :stats, true)
    use_transactions = Keyword.get(opts, :transactions, true)
    expiry_interval = Keyword.get(opts, :expiry_interval, 60_000)
    default_ttl = Keyword.get(opts, :default_ttl, @default_ttl)
    
    # Opções avançadas
    use_logger_hook = Keyword.get(opts, :use_logger_hook, environment != :production)
    use_lru_limit = Keyword.get(opts, :use_lru_limit, true)
    use_distributed = Keyword.get(opts, :use_distributed, DistributedRouter.use_distributed_router?())
    use_warmers = Keyword.get(opts, :use_warmers, true)
    
    # Configura opções básicas do cache
    cache_opts = [
      compressed: compressed,
      transactions: use_transactions,
      expiration: expiration(
        interval: expiry_interval,
        default: :timer.seconds(default_ttl),
        lazy: true
      )
    ]
    
    # Adiciona hooks para estatísticas e logging
    hooks = []
    
    # Adiciona hook de estatísticas se habilitado
    hooks = if use_stats do
      [hook(
        module: Cachex.Stats,
        name: :stats_logger,
        args: []
      ) | hooks]
    else
      hooks
    end
    
    # Adiciona hook de logging se habilitado
    hooks = if use_logger_hook do
      [hook(
        module: LoggerHook,
        name: :logger_hook,
        args: []
      ) | hooks]
    else
      hooks
    end
    
    # Adiciona hook de política LRU se habilitado
    hooks = if use_lru_limit do
      custom_limit = Keyword.get(opts, :lru_limit)
      
      lru_hook = if custom_limit do
        LruPolicy.create_hook(custom_limit)
      else
        LruPolicy.create_recommended_hook()
      end
      
      [lru_hook | hooks]
    else
      hooks
    end
    
    # Adiciona hooks ao cache se houver algum
    cache_opts = if hooks != [] do
      Keyword.put(cache_opts, :hooks, hooks)
    else
      cache_opts
    end
    
    # Configura roteador distribuído se habilitado
    cache_opts = if use_distributed do
      router = DistributedRouter.create_recommended_router()
      Keyword.put(cache_opts, :router, router)
    else
      cache_opts
    end
    
    # Configura warmers se habilitados
    cache_opts = if use_warmers do
      warmers = [
        warmer(
          module: ConfigWarmer,
          name: :config_warmer
        )
      ]
      Keyword.put(cache_opts, :warmers, warmers)
    else
      cache_opts
    end
    
    # Log de configurações
    DeeperHub.Core.Logger.debug("Configurações do cache: #{inspect(cache_opts)}")
    
    # Inicializa o cache principal com Cachex
    case Cachex.start_link(@cache_name, cache_opts) do
      {:ok, _pid} ->
        DeeperHub.Core.Logger.info("Sistema de cache inicializado com sucesso")
        :ok
      {:error, {:already_started, _pid}} ->
        DeeperHub.Core.Logger.info("Sistema de cache já estava inicializado")
        :ok
      {:error, reason} ->
        DeeperHub.Core.Logger.error("Falha ao inicializar o sistema de cache: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Armazena um valor no cache.

  ## Parâmetros

    * `key` - A chave para o valor no cache
    * `value` - O valor a ser armazenado
    * `opts` - Opções adicionais (como TTL)

  ## Opções

    * `:ttl` - Tempo de vida em segundos (padrão: #{@default_ttl})
    * `:namespace` - Namespace para a chave (opcional)
    * `:ttl_on_update` - Se `true`, atualiza o TTL do valor caso ele já exista (padrão: `true`)
    * `:async` - Se `true`, executa a operação de forma assíncrona (padrão: `false`)

  ## Exemplos

      iex> DeeperHub.Core.Cache.put("user:123", %{name: "João"})
      :ok

      iex> DeeperHub.Core.Cache.put("token:abc", "xyz123", ttl: 60)
      :ok

      iex> DeeperHub.Core.Cache.put("server:1", %{status: "online"}, namespace: "servers")
      :ok

  """
  @spec put(binary(), any(), keyword()) :: :ok | {:error, any()}
  def put(key, value, opts \\ []) do
    ttl = Keyword.get(opts, :ttl, @default_ttl) * 1000  # Converte para milissegundos
    namespace = Keyword.get(opts, :namespace)
    ttl_on_update = Keyword.get(opts, :ttl_on_update, true) 
    is_async = Keyword.get(opts, :async, false)
    
    cache_key = build_key(key, namespace)
    
    # Configura opções para o Cachex
    cache_opts = [
      ttl: ttl,
      ttl_on_update: ttl_on_update
    ]
    
    # Adiciona operação assíncrona se solicitado
    cache_opts = if is_async, do: [{:async, true} | cache_opts], else: cache_opts
    
    case Cachex.put(@cache_name, cache_key, value, cache_opts) do
      {:ok, true} -> :ok
      # Quando assíncrono, retorna :ok diretamente
      {:ok, :ok} when is_async -> :ok 
      {:error, reason} -> 
        DeeperHub.Core.Logger.error("Erro ao armazenar em cache #{cache_key}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Recupera um valor do cache.

  ## Parâmetros

    * `key` - A chave do valor no cache
    * `opts` - Opções adicionais

  ## Opções

    * `:namespace` - Namespace para a chave (opcional)
    * `:default` - Valor padrão se a chave não for encontrada (opcional)

  ## Retorno

    * `{:ok, value}` - Valor encontrado no cache
    * `{:ok, default}` - Valor padrão, se a chave não for encontrada e default for especificado
    * `{:error, :not_found}` - Se a chave não for encontrada e nenhum default for especificado

  ## Exemplos

      iex> DeeperHub.Core.Cache.get("user:123")
      {:ok, %{name: "João"}}

      iex> DeeperHub.Core.Cache.get("invalid_key", default: nil)
      {:ok, nil}

      iex> DeeperHub.Core.Cache.get("server:1", namespace: "servers")
      {:ok, %{status: "online"}}

  """
  @spec get(binary(), keyword()) :: {:ok, any()} | {:error, :not_found}
  def get(key, opts \\ []) do
    namespace = Keyword.get(opts, :namespace)
    default = Keyword.get(opts, :default, :__no_default__)
    
    cache_key = build_key(key, namespace)
    
    case Cachex.get(@cache_name, cache_key) do
      {:ok, nil} when default != :__no_default__ -> {:ok, default}
      {:ok, nil} -> {:error, :not_found}
      {:ok, value} -> {:ok, value}
      {:error, reason} -> 
        DeeperHub.Core.Logger.error("Erro ao recuperar do cache #{cache_key}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Recupera um valor do cache ou executa uma função se não encontrado.

  Este método utiliza o `Cachex.fetch/4` que é otimizado para evitar problemas
  de concorrência como "thundering herd" (quando múltiplas requisições
  tentam regenerar o mesmo valor em cache simultaneamente).

  ## Parâmetros

    * `key` - A chave do valor no cache
    * `fallback` - Função para executar se o valor não estiver em cache
    * `opts` - Opções adicionais

  ## Opções

    * `:ttl` - Tempo de vida em segundos para o valor, se for recuperado do fallback (padrão: #{@default_ttl})
    * `:namespace` - Namespace para a chave (opcional)
    * `:statistics` - Se deve coletar estatísticas sobre cache hits/misses (padrão: `true`)

  ## Retorno

    * `{:ok, value}` - Valor encontrado no cache ou gerado pelo fallback
    * `{:error, reason}` - Se ocorrer um erro durante o fallback

  ## Exemplos

      iex> DeeperHub.Core.Cache.get_or_store("user:123", fn -> fetch_user_from_db(123) end)
      {:ok, %{id: 123, name: "João"}}

  """
  @spec get_or_store(binary(), (-> any() | {:ok, any()} | {:error, any()}), keyword()) :: 
    {:ok, any()} | {:error, any()}
  def get_or_store(key, fallback, opts \\ []) do
    namespace = Keyword.get(opts, :namespace)
    ttl = Keyword.get(opts, :ttl, @default_ttl) * 1000 # Converte para milissegundos
    statistics = Keyword.get(opts, :statistics, true)
    
    cache_key = build_key(key, namespace)
    
    # Configura opções para o Cachex
    cache_opts = [
      ttl: ttl,
      statistics: statistics
    ]
    
    # Utiliza Cachex.fetch para buscar ou gerar o valor do cache
    # com proteção contra concorrência
    result = Cachex.fetch(@cache_name, cache_key, fn _key ->
      # Adapta a resposta do fallback para o formato esperado pelo Cachex
      try do
        case fallback.() do
          {:ok, value} -> {:commit, value}
          {:error, reason} = error -> 
            DeeperHub.Core.Logger.error("Erro na função fallback para #{cache_key}: #{inspect(reason)}")
            {:ignore, error}
          value -> {:commit, value}
        end
      rescue
        error ->
          DeeperHub.Core.Logger.error("Exceção na função fallback para #{cache_key}: #{inspect(error)}")
          {:ignore, {:error, error}}
      end
    end, cache_opts)
    
    # Processa o resultado
    case result do
      {:ok, value} -> {:ok, value}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Remove um valor do cache.

  ## Parâmetros

    * `key` - A chave a ser removida
    * `opts` - Opções adicionais

  ## Opções

    * `:namespace` - Namespace para a chave (opcional)

  ## Retorno

    * `:ok` - Operação concluída (independentemente de o valor existir ou não)
    * `{:error, reason}` - Se ocorrer um erro

  ## Exemplos

      iex> DeeperHub.Core.Cache.delete("user:123")
      :ok

      iex> DeeperHub.Core.Cache.delete("server:1", namespace: "servers")
      :ok

  """
  @spec delete(binary(), keyword()) :: :ok | {:error, any()}
  def delete(key, opts \\ []) do
    namespace = Keyword.get(opts, :namespace)
    
    cache_key = build_key(key, namespace)
    
    case Cachex.del(@cache_name, cache_key) do
      {:ok, _} -> :ok
      {:error, reason} -> 
        DeeperHub.Core.Logger.error("Erro ao remover do cache #{cache_key}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Limpa todos os valores do cache.

  ## Parâmetros

    * `opts` - Opções adicionais

  ## Opções

    * `:namespace` - Se especificado, limpa apenas os valores no namespace

  ## Retorno

    * `:ok` - Operação concluída com sucesso
    * `{:error, reason}` - Se ocorrer um erro

  ## Exemplos

      iex> DeeperHub.Core.Cache.clear()
      :ok

      iex> DeeperHub.Core.Cache.clear(namespace: "servers")
      :ok

  """
  @spec clear(keyword()) :: :ok | {:error, any()}
  def clear(opts \\ []) do
    namespace = Keyword.get(opts, :namespace)
    
    if namespace do
      # Limpa apenas um namespace específico
      prefix = "#{namespace}:"
      
      case Cachex.clear(@cache_name, fn key -> 
        is_binary(key) and String.starts_with?(key, prefix)
      end) do
        {:ok, _count} -> :ok
        {:error, reason} -> 
          DeeperHub.Core.Logger.error("Erro ao limpar namespace #{namespace} do cache: #{inspect(reason)}")
          {:error, reason}
      end
    else
      # Limpa todo o cache
      case Cachex.clear(@cache_name) do
        {:ok, _count} -> :ok
        {:error, reason} -> 
          DeeperHub.Core.Logger.error("Erro ao limpar todo o cache: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  @doc """
  Verifica se uma chave existe no cache.

  ## Parâmetros

    * `key` - A chave a ser verificada
    * `opts` - Opções adicionais

  ## Opções

    * `:namespace` - Namespace para a chave (opcional)

  ## Retorno

    * `{:ok, true}` - Se a chave existir
    * `{:ok, false}` - Se a chave não existir
    * `{:error, reason}` - Se ocorrer um erro

  ## Exemplos

      iex> DeeperHub.Core.Cache.exists?("user:123")
      {:ok, true}

      iex> DeeperHub.Core.Cache.exists?("unknown_key")
      {:ok, false}

  """
  @spec exists?(binary(), keyword()) :: {:ok, boolean()} | {:error, any()}
  def exists?(key, opts \\ []) do
    namespace = Keyword.get(opts, :namespace)
    
    cache_key = build_key(key, namespace)
    
    case Cachex.exists?(@cache_name, cache_key) do
      {:ok, exists} -> {:ok, exists}
      {:error, reason} -> 
        DeeperHub.Core.Logger.error("Erro ao verificar existência no cache #{cache_key}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Obtém estatísticas do cache.

  ## Retorno

    * `{:ok, stats}` - Um mapa com estatísticas do cache
    * `{:error, reason}` - Se ocorrer um erro

  ## Exemplos

      iex> DeeperHub.Core.Cache.stats()
      {:ok, %{
        size: 42,
        memory: 1024,
        hit_rate: 0.85,
        hits: 850,
        misses: 150
      }}

  """
  @spec stats() :: {:ok, map()} | {:error, any()}
  def stats do
    try do
      # Obtém tamanho do cache
      {:ok, size} = Cachex.size(@cache_name)
      
      # Obtém estatísticas do Cachex
      {:ok, memory} = cachex_memory(@cache_name)
      {:ok, stats} = Cachex.stats(@cache_name)
      
      # Calcula taxa de acertos
      hits = stats.hits || 0
      misses = stats.misses || 0
      total = hits + misses
      hit_rate = if total > 0, do: hits / total, else: 0
      
      # Obtém informações sobre expi
      expired_count = Cachex.inspect(@cache_name, {:expired, :count})
      expired_count = case expired_count do
        {:ok, count} -> count
        _ -> 0
      end
      
      {:ok, %{
        size: size,
        memory: memory,
        hit_rate: hit_rate,
        hits: hits,
        misses: misses,
        expired_count: expired_count
      }}
    rescue
      error ->
        DeeperHub.Core.Logger.error("Erro ao obter estatísticas do cache: #{inspect(error)}")
        {:error, error}
    end
  end
  
  @doc """
  Executa uma operação em transação para garantir atomicidade.
  
  As transações bloqueiam as chaves especificadas durante a execução da
  operação, garantindo que apenas um processo possa modificar essas chaves
  ao mesmo tempo, evitando condições de corrida.
  
  ## Parâmetros
  
    * `keys` - Lista de chaves a serem bloqueadas durante a transação
    * `operation` - Função a ser executada dentro da transação
    * `opts` - Opções adicionais
  
  ## Opções
  
    * `:namespace` - Namespace para as chaves (opcional)
  
  ## Retorno
  
    * `{:ok, result}` - Resultado da operação
    * `{:error, reason}` - Se ocorrer um erro
  
  ## Exemplos
  
      iex> DeeperHub.Core.Cache.transaction(["counter:1", "counter:2"], fn ->
      ...>   {:ok, val1} = DeeperHub.Core.Cache.increment("counter:1")
      ...>   {:ok, val2} = DeeperHub.Core.Cache.increment("counter:2")
      ...>   val1 + val2
      ...> end)
      {:ok, 3}
  
  """
  @spec transaction([binary()], (-> any()), keyword()) :: {:ok, any()} | {:error, any()}
  def transaction(keys, operation, opts \\ []) do
    namespace = Keyword.get(opts, :namespace)
    
    # Aplica o namespace às chaves, se fornecido
    cache_keys = Enum.map(keys, &build_key(&1, namespace))
    
    # Executa a operação em transação
    result = Cachex.transaction(@cache_name, cache_keys, fn _worker ->
      try do
        # Executa a operação dentro da transação
        operation.()
      rescue
        error ->
          DeeperHub.Core.Logger.error("Erro em transação de cache: #{inspect(error)}")
          {:error, error}
      end
    end)
    
    case result do
      {:ok, value} -> {:ok, value}
      {:error, reason} ->
        DeeperHub.Core.Logger.error("Erro ao executar transação: #{inspect(reason)}")
        {:error, reason}
    end
  end
  
  @doc """
  Cria um stream de entradas do cache para processamento eficiente.
  
  Isso permite processar grandes conjuntos de dados em cache sem
  carregá-los inteiramente na memória de uma vez.
  
  ## Parâmetros
  
    * `opts` - Opções para a consulta de stream
  
  ## Opções
  
    * `:namespace` - Filtrar apenas chaves com este namespace (opcional)
    * `:prefix` - Filtrar apenas chaves que comecem com este prefixo (opcional)
    * `:include_expired` - Se deve incluir entradas expiradas (padrão: `false`)
  
  ## Retorno
  
    * `{:ok, stream}` - Um stream de entradas do cache
    * `{:error, reason}` - Erro ao criar stream
  
  ## Exemplos
  
      iex> {:ok, stream} = DeeperHub.Core.Cache.stream(namespace: "user")
      iex> Enum.count(stream)
      42
  
  """
  @spec stream(keyword()) :: {:ok, Enumerable.t()} | {:error, any()}
  def stream(opts \\ []) do
    namespace = Keyword.get(opts, :namespace)
    prefix = Keyword.get(opts, :prefix)
    include_expired = Keyword.get(opts, :include_expired, false)
    
    # Construói a consulta para o stream
    query = if namespace || prefix do
      prefix_str = if namespace, do: "#{namespace}:", else: ""
      prefix_str = if prefix, do: prefix_str <> prefix, else: prefix_str
      
      # Construói a consulta para filtrar por prefixo
      q_opts = if String.length(prefix_str) > 0 do
        [where: fn {key, _val} -> is_binary(key) && String.starts_with?(key, prefix_str) end]
      else
        []
      end
      
      # Adiciona filtro de expi
      q_opts = if !include_expired, do: [{:where, &Cachex.Query.unexpired/1} | q_opts], else: q_opts
      
      # Construói a consulta final
      Cachex.Query.build(q_opts)
    else
      # Sem filtro de namespace/prefixo, apenas filtro de expi
      if include_expired do
        nil # Sem consulta, retorna tudo
      else
        Cachex.Query.build(where: &Cachex.Query.unexpired/1)
      end
    end
    
    # Cria o stream com a consulta
    case Cachex.stream(@cache_name, query) do
      {:ok, stream} -> {:ok, stream}
      {:error, reason} ->
        DeeperHub.Core.Logger.error("Erro ao criar stream de cache: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Incrementa um contador no cache.

  ## Parâmetros

    * `key` - A chave do contador
    * `amount` - Quantidade a incrementar (padrão: 1)
    * `opts` - Opções adicionais

  ## Opções

    * `:ttl` - Tempo de vida em segundos (padrão: #{@default_ttl})
    * `:namespace` - Namespace para a chave (opcional)

  ## Retorno

    * `{:ok, new_value}` - Valor após incremento
    * `{:error, reason}` - Se ocorrer um erro

  ## Exemplos

      iex> DeeperHub.Core.Cache.increment("visit_count:page1")
      {:ok, 1}

      iex> DeeperHub.Core.Cache.increment("visit_count:page1")
      {:ok, 2}

      iex> DeeperHub.Core.Cache.increment("api_calls", 5, namespace: "stats")
      {:ok, 5}

  """
  @spec increment(binary(), integer(), keyword()) :: {:ok, integer()} | {:error, any()}
  def increment(key, amount \\ 1, opts \\ []) do
    ttl = Keyword.get(opts, :ttl, @default_ttl) * 1000
    namespace = Keyword.get(opts, :namespace)
    
    cache_key = build_key(key, namespace)
    
    # Cachex.incr cria a chave se não existir, com valor inicial 0
    case Cachex.incr(@cache_name, cache_key, amount, ttl: ttl) do
      {:ok, value} -> {:ok, value}
      {:error, reason} -> 
        DeeperHub.Core.Logger.error("Erro ao incrementar contador #{cache_key}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Decrementa um contador no cache.

  ## Parâmetros

    * `key` - A chave do contador
    * `amount` - Quantidade a decrementar (padrão: 1)
    * `opts` - Opções adicionais

  ## Opções

    * `:ttl` - Tempo de vida em segundos (padrão: #{@default_ttl})
    * `:namespace` - Namespace para a chave (opcional)

  ## Retorno

    * `{:ok, new_value}` - Valor após decremento
    * `{:error, reason}` - Se ocorrer um erro

  ## Exemplos

      iex> DeeperHub.Core.Cache.decrement("active_users")
      {:ok, 41}

  """
  @spec decrement(binary(), integer(), keyword()) :: {:ok, integer()} | {:error, any()}
  def decrement(key, amount \\ 1, opts \\ []) do
    increment(key, -amount, opts)
  end

  # Funções privadas

  @doc """
  Executa uma consulta avançada no cache.
  
  Permite utilizar o módulo DeeperHub.Core.Cache.Queries.AdvancedQuery
  para realizar consultas sofisticadas no cache.
  
  ## Parâmetros
  
    * `query` - Consulta a ser executada (objeto Cachex.Query)
    * `opts` - Opções adicionais
  
  ## Opções
  
    * `:limit` - Limite máximo de resultados (padrão: `nil`, sem limite)
    * `:as_stream` - Se deve retornar como stream em vez de lista (padrão: `false`)
  
  ## Retorno
  
    * `{:ok, results}` - Resultados da consulta (lista ou stream)
    * `{:error, reason}` - Erro durante a consulta
  
  ## Exemplos
  
      iex> alias DeeperHub.Core.Cache.Queries.AdvancedQuery
      iex> query = AdvancedQuery.by_prefix("user:")
      iex> DeeperHub.Core.Cache.query(query)
      {:ok, [{"user:123", %{name: "João"}}]}
  
  """
  @spec query(Cachex.Query.t(), keyword()) :: {:ok, list() | Enumerable.t()} | {:error, any()}
  def query(query, opts \\ []) do
    limit = Keyword.get(opts, :limit)
    as_stream = Keyword.get(opts, :as_stream, false)
    
    # Inicia com o stream básico
    result = Cachex.stream(@cache_name, query)
    
    case result do
      {:ok, stream} ->
        # Aplica limite se fornecido
        stream = if limit, do: Stream.take(stream, limit), else: stream
        
        # Retorna como stream ou converte para lista
        if as_stream do
          {:ok, stream}
        else
          # Converte para lista
          entries = Enum.to_list(stream)
          {:ok, entries}
        end
        
      error -> error
    end
  end
  
  @doc """
  Salva o conteúdo do cache em disco.
  
  Utiliza o módulo DeeperHub.Core.Cache.Persistence.DiskStorage para
  persistir o conteúdo do cache em disco, permitindo que ele seja
  restaurado posteriormente, inclusive após reinicializações do sistema.
  
  ## Parâmetros
  
    * `opts` - Opções adicionais (repassadas para DiskStorage.save_to_disk/2)
  
  ## Retorno
  
    * `:ok` - Operação concluída com sucesso
    * `{:error, reason}` - Erro durante a operação
  
  ## Exemplos
  
      iex> DeeperHub.Core.Cache.save_to_disk()
      :ok
      
      iex> DeeperHub.Core.Cache.save_to_disk(path: "caminho/personalizado")
      :ok
  """
  @spec save_to_disk(keyword()) :: :ok | {:error, any()}
  def save_to_disk(opts \\ []) do
    alias DeeperHub.Core.Cache.Persistence.DiskStorage
    DiskStorage.save_to_disk(@cache_name, opts)
  end
  
  @doc """
  Restaura o conteúdo do cache a partir de um arquivo em disco.
  
  Utiliza o módulo DeeperHub.Core.Cache.Persistence.DiskStorage para
  restaurar o conteúdo do cache a partir de um arquivo previamente salvo.
  
  ## Parâmetros
  
    * `opts` - Opções adicionais (repassadas para DiskStorage.restore_from_disk/2)
  
  ## Retorno
  
    * `{:ok, count}` - Número de entradas restauradas
    * `{:error, reason}` - Erro durante a operação
  
  ## Exemplos
  
      iex> DeeperHub.Core.Cache.restore_from_disk()
      {:ok, 42}
  """
  @spec restore_from_disk(keyword()) :: {:ok, non_neg_integer()} | {:error, any()}
  def restore_from_disk(opts \\ []) do
    alias DeeperHub.Core.Cache.Persistence.DiskStorage
    DiskStorage.restore_from_disk(@cache_name, opts)
  end
  
  @doc """
  Configura backup automático do cache em disco.
  
  Agenda backups periódicos do conteúdo do cache em disco,
  permitindo recuperação em caso de falhas no sistema.
  
  ## Parâmetros
  
    * `interval_ms` - Intervalo em milissegundos entre backups
    * `opts` - Opções adicionais (repassadas para DiskStorage.schedule_automatic_backup/3)
  
  ## Retorno
  
    * `{:ok, pid}` - PID do processo de backup
    * `{:error, reason}` - Erro ao configurar backup
  
  ## Exemplos
  
      iex> DeeperHub.Core.Cache.schedule_automatic_backup(3_600_000) # A cada hora
      {:ok, #PID<0.123.0>}
  """
  @spec schedule_automatic_backup(non_neg_integer(), keyword()) :: {:ok, pid()} | {:error, any()}
  def schedule_automatic_backup(interval_ms \\ 3_600_000, opts \\ []) do
    alias DeeperHub.Core.Cache.Persistence.DiskStorage
    DiskStorage.schedule_automatic_backup(@cache_name, interval_ms, opts)
  end
  
  @doc """
  Recupera todas as chaves que correspondem a um determinado padrão.
  
  ## Parâmetros
  
    * `pattern` - Padrão para filtrar as chaves (string ou regex)
    * `opts` - Opções adicionais
  
  ## Opções
  
    * `:namespace` - Namespace para as chaves (opcional)
  
  ## Retorno
  
    * `{:ok, keys}` - Lista de chaves encontradas
    * `{:error, reason}` - Erro durante a operação
  
  ## Exemplos
  
      iex> DeeperHub.Core.Cache.get_keys_by_pattern("user:*")
      {:ok, ["user:123", "user:456"]}
  """
  @spec get_keys_by_pattern(binary() | Regex.t(), keyword()) :: {:ok, [binary()]} | {:error, any()}
  def get_keys_by_pattern(pattern, opts \\ []) do
    namespace = Keyword.get(opts, :namespace)
    
    # Constrói a consulta baseada no tipo do padrão
    query = cond do
      is_binary(pattern) -> 
        # Converte o padrão glob para regex
        # Converte o padrão original ou com prefixo de namespace
        prefixed_pattern = if namespace, do: "#{namespace}:#{pattern}", else: pattern
        regex = pattern_to_regex(prefixed_pattern)
        QueryBuilder.create(where: fn {key, _} -> is_binary(key) && Regex.match?(regex, key) end)
      
      match?(%Regex{}, pattern) ->
        # Já é um regex
        regex = if namespace do
          # Cria um novo regex combinando o namespace e o padrão existente
          ns_pattern = "^#{namespace}:.*"
          # Em vez de tentar acessar campos internos do Regex, usamos o source
          pattern_source = Regex.source(pattern)
          Regex.compile!("#{ns_pattern}.*#{pattern_source}")
        else
          pattern
        end
        QueryBuilder.create(where: fn {key, _} -> is_binary(key) && Regex.match?(regex, key) end)
      
      true ->
        raise ArgumentError, "pattern deve ser uma string ou regex"
    end
    
    # Executa a consulta e extrai as chaves
    case Cachex.stream(@cache_name, query) do
      {:ok, stream} ->
        keys = stream
          |> Stream.map(fn {key, _} -> key end)
          |> Enum.to_list()
        {:ok, keys}
      
      error -> error
    end
  end

  # Constrói a chave completa com namespace, se fornecido
  @spec build_key(binary(), binary() | nil) :: binary()
  defp build_key(key, nil), do: key
  defp build_key(key, namespace), do: "#{namespace}:#{key}"
  
  # Converte um padrão glob ("*", "?") para uma expressão regular
  defp pattern_to_regex(pattern) do
    pattern
    |> String.replace(~r/\./, "\\\\.")
    |> String.replace(~r/\*/, ".*")
    |> String.replace(~r/\?/, ".")
    |> then(fn p -> "^#{p}$" end)
    |> Regex.compile!()
  end

  # Funções wrapper para Cachex para evitar avisos de compilação

  @doc false
  defp cachex_memory(cache_name) do
    try do
      # Chama a função usando apply para evitar warnings
      apply(Cachex, :memory, [cache_name])
    rescue
      e -> 
        DeeperHub.Core.Logger.error("Erro ao obter uso de memória do cache: #{inspect(e)}")
        {:error, :memory_unavailable}
    end
  end
end
