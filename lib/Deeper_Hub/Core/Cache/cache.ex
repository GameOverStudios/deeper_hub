defmodule Deeper_Hub.Core.Cache do
  @moduledoc """
  Módulo para gerenciamento de cache utilizando Cachex.
  
  Este módulo fornece uma interface simplificada para operações de cache,
  permitindo armazenar e recuperar dados em memória de forma eficiente.
  """
  
  alias Deeper_Hub.Core.Logger
  
  @cache_name :deeper_hub_cache
  @default_ttl :timer.minutes(10) # 10 minutos por padrão
  
  @doc """
  Retorna o nome do cache utilizado pela aplicação.
  
  ## Retorno
  
    - Nome do cache como atom
  """
  def cache_name, do: @cache_name
  
  @doc """
  Inicia o cache como parte da árvore de supervisão.
  
  ## Retorno
  
    - Especificação para o supervisor
  """
  def child_spec(_opts) do
    %{
      id: __MODULE__,
      start: {Cachex, :start_link, [@cache_name, [
        # Configurações do cache
        expiration: [
          # Configura a expiração padrão para entradas no cache
          default: @default_ttl,
          # Verifica entradas expiradas a cada minuto
          interval: :timer.minutes(1)
        ],
        # Habilita estatísticas para telemetria
        stats: true
      ]]}
    }
  end
  
  @doc """
  Armazena um valor no cache.
  
  ## Parâmetros
  
    - `key`: A chave para armazenar o valor
    - `value`: O valor a ser armazenado
    - `ttl`: Tempo de vida em milissegundos (opcional)
  
  ## Retorno
  
    - `{:ok, true}` se o valor for armazenado com sucesso
    - `{:error, reason}` em caso de falha
  """
  @spec put(any(), any(), integer() | nil) :: {:ok, boolean()} | {:error, any()}
  def put(key, value, ttl \\ @default_ttl) do
    Logger.debug("Armazenando valor no cache", %{
      module: __MODULE__,
      key: key,
      ttl: ttl
    })
    
    # Publica evento no EventBus se estiver disponível
    try do
      if Code.ensure_loaded?(Deeper_Hub.Core.EventBus) do
        Deeper_Hub.Core.EventBus.publish(:cache_put, %{
          key: key,
          ttl: ttl,
          timestamp: :os.system_time(:millisecond)
        })
      end
    rescue
      _ -> :ok
    end
    
    Cachex.put(@cache_name, key, value, ttl: ttl)
  end
  
  @doc """
  Recupera um valor do cache.
  
  ## Parâmetros
  
    - `key`: A chave do valor a ser recuperado
  
  ## Retorno
  
    - `{:ok, value}` se o valor for encontrado
    - `{:ok, nil}` se o valor não for encontrado
    - `{:error, reason}` em caso de falha
  """
  @spec get(any()) :: {:ok, any()} | {:error, any()}
  def get(key) do
    Logger.debug("Recuperando valor do cache", %{module: __MODULE__, key: key})
    result = Cachex.get(@cache_name, key)
    
    # Publica evento no EventBus se estiver disponível
    try do
      if Code.ensure_loaded?(Deeper_Hub.Core.EventBus) do
        case result do
          {:ok, nil} ->
            # Cache miss
            Logger.debug("Cache miss", %{module: __MODULE__, key: key})
            Deeper_Hub.Core.EventBus.publish(:cache_miss, %{
              key: key,
              timestamp: :os.system_time(:millisecond)
            })
            
          {:ok, _value} ->
            # Cache hit
            Logger.debug("Cache hit", %{module: __MODULE__, key: key})
            Deeper_Hub.Core.EventBus.publish(:cache_hit, %{
              key: key,
              timestamp: :os.system_time(:millisecond)
            })
            
          _ -> :ok
        end
      end
    rescue
      _ -> :ok
    end
    
    result
  end
  
  @doc """
  Verifica se uma chave existe no cache.
  
  ## Parâmetros
  
    - `key`: A chave a ser verificada
  
  ## Retorno
  
    - `{:ok, true}` se a chave existir
    - `{:ok, false}` se a chave não existir
    - `{:error, reason}` em caso de falha
  """
  def exists?(key) do
    Cachex.exists?(@cache_name, key)
  end
  
  @doc """
  Remove um valor do cache.
  
  ## Parâmetros
  
    - `key`: A chave do valor a ser removido
  
  ## Retorno
  
    - `{:ok, true}` se o valor for removido com sucesso
    - `{:ok, false}` se o valor não existir
    - `{:error, reason}` em caso de falha
  """
  @spec del(any()) :: {:ok, boolean()} | {:error, any()}
  def del(key) do
    Logger.debug("Removendo valor do cache", %{module: __MODULE__, key: key})
    result = Cachex.del(@cache_name, key)
    
    # Publica evento no EventBus se estiver disponível
    try do
      if Code.ensure_loaded?(Deeper_Hub.Core.EventBus) do
        Deeper_Hub.Core.EventBus.publish(:cache_delete, %{
          key: key,
          timestamp: :os.system_time(:millisecond)
        })
      end
    rescue
      _ -> :ok
    end
    
    result
  end
  
  @doc """
  Limpa todo o cache, removendo todas as entradas.
  
  ## Retorno
  
    - `{:ok, integer}` com o número de chaves removidas
    - `{:error, reason}` em caso de falha
  """
  @spec clear() :: {:ok, integer()} | {:error, any()}
  def clear do
    Logger.debug("Limpando todo o cache", %{module: __MODULE__})
    result = Cachex.clear(@cache_name)
    
    # Publica evento no EventBus se estiver disponível
    try do
      if Code.ensure_loaded?(Deeper_Hub.Core.EventBus) do
        Deeper_Hub.Core.EventBus.publish(:cache_clear, %{
          timestamp: :os.system_time(:millisecond)
        })
      end
    rescue
      _ -> :ok
    end
    
    result
  end
  
  @doc """
  Obtém estatísticas do cache.
  
  ## Retorno
  
    - `{:ok, stats}` com as estatísticas do cache
    - `{:error, reason}` em caso de falha
  """
  def stats do
    Logger.debug("Obtendo estatísticas do cache", %{module: __MODULE__})
    
    # Usamos nosso hook personalizado para obter estatísticas
    Deeper_Hub.Core.Cache.StatsHook.get_stats(@cache_name)
  end
  
  @doc """
  Executa uma função e armazena o resultado no cache.
  Se a chave já existir no cache, retorna o valor armazenado.
  
  ## Parâmetros
  
    - `key`: A chave para armazenar o resultado
    - `ttl`: Tempo de vida em milissegundos (opcional)
    - `fun`: A função a ser executada se o valor não estiver no cache
  
  ## Retorno
  
    - `{:ok, value}` onde value é o valor recuperado ou calculado
    - `{:error, reason}` em caso de falha
  """
  def fetch(key, ttl \\ @default_ttl, fun) when is_function(fun, 0) do
    case get(key) do
      {:ok, nil} ->
        # Valor não encontrado no cache, executa a função
        Logger.debug("Cache miss, executando função", %{
          module: __MODULE__,
          key: key
        })
        
        result = fun.()
        
        # Armazena o resultado no cache
        {:ok, true} = put(key, result, ttl)
        
        {:ok, result}
      
      {:ok, value} ->
        # Valor encontrado no cache
        Logger.debug("Cache hit", %{
          module: __MODULE__,
          key: key
        })
        
        {:ok, value}
      
      error ->
        # Erro ao acessar o cache
        Logger.error("Erro ao acessar cache", %{
          module: __MODULE__,
          key: key,
          error: error
        })
        
        error
    end
  end
end
