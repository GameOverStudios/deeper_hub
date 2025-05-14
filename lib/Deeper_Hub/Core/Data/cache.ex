defmodule Deeper_Hub.Core.Data.Cache do
  @moduledoc """
  Módulo responsável pelo cache de consultas ao Mnesia.
  Armazena resultados de consultas frequentes para reduzir a carga no banco de dados.
  
  Integra-se com o Repository para interceptar e cachear consultas.
  """
  
  use GenServer
  alias Deeper_Hub.Core.Logger
  
  # Tempo padrão de expiração de cache (em ms)
  @default_ttl 60_000
  
  # Estrutura de cache
  # %{
  #   {table_name, operation, key} => %{
  #     value: cached_value,
  #     expires_at: timestamp
  #   }
  # }
  
  # API pública
  
  @doc """
  Inicia o servidor de cache.
  
  ## Parâmetros
  
    - `opts`: Opções de inicialização (opcional)
  
  ## Retorno
  
    - `{:ok, pid}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Busca um valor no cache.
  
  ## Parâmetros
  
    - `table_name`: Nome da tabela
    - `operation`: Operação (:find, :all, :match)
    - `key`: Chave do registro ou parâmetros da consulta
    
  ## Retorno
  
    - `{:ok, value}` se o valor estiver no cache
    - `:not_found` se o valor não estiver no cache
  """
  @spec get(atom(), atom(), any()) :: {:ok, any()} | :not_found
  def get(table_name, operation, key) do
    GenServer.call(__MODULE__, {:get, {table_name, operation, key}})
  end
  
  @doc """
  Armazena um valor no cache.
  
  ## Parâmetros
  
    - `table_name`: Nome da tabela
    - `operation`: Operação (:find, :all, :match)
    - `key`: Chave do registro ou parâmetros da consulta
    - `value`: Valor a ser armazenado
    - `ttl`: Tempo de vida do cache em ms (opcional)
  
  ## Retorno
  
    - `:ok`
  """
  @spec put(atom(), atom(), any(), any(), non_neg_integer()) :: :ok
  def put(table_name, operation, key, value, ttl \\ @default_ttl) do
    GenServer.cast(__MODULE__, {:put, {table_name, operation, key}, value, ttl})
  end
  
  @doc """
  Invalida uma entrada específica do cache.
  
  ## Parâmetros
  
    - `table_name`: Nome da tabela
    - `operation`: Operação (opcional, se nil invalida todas as operações)
    - `key`: Chave do registro (opcional, se nil invalida todas as chaves)
  
  ## Retorno
  
    - `:ok`
  """
  @spec invalidate(atom(), atom() | nil, any() | nil) :: :ok
  def invalidate(table_name, operation \\ nil, key \\ nil) do
    GenServer.cast(__MODULE__, {:invalidate, table_name, operation, key})
  end
  
  @doc """
  Limpa todo o cache.
  
  ## Retorno
  
    - `:ok`
  """
  @spec clear() :: :ok
  def clear do
    GenServer.cast(__MODULE__, :clear)
  end
  
  @doc """
  Retorna estatísticas do cache.
  
  ## Retorno
  
    - Mapa com estatísticas do cache (tamanho, etc)
  """
  @spec stats() :: map()
  def stats do
    GenServer.call(__MODULE__, :stats)
  end
  
  @doc """
  Reseta as estatísticas do cache (hits, misses).
  
  ## Retorno
  
    - `:ok`
  """
  @spec reset_stats() :: :ok
  def reset_stats do
    GenServer.cast(__MODULE__, :reset_stats)
  end
  
  # Callbacks do GenServer
  
  @impl true
  def init(_opts) do
    Logger.info("Iniciando sistema de cache para consultas Mnesia", %{module: __MODULE__})
    # Inicializa o estado com um mapa vazio e estatísticas
    {:ok, %{cache: %{}, hits: 0, misses: 0}}
  end
  
  @impl true
  def handle_call({:get, cache_key}, _from, state) do
    case Map.get(state.cache, cache_key) do
      nil ->
        # Cache miss
        Logger.debug("Cache miss para #{inspect(cache_key)}", %{module: __MODULE__})
        new_state = %{state | misses: state.misses + 1}
        {:reply, :not_found, new_state}
        
      %{value: :not_found, expires_at: expires_at} ->
        # Caso especial para valores :not_found armazenados no cache
        if :os.system_time(:millisecond) < expires_at do
          # Cache hit
          Logger.debug("Cache hit para #{inspect(cache_key)}", %{module: __MODULE__})
          new_state = %{state | hits: state.hits + 1}
          {:reply, :not_found, new_state}
        else
          # Cache expirado
          Logger.debug("Cache expirado para #{inspect(cache_key)}", %{module: __MODULE__})
          new_cache = Map.delete(state.cache, cache_key)
          new_state = %{state | cache: new_cache, misses: state.misses + 1}
          {:reply, :not_found, new_state}
        end
        
      %{value: value, expires_at: expires_at} ->
        if :os.system_time(:millisecond) < expires_at do
          # Cache hit
          Logger.debug("Cache hit para #{inspect(cache_key)}", %{module: __MODULE__})
          new_state = %{state | hits: state.hits + 1}
          {:reply, {:ok, value}, new_state}
        else
          # Cache expirado
          Logger.debug("Cache expirado para #{inspect(cache_key)}", %{module: __MODULE__})
          new_cache = Map.delete(state.cache, cache_key)
          new_state = %{state | cache: new_cache, misses: state.misses + 1}
          {:reply, :not_found, new_state}
        end
    end
  end
  
  @impl true
  def handle_call(:stats, _from, state) do
    stats = %{
      size: map_size(state.cache),
      hits: state.hits,
      misses: state.misses,
      hit_rate: calculate_hit_rate(state.hits, state.misses)
    }
    
    {:reply, stats, state}
  end
  
  @impl true
  def handle_cast({:put, cache_key, value, ttl}, state) do
    expires_at = :os.system_time(:millisecond) + ttl
    Logger.debug("Armazenando em cache: #{inspect(cache_key)}", %{module: __MODULE__})
    new_cache = Map.put(state.cache, cache_key, %{value: value, expires_at: expires_at})
    {:noreply, %{state | cache: new_cache}}
  end
  
  @impl true
  def handle_cast({:invalidate, table_name, operation, key}, state) do
    # Filtra as chaves do cache que correspondem aos critérios
    {invalidated, new_cache} = 
      Enum.reduce(state.cache, {0, %{}}, fn
        {{^table_name, op, k}, _value}, {count, acc} when operation == nil or operation == op ->
          if key == nil or key == k do
            Logger.debug("Invalidando cache para #{table_name}/#{op}/#{inspect(k)}", %{module: __MODULE__})
            {count + 1, acc}
          else
            {count, Map.put(acc, {table_name, op, k}, Map.get(state.cache, {table_name, op, k}))}
          end
        
        {cache_key, cache_value}, {count, acc} ->
          {count, Map.put(acc, cache_key, cache_value)}
      end)
    
    Logger.info("Invalidadas #{invalidated} entradas de cache para tabela #{table_name}", %{module: __MODULE__})
    {:noreply, %{state | cache: new_cache}}
  end
  
  @impl true
  def handle_cast(:clear, state) do
    Logger.info("Limpando todo o cache (#{map_size(state.cache)} entradas)", %{module: __MODULE__})
    {:noreply, %{state | cache: %{}}}
  end
  
  @impl true
  def handle_cast(:reset_stats, state) do
    Logger.info("Resetando estatísticas de cache", %{module: __MODULE__})
    {:noreply, %{state | hits: 0, misses: 0}}
  end
  
  # Funções privadas
  
  defp calculate_hit_rate(hits, misses) do
    total = hits + misses
    
    if total > 0 do
      hits / total
    else
      0.0
    end
  end
end
