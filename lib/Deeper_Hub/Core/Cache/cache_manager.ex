defmodule Deeper_Hub.Core.Cache.CacheManager do
  @moduledoc """
  Módulo responsável pelo gerenciamento de cache no sistema Deeper_Hub.
  
  Este módulo fornece uma interface para operações de cache usando Cachex,
  permitindo armazenar, recuperar e invalidar dados em cache de forma eficiente.
  Também fornece métricas e telemetria para monitoramento do desempenho do cache.
  """

  use GenServer
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Telemetry.TelemetryEvents
  alias Deeper_Hub.Core.EventBus.EventDefinitions

  # Nome do cache Cachex
  @cache_name :repository_cache
  
  # Tempo de vida padrão para itens do cache (em milissegundos)
  # 5 minutos = 5 * 60 * 1000 = 300000 ms
  @default_ttl 300_000

  # Nome do processo GenServer
  @server __MODULE__

  @doc """
  Inicializa o cache do repositório usando Cachex.

  Esta função inicia o cache Cachex se ele ainda não estiver em execução.
  É seguro chamar esta função múltiplas vezes.

  ## Retorno

  - `:ok` se a inicialização for bem-sucedida
  """
  @spec initialize_cache() :: :ok
  def initialize_cache do
    try do
      # Opções do Cachex: TTL padrão e limpeza automática de itens expirados
      options = [
        # Define o TTL padrão para todos os itens do cache
        ttl: true,
        # Define o intervalo de limpeza de itens expirados (a cada 1 minuto)
        ttl_interval: 60_000
      ]
      
      case Cachex.start(@cache_name, options) do
        {:ok, _pid} -> 
          Logger.debug("Cache Cachex iniciado com sucesso", %{module: __MODULE__})
          :ok
        {:error, {:already_started, _pid}} -> 
          Logger.debug("Cache Cachex já estava em execução", %{module: __MODULE__})
          :ok
        {:error, error} ->
          Logger.warning("Falha ao inicializar cache Cachex: #{inspect(error)}", %{module: __MODULE__})
          :error
      end
    rescue
      error ->
        Logger.warning("Falha ao inicializar cache Cachex: #{inspect(error)}", %{module: __MODULE__})
        :error
    end
  end

  # Inicializa o cache quando o módulo é carregado
  @cache_initialized_key {__MODULE__, :cache_initialized}

  # Move a inicialização para uma função que será chamada no carregamento
  # em vez de executar código no momento da compilação

  @doc """
  Inicia o GenServer do cache.

  Esta função é chamada pela árvore de supervisão para iniciar o processo
  que gerencia o cache.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, Keyword.put(opts, :name, @server))
  end

  @impl true
  def init(:ok) do
    # Inicializa o cache quando o GenServer inicia
    :ok = initialize_cache()

    # Não precisamos mais verificar periodicamente o cache com Cachex

    {:ok, %{initialized: true}}
  end

  # Chamado quando o módulo é carregado
  @on_load :init_cache

  @doc """
  Inicializa o cache quando o módulo é carregado.

  Esta função é chamada automaticamente quando o módulo é carregado.
  Ela garante que o GenServer esteja em execução e que o cache esteja inicializado.
  """
  def init_cache do
    # Inicializa o valor em persistent_term
    :persistent_term.put(@cache_initialized_key, false)

    # Não inicia o GenServer aqui, deixa isso para a árvore de supervisão
    # O GenServer será iniciado pela árvore de supervisão da aplicação
    # Isso evita o erro de "already started"

    # Retorna :ok imediatamente para não bloquear a compilação
    :ok
  end

  @impl true
  def handle_info(:ensure_cache_initialized, state) do
    # Verifica e repara o cache se necessário
    :ok = ensure_cache_initialized()

    # Agenda a próxima verificação
    Process.send_after(self(), :ensure_cache_initialized, 60_000)

    {:noreply, state}
  end

  @doc """
  Limpa o cache completamente.
  """
  def clear_cache do
    # Garante que o cache está inicializado antes de qualquer operação
    ensure_cache_initialized()

    # Limpa o cache usando Cachex.clear
    case Cachex.clear(@cache_name) do
      {:ok, _} -> :ok
      _ -> :error
    end
  end

  @doc """
  Limpa o cache de uma tabela específica.

  ## Parâmetros

    - `schema`: O módulo do schema Ecto para o qual limpar o cache

  ## Retorno

    - `:ok` se a operação for bem-sucedida
    - `:error` em caso de falha
  """
  @spec clear_schema_cache(module()) :: :ok | :error
  def clear_schema_cache(schema) do
    # Garante que o cache está inicializado
    ensure_cache_initialized()

    # Cria um padrão para corresponder a todas as chaves do schema
    schema_pattern = "#{inspect(schema)}_*"
    
    # Remove todas as chaves que correspondem ao padrão usando expressão regular
    # Como clear_matched não existe, usamos stream + clear para limpar as chaves que correspondem ao padrão
    try do
      # Usamos uma expressão regular para corresponder às chaves
      regex = Regex.compile!(schema_pattern)
      
      # Contamos quantas chaves foram removidas
      count = Cachex.stream!(@cache_name, [batch_size: 100])
      |> Stream.filter(fn {key, _value} -> 
        is_binary(key) && Regex.match?(regex, key)
      end)
      |> Stream.map(fn {key, _value} -> 
        Cachex.del!(@cache_name, key)
        1
      end)
      |> Enum.sum()
      
      {:ok, count}
    rescue
      e -> {:error, e}
    end
    |> case do
      {:ok, _count} -> 
        Logger.debug("Cache limpo para o schema #{inspect(schema)}", %{module: __MODULE__})
        EventDefinitions.emit(
          EventDefinitions.cache_update(),
          %{schema: schema, action: :clear},
          source: "#{__MODULE__}"
        )
        :ok
      error -> 
        Logger.error("Falha ao limpar cache para o schema #{inspect(schema)}: #{inspect(error)}", %{module: __MODULE__})
        :error
    end
  end

  @doc """
  Obtém estatísticas do cache.

  ## Retorno

    - Um mapa com as estatísticas do cache (hits, misses, hit_rate)
  """
  @spec get_cache_stats() :: map()
  def get_cache_stats do
    # Obtém as estatísticas do cache usando Cachex.stats
    case Cachex.stats(@cache_name) do
      {:ok, stats} ->
        hits = stats.hits
        misses = stats.misses
        total = hits + misses
        hit_rate = if total > 0, do: hits / total, else: 0.0

        %{
          hits: hits,
          misses: misses,
          hit_rate: hit_rate
        }
      _ ->
        %{
          hits: 0,
          misses: 0,
          hit_rate: 0.0
        }
    end
  end

  # Funções privadas para manipulação do cache
  defp cache_key(schema, id), do: "#{inspect(schema)}_#{id}"

  @doc """
  Busca um valor no cache.

  ## Parâmetros

    - `schema`: O módulo do schema Ecto
    - `id`: O ID do registro a ser buscado

  ## Retorno

    - `{:ok, value}` se o valor for encontrado no cache
    - `:not_found` se o valor não for encontrado no cache
  """
  @spec get_from_cache(module(), term()) :: {:ok, term()} | :not_found
  def get_from_cache(schema, id) do
    # Busca o valor no cache usando Cachex.get
    key = cache_key(schema, id)
    result = case Cachex.get(@cache_name, key) do
      {:ok, nil} -> 
        # Emite evento de telemetria para cache miss
        TelemetryEvents.execute_cache_miss(
          %{count: 1},
          %{schema: schema, key: key}
        )
        
        # Emite evento para EventBus
        EventDefinitions.emit(
          EventDefinitions.cache_miss(),
          %{schema: schema, key: key},
          source: "#{__MODULE__}"
        )
        :not_found
      {:ok, value} -> 
        # Emite evento de telemetria para cache hit
        TelemetryEvents.execute_cache_hit(
          %{count: 1},
          %{schema: schema, key: key}
        )
        
        # Emite evento para EventBus
        EventDefinitions.emit(
          EventDefinitions.cache_hit(),
          %{schema: schema, key: key},
          source: "#{__MODULE__}"
        )
        {:ok, value}
      _ -> 
        # Emite evento de telemetria para cache miss (erro)
        TelemetryEvents.execute_cache_miss(
          %{count: 1},
          %{schema: schema, key: key, reason: :error}
        )
        :not_found
    end
    
    result
  end

  @doc """
  Busca múltiplos valores no cache de uma vez.

  ## Parâmetros

    - `schema`: O módulo do schema Ecto
    - `ids`: Lista de IDs dos registros a serem buscados

  ## Retorno

    - Um mapa onde as chaves são os IDs e os valores são os registros encontrados
    - Registros não encontrados no cache não serão incluídos no mapa resultante
  """
  @spec get_many_from_cache(module(), [term()]) :: %{optional(term()) => term()}
  def get_many_from_cache(schema, ids) when is_list(ids) do
    # Garante que o cache está inicializado
    ensure_cache_initialized()

    # Converte os IDs em chaves de cache
    keys = Enum.map(ids, fn id -> cache_key(schema, id) end)
    
    # Como get_many não existe, usamos múltiplas chamadas a get
    results = Enum.map(keys, fn key ->
      case Cachex.get(@cache_name, key) do
        {:ok, value} -> {key, value}
        _ -> {key, nil}
      end
    end)
    
    # Processamos os resultados
    # Filtra os resultados para remover valores nulos e converte de volta para o formato {id => valor}
    results
    |> Enum.filter(fn {_key, value} -> value != nil end)
    |> Enum.map(fn {key, value} ->
      # Extrai o ID da chave do cache
      id = extract_id_from_key(key, schema)
      {id, value}
    end)
    |> Map.new()
  end
  
  # Função auxiliar para extrair o ID da chave do cache
  defp extract_id_from_key(key, schema) do
    schema_str = "#{inspect(schema)}_"
    String.replace(key, schema_str, "") |> String.to_atom()
  rescue
    _ -> key
  end

  @doc """
  Garante que o cache Cachex está inicializado.

  Esta função pode ser chamada em qualquer momento para verificar e, se necessário,
  iniciar o cache Cachex.

  ## Retorno

    - `:ok` se o cache estiver inicializado corretamente
  """
  @spec ensure_cache_initialized() :: :ok
  def ensure_cache_initialized do
    # Verifica se o cache já foi inicializado para evitar operações redundantes
    case :persistent_term.get(@cache_initialized_key, false) do
      true ->
        # Cache já foi inicializado, verifica se o cache ainda existe
        # Usamos Cachex.stats para verificar se o cache está em execução
        case Cachex.stats(@cache_name) do
          {:ok, _stats} -> 
            # Cache existe, tudo ok
            :ok
          {:error, _} -> 
            # Cache não existe mais, precisa reinicializar
            initialize_cache()
            :persistent_term.put(@cache_initialized_key, true)
            :ok
        end

      false ->
        # Cache ainda não foi inicializado, inicializa agora
        initialize_cache()
        :persistent_term.put(@cache_initialized_key, true)
        :ok
    end
  end

  @doc """
  Armazena um valor no cache.

  ## Parâmetros

    - `schema`: O módulo do schema Ecto
    - `id`: O ID do registro
    - `value`: O valor a ser armazenado
    - `ttl`: Tempo de vida em milissegundos (opcional)

  ## Retorno

    - `:ok` se o valor for armazenado com sucesso
    - `:error` em caso de falha
  """
  @spec put_in_cache(module(), term(), term(), integer() | nil) :: :ok | :error
  def put_in_cache(schema, id, value, ttl \\ nil) do
    # Garante que o cache está inicializado
    ensure_cache_initialized()

    # Armazena o valor no cache usando Cachex.put
    key = cache_key(schema, id)
    ttl = ttl || @default_ttl
    
    # Início da medição de tempo para telemetria
    start_time = System.monotonic_time()
    
    result = case Cachex.put(@cache_name, key, value, ttl: ttl) do
      {:ok, true} -> 
        # Emite evento de telemetria para atualização de cache
        TelemetryEvents.execute_cache_update(
          %{count: 1, duration: System.monotonic_time() - start_time},
          %{schema: inspect(schema), id: id, key: key, ttl: ttl}
        )
        # Emite evento para EventBus
        EventDefinitions.emit(
          EventDefinitions.cache_update(),
          %{schema: schema, id: id, key: key, action: :put, ttl: ttl},
          source: "#{__MODULE__}"
        )
        :ok
      _ -> 
        # Emite evento de telemetria para erro na atualização de cache
        TelemetryEvents.execute_cache_update(
          %{count: 1, duration: System.monotonic_time() - start_time},
          %{schema: inspect(schema), id: id, key: key, ttl: ttl, status: :error}
        )
        :error
    end
    
    result
  end

  @doc """
  Invalida (remove) um valor do cache.

  ## Parâmetros

    - `schema`: O módulo do schema Ecto
    - `id`: O ID do registro a ser removido

  ## Retorno

    - `:ok` se o valor for removido com sucesso ou não existir
    - `:error` em caso de falha
  """
  @spec invalidate_cache(module(), term()) :: :ok | :error
  def invalidate_cache(schema, id) do
    # Garante que o cache está inicializado
    ensure_cache_initialized()

    # Remove o valor do cache usando Cachex.del
    key = cache_key(schema, id)
    
    # Início da medição de tempo para telemetria
    start_time = System.monotonic_time()
    
    result = case Cachex.del(@cache_name, key) do
      {:ok, _} -> 
        # Emite evento de telemetria para remoção de cache
        TelemetryEvents.execute_cache_update(
          %{count: 1, duration: System.monotonic_time() - start_time},
          %{schema: inspect(schema), id: id, key: key, operation: :remove}
        )
        :ok
      _ -> 
        # Emite evento de telemetria para erro na remoção de cache
        TelemetryEvents.execute_cache_update(
          %{count: 1, duration: System.monotonic_time() - start_time},
          %{schema: inspect(schema), id: id, key: key, operation: :remove, status: :error}
        )
        :error
    end
    
    result
  end

  @doc """
  Obtém um valor do cache pelo nome do cache e chave.
  
  ## Parâmetros
  
  - `cache_name`: Nome do cache (atom)
  - `key`: Chave do valor no cache
  
  ## Retorno
  
  - `{:ok, value}` se o valor for encontrado
  - `{:ok, nil}` se o valor não for encontrado
  - `{:error, reason}` em caso de erro
  """
  @spec get(atom(), any()) :: {:ok, any()} | {:error, any()}
  def get(cache_name, key) do
    # Garante que o cache está inicializado
    ensure_cache_initialized()
    
    # Início da medição de tempo para telemetria
    start_time = System.monotonic_time()
    
    # Obtém o valor do cache usando Cachex.get
    result = Cachex.get(cache_name, key)
    
    # Cálculo da duração para telemetria
    end_time = System.monotonic_time()
    duration = end_time - start_time
    
    # Emite evento de telemetria baseado no resultado
    case result do
      {:ok, nil} ->
        # Cache miss
        TelemetryEvents.execute_cache_miss(
          %{duration: duration, count: 1},
          %{cache: cache_name, key: key, module: __MODULE__}
        )
        
        # Emite evento para o EventBus
        EventDefinitions.emit(
          EventDefinitions.cache_miss(),
          %{cache: cache_name, key: key},
          source: "#{__MODULE__}"
        )
        
        {:ok, nil}
        
      {:ok, _value} ->
        # Cache hit
        TelemetryEvents.execute_cache_hit(
          %{duration: duration, count: 1},
          %{cache: cache_name, key: key, module: __MODULE__}
        )
        
        # Emite evento para o EventBus
        EventDefinitions.emit(
          EventDefinitions.cache_hit(),
          %{cache: cache_name, key: key},
          source: "#{__MODULE__}"
        )
        
        result
        
      {:error, reason} ->
        Logger.warning("Erro ao obter valor do cache", %{
          module: __MODULE__,
          cache: cache_name,
          key: key,
          error: reason
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Armazena um valor no cache pelo nome do cache e chave.
  
  ## Parâmetros
  
  - `cache_name`: Nome do cache (atom)
  - `key`: Chave do valor no cache
  - `value`: Valor a ser armazenado
  - `opts`: Opções adicionais
    - `:ttl`: Tempo de vida do valor em milissegundos (opcional)
  
  ## Retorno
  
  - `:ok` se o valor for armazenado com sucesso
  - `{:error, reason}` em caso de erro
  """
  @spec put(atom(), any(), any(), keyword()) :: :ok | {:error, any()}
  def put(cache_name, key, value, opts \\ []) do
    # Garante que o cache está inicializado
    ensure_cache_initialized()
    
    # Obtém o TTL das opções ou usa o padrão
    ttl = Keyword.get(opts, :ttl, @default_ttl)
    
    # Início da medição de tempo para telemetria
    start_time = System.monotonic_time()
    
    # Armazena o valor no cache usando Cachex.put
    result = Cachex.put(cache_name, key, value, ttl: ttl)
    
    # Cálculo da duração para telemetria
    end_time = System.monotonic_time()
    duration = end_time - start_time
    
    # Emite evento de telemetria
    TelemetryEvents.execute_cache_update(
      %{duration: duration, count: 1},
      %{cache: cache_name, key: key, module: __MODULE__}
    )
    
    # Emite evento para o EventBus
    EventDefinitions.emit(
      EventDefinitions.cache_update(),
      %{cache: cache_name, key: key},
      source: "#{__MODULE__}"
    )
    
    case result do
      {:ok, true} -> :ok
      {:ok, false} -> :ok  # Também consideramos sucesso se o valor não foi alterado
      {:error, reason} ->
        Logger.warning("Erro ao armazenar valor no cache", %{
          module: __MODULE__,
          cache: cache_name,
          key: key,
          error: reason
        })
        
        {:error, reason}
    end
  end
end
