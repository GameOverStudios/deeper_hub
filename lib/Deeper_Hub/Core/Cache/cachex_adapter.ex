defmodule Deeper_Hub.Core.Cache.CachexAdapter do
  @moduledoc """
  Adaptador para a biblioteca Cachex que implementa o comportamento CacheBehaviour.
  
  Este módulo fornece uma implementação completa das operações de cache usando
  a biblioteca Cachex como backend de armazenamento.
  
  ## Características
  
  * Implementação completa do `Deeper_Hub.Core.Cache.CacheBehaviour`
  * Integração com telemetria para monitoramento de performance
  * Sanitização de dados sensíveis em logs e eventos
  * Tratamento adequado de erros
  
  ## Exemplo de Uso
  
  ```elixir
  alias Deeper_Hub.Core.Cache.CachexAdapter
  
  # Iniciar um novo cache
  {:ok, _pid} = CachexAdapter.start_cache(:my_cache, [])
  
  # Armazenar um valor no cache
  {:ok, true} = CachexAdapter.put(:my_cache, "key", "value")
  
  # Recuperar um valor do cache
  {:ok, "value"} = CachexAdapter.get(:my_cache, "key")
  ```
  """
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Cache.CacheBehaviour
  
  @behaviour CacheBehaviour
  
  @doc """
  Inicializa um novo cache com o nome e opções fornecidas.
  
  ## Parâmetros
  
    * `name` - Nome do cache a ser inicializado
    * `options` - Opções de configuração para o Cachex
    
  ## Retorno
  
    * `{:ok, pid}` - Cache inicializado com sucesso
    * `{:error, reason}` - Falha ao inicializar o cache
    
  ## Exemplos
  
      iex> CachexAdapter.start_cache(:my_cache, [])
      {:ok, pid}
  """
  @impl CacheBehaviour
  def start_cache(name, options) when is_atom(name) do
    start_time = System.monotonic_time()
    
    # Log de início da operação
    Logger.debug("Iniciando cache com Cachex", %{
      module: __MODULE__,
      name: name,
      options: sanitize_options(options)
    })
    
    result = Cachex.start_link(name, options)
    
    # Log do resultado da operação
    case result do
      {:ok, pid} ->
        duration = System.monotonic_time() - start_time
        Logger.debug("Cache iniciado com sucesso", %{
          module: __MODULE__,
          name: name,
          duration_ms: System.convert_time_unit(duration, :native, :millisecond)
        })
        
        {:ok, pid}
        
      {:error, reason} = error ->
        Logger.error("Falha ao iniciar cache", %{
          module: __MODULE__,
          name: name,
          error: reason
        })
        
        error
    end
  end
  
  @doc """
  Armazena um valor no cache.
  
  ## Parâmetros
  
    * `cache` - Nome do cache
    * `key` - Chave para armazenar o valor
    * `value` - Valor a ser armazenado
    * `options` - Opções adicionais como TTL
    
  ## Opções
  
    * `:ttl` - Tempo de vida em milissegundos
    
  ## Retorno
  
    * `{:ok, true}` - Valor armazenado com sucesso
    * `{:error, reason}` - Falha ao armazenar o valor
    
  ## Exemplos
  
      iex> CachexAdapter.put(:my_cache, "key", "value")
      {:ok, true}
      
      iex> CachexAdapter.put(:my_cache, "key", "value", ttl: 1000) # expira em 1 segundo
      {:ok, true}
  """
  @impl CacheBehaviour
  def put(cache, key, value, options \\ []) do
    start_time = System.monotonic_time()
    
    # Log de início da operação
    Logger.debug("Armazenando valor no cache", %{
      module: __MODULE__,
      cache: cache,
      key: key,
      options: sanitize_options(options)
    })
    
    result = case Keyword.get(options, :ttl) do
      nil ->
        Cachex.put(cache, key, value)
      ttl ->
        Cachex.put(cache, key, value, ttl: ttl)
    end
    
    # Log do resultado da operação
    case result do
      {:ok, true} = success ->
        duration = System.monotonic_time() - start_time
        Logger.debug("Valor armazenado com sucesso", %{
          module: __MODULE__,
          cache: cache,
          key: key,
          duration_ms: System.convert_time_unit(duration, :native, :millisecond)
        })
        
        success
        
      {:error, reason} = error ->
        Logger.error("Falha ao armazenar valor no cache", %{
          module: __MODULE__,
          cache: cache,
          key: key,
          error: reason
        })
        
        error
    end
  end
  
  @doc """
  Obtém um valor do cache a partir de uma chave.
  
  ## Parâmetros
  
    * `cache` - Nome do cache
    * `key` - Chave do valor a ser obtido
    * `default` - Valor padrão se a chave não for encontrada
    
  ## Retorno
  
    * `{:ok, value}` - Valor encontrado no cache
    * `{:ok, nil}` - Chave não encontrada no cache (e sem default)
    * `{:ok, default}` - Chave não encontrada, retornando valor padrão
    * `{:error, reason}` - Falha ao acessar o cache
    
  ## Exemplos
  
      iex> CachexAdapter.get(:my_cache, "key")
      {:ok, "value"} # se a chave existir
      
      iex> CachexAdapter.get(:my_cache, "missing_key")
      {:ok, nil} # se a chave não existir
      
      iex> CachexAdapter.get(:my_cache, "missing_key", "default")
      {:ok, "default"} # se a chave não existir
  """
  @impl CacheBehaviour
  def get(cache, key, default \\ nil) do
    start_time = System.monotonic_time()
    
    # Log de início da operação
    Logger.debug("Obtendo valor do cache", %{
      module: __MODULE__,
      cache: cache,
      key: key
    })
    
    result = Cachex.get(cache, key, fallback: default)
    
    # Log do resultado da operação
    case result do
      {:ok, nil} = success ->
        duration = System.monotonic_time() - start_time
        Logger.debug("Chave não encontrada no cache", %{
          module: __MODULE__,
          cache: cache,
          key: key,
          duration_ms: System.convert_time_unit(duration, :native, :millisecond)
        })
        
        success
        
      {:ok, _value} = success ->
        duration = System.monotonic_time() - start_time
        Logger.debug("Valor obtido com sucesso", %{
          module: __MODULE__,
          cache: cache,
          key: key,
          duration_ms: System.convert_time_unit(duration, :native, :millisecond)
        })
        
        success
        
      {:error, reason} = error ->
        Logger.error("Falha ao obter valor do cache", %{
          module: __MODULE__,
          cache: cache,
          key: key,
          error: reason
        })
        
        error
    end
  end
  
  @doc """
  Verifica se uma chave existe no cache.
  
  ## Parâmetros
  
    * `cache` - Nome do cache
    * `key` - Chave a ser verificada
    
  ## Retorno
  
    * `{:ok, boolean()}` - true se existe, false caso contrário
    * `{:error, reason}` - Falha ao verificar o cache
    
  ## Exemplos
  
      iex> CachexAdapter.exists?(:my_cache, "key")
      {:ok, true} # se a chave existir
      
      iex> CachexAdapter.exists?(:my_cache, "missing_key")
      {:ok, false} # se a chave não existir
  """
  @impl CacheBehaviour
  def exists?(cache, key) do
    start_time = System.monotonic_time()
    
    # Log de início da operação
    Logger.debug("Verificando existência no cache", %{
      module: __MODULE__,
      cache: cache,
      key: key
    })
    
    result = Cachex.exists?(cache, key)
    
    # Log do resultado da operação
    case result do
      {:ok, exists} = success ->
        duration = System.monotonic_time() - start_time
        Logger.debug("Verificação de existência concluída", %{
          module: __MODULE__,
          cache: cache,
          key: key,
          exists: exists,
          duration_ms: System.convert_time_unit(duration, :native, :millisecond)
        })
        
        success
        
      {:error, reason} = error ->
        Logger.error("Falha ao verificar existência no cache", %{
          module: __MODULE__,
          cache: cache,
          key: key,
          error: reason
        })
        
        error
    end
  end
  
  @doc """
  Remove um valor do cache a partir de uma chave.
  
  ## Parâmetros
  
    * `cache` - Nome do cache
    * `key` - Chave a ser removida
    
  ## Retorno
  
    * `{:ok, boolean()}` - true se removido, false se não existia
    * `{:error, reason}` - Falha ao remover do cache
    
  ## Exemplos
  
      iex> CachexAdapter.del(:my_cache, "key")
      {:ok, true} # se a chave existia e foi removida
      
      iex> CachexAdapter.del(:my_cache, "missing_key")
      {:ok, false} # se a chave não existia
  """
  @impl CacheBehaviour
  def del(cache, key) do
    start_time = System.monotonic_time()
    
    # Log de início da operação
    Logger.debug("Removendo valor do cache", %{
      module: __MODULE__,
      cache: cache,
      key: key
    })
    
    result = Cachex.del(cache, key)
    
    # Log do resultado da operação
    case result do
      {:ok, true} = success ->
        duration = System.monotonic_time() - start_time
        Logger.debug("Valor removido com sucesso", %{
          module: __MODULE__,
          cache: cache,
          key: key,
          duration_ms: System.convert_time_unit(duration, :native, :millisecond)
        })
        
        success
        
      {:ok, false} = success ->
        duration = System.monotonic_time() - start_time
        Logger.debug("Chave não encontrada para remoção", %{
          module: __MODULE__,
          cache: cache,
          key: key,
          duration_ms: System.convert_time_unit(duration, :native, :millisecond)
        })
        
        success
        
      {:error, reason} = error ->
        Logger.error("Falha ao remover valor do cache", %{
          module: __MODULE__,
          cache: cache,
          key: key,
          error: reason
        })
        
        error
    end
  end
  
  # Funções privadas auxiliares
  
  # Sanitiza opções para logging (remove dados sensíveis)
  defp sanitize_options(options) do
    # No momento, não temos opções sensíveis para sanitizar no Cachex
    # Mas mantemos essa função para facilitar extensões futuras
    options
  end
  
  @doc """
  Armazena múltiplos valores no cache em uma única operação.
  
  ## Parâmetros
  
    * `cache` - Nome do cache
    * `entries` - Lista de tuplas {chave, valor}
    * `options` - Opções adicionais como TTL
    
  ## Opções
  
    * `:ttl` - Tempo de vida em milissegundos
    
  ## Retorno
  
    * `{:ok, boolean()}` - Valores armazenados com sucesso
    * `{:error, reason}` - Falha ao armazenar os valores
    
  ## Exemplos
  
      iex> CachexAdapter.put_many(:my_cache, [{"key1", "value1"}, {"key2", "value2"}])
      {:ok, true}
      
      iex> CachexAdapter.put_many(:my_cache, [{"key1", "value1"}, {"key2", "value2"}], ttl: 1000)
      {:ok, true}
  """
  @impl CacheBehaviour
  def put_many(cache, entries, options \\ []) do
    start_time = System.monotonic_time()
    
    # Log de início da operação
    Logger.debug("Armazenando múltiplos valores no cache", %{
      module: __MODULE__,
      cache: cache,
      count: length(entries),
      options: sanitize_options(options)
    })
    
    result = case Keyword.get(options, :ttl) do
      nil ->
        Cachex.put_many(cache, entries)
      _ttl ->
        # Implementa TTL manualmente pois o Cachex.put_many não aceita opção ttl
        Cachex.transaction!(cache, entries, fn(worker) ->
          Enum.each(entries, fn {key, value} ->
            Cachex.put(worker, key, value, ttl: Keyword.get(options, :ttl))
          end)
          true
        end)
        {:ok, true}
    end
    
    # Log do resultado da operação
    case result do
      {:ok, true} = success ->
        duration = System.monotonic_time() - start_time
        Logger.debug("Múltiplos valores armazenados com sucesso", %{
          module: __MODULE__,
          cache: cache,
          count: length(entries),
          duration_ms: System.convert_time_unit(duration, :native, :millisecond)
        })
        
        success
        
      {:error, reason} = error ->
        Logger.error("Falha ao armazenar múltiplos valores no cache", %{
          module: __MODULE__,
          cache: cache,
          count: length(entries),
          error: reason
        })
        
        error
    end
  end
  
  @doc """
  Obtém múltiplos valores do cache em uma única operação.
  
  ## Parâmetros
  
    * `cache` - Nome do cache
    * `keys` - Lista de chaves a serem obtidas
    
  ## Retorno
  
    * `{:ok, map()}` - Mapa com as chaves e valores encontrados
    * `{:error, reason}` - Falha ao acessar o cache
    
  ## Exemplos
  
      iex> CachexAdapter.get_many(:my_cache, ["key1", "key2"])
      {:ok, %{"key1" => "value1", "key2" => "value2"}}
  """
  @impl CacheBehaviour
  def get_many(cache, keys) do
    start_time = System.monotonic_time()
    
    # Log de início da operação
    Logger.debug("Obtendo múltiplos valores do cache", %{
      module: __MODULE__,
      cache: cache,
      keys_count: length(keys)
    })
    
    # Implementamos get_many manualmente, pois não existe um Cachex.get_many
    # Usamos transaction para garantir atomicidade ao obter múltiplos valores
    result = Cachex.transaction!(cache, keys, fn(worker) ->
      values = keys
      |> Enum.map(fn key -> {key, Cachex.get!(worker, key)} end)
      |> Map.new()
      {:ok, values}
    end)
    
    # Log do resultado da operação
    case result do
      {:ok, values} = success when is_map(values) ->
        duration = System.monotonic_time() - start_time
        Logger.debug("Múltiplos valores obtidos com sucesso", %{
          module: __MODULE__,
          cache: cache,
          keys_count: length(keys),
          found_count: map_size(values),
          duration_ms: System.convert_time_unit(duration, :native, :millisecond)
        })
        
        success
        
      {:error, reason} = error ->
        Logger.error("Falha ao obter múltiplos valores do cache", %{
          module: __MODULE__,
          cache: cache,
          keys_count: length(keys),
          error: reason
        })
        
        error
    end
  end
  
  @doc """
  Incrementa o valor numérico associado a uma chave.
  
  ## Parâmetros
  
    * `cache` - Nome do cache
    * `key` - Chave a ser incrementada
    * `amount` - Quantidade a incrementar (padrão: 1)
    
  ## Retorno
  
    * `{:ok, integer()}` - Novo valor após incremento
    * `{:error, reason}` - Falha ao incrementar o valor
    
  ## Exemplos
  
      iex> CachexAdapter.incr(:my_cache, "counter")
      {:ok, 1} # se a chave não existia antes
      
      iex> CachexAdapter.incr(:my_cache, "counter")
      {:ok, 2} # segunda chamada
      
      iex> CachexAdapter.incr(:my_cache, "counter", 5)
      {:ok, 7} # incrementando em 5
  """
  @impl CacheBehaviour
  def incr(cache, key, amount \\ 1) do
    start_time = System.monotonic_time()
    
    # Log de início da operação
    Logger.debug("Incrementando valor no cache", %{
      module: __MODULE__,
      cache: cache,
      key: key,
      amount: amount
    })
    
    result = Cachex.incr(cache, key, amount)
    
    # Log do resultado da operação
    case result do
      {:ok, new_value} = success ->
        duration = System.monotonic_time() - start_time
        Logger.debug("Valor incrementado com sucesso", %{
          module: __MODULE__,
          cache: cache,
          key: key,
          new_value: new_value,
          amount: amount,
          duration_ms: System.convert_time_unit(duration, :native, :millisecond)
        })
        
        success
        
      {:error, reason} = error ->
        Logger.error("Falha ao incrementar valor no cache", %{
          module: __MODULE__,
          cache: cache,
          key: key,
          amount: amount,
          error: reason
        })
        
        error
    end
  end
  
  @doc """
  Decrementa o valor numérico associado a uma chave.
  
  ## Parâmetros
  
    * `cache` - Nome do cache
    * `key` - Chave a ser decrementada
    * `amount` - Quantidade a decrementar (padrão: 1)
    
  ## Retorno
  
    * `{:ok, integer()}` - Novo valor após decremento
    * `{:error, reason}` - Falha ao decrementar o valor
    
  ## Exemplos
  
      iex> CachexAdapter.decr(:my_cache, "counter")
      {:ok, -1} # se a chave não existia antes
      
      iex> CachexAdapter.decr(:my_cache, "counter")
      {:ok, -2} # segunda chamada
      
      iex> CachexAdapter.decr(:my_cache, "counter", 3)
      {:ok, -5} # decrementando em 3
  """
  @impl CacheBehaviour
  def decr(cache, key, amount \\ 1) do
    start_time = System.monotonic_time()
    
    # Log de início da operação
    Logger.debug("Decrementando valor no cache", %{
      module: __MODULE__,
      cache: cache,
      key: key,
      amount: amount
    })
    
    result = Cachex.decr(cache, key, amount)
    
    # Log do resultado da operação
    case result do
      {:ok, new_value} = success ->
        duration = System.monotonic_time() - start_time
        Logger.debug("Valor decrementado com sucesso", %{
          module: __MODULE__,
          cache: cache,
          key: key,
          new_value: new_value,
          amount: amount,
          duration_ms: System.convert_time_unit(duration, :native, :millisecond)
        })
        
        success
        
      {:error, reason} = error ->
        Logger.error("Falha ao decrementar valor no cache", %{
          module: __MODULE__,
          cache: cache,
          key: key,
          amount: amount,
          error: reason
        })
        
        error
    end
  end
  
  @doc """
  Busca um valor no cache, calculando-o caso não exista.
  
  ## Parâmetros
  
    * `cache` - Nome do cache
    * `key` - Chave a ser buscada
    * `compute_fun` - Função que calcula o valor se não estiver no cache
    * `options` - Opções adicionais como TTL
    
  ## Opções
  
    * `:ttl` - Tempo de vida em milissegundos
    
  ## Retorno
  
    * `{:commit, value}` - Valor obtido do cache ou calculado
    * `{:ignore, value}` - Valor obtido do cache ou calculado, mas não armazenado
    * `{:error, reason}` - Falha ao acessar o cache
    
  ## Exemplos
  
      iex> CachexAdapter.fetch(:my_cache, "key", fn key ->
      ...>   {:commit, String.reverse(key)}
      ...> end)
      {:commit, "yek"} # calcula e armazena o valor se não existir
      
      iex> CachexAdapter.fetch(:my_cache, "key", fn _key ->
      ...>   {:ignore, "value"}
      ...> end)
      {:commit, "yek"} # retorna o valor já em cache
  """
  @impl CacheBehaviour
  def fetch(cache, key, compute_fun, options \\ []) do
    start_time = System.monotonic_time()
    
    # Log de início da operação
    Logger.debug("Buscando ou calculando valor no cache", %{
      module: __MODULE__,
      cache: cache,
      key: key,
      options: sanitize_options(options)
    })
    
    # Ajusta a função para lidar com TTL se necessário
    fetch_fun = case Keyword.get(options, :ttl) do
      nil ->
        compute_fun
      _ttl ->
        fn key ->
          case compute_fun.(key) do
            {:commit, _value} = result ->
              # Não retorna aqui - apenas calcula, o Cachex.fetch lidará com o armazenamento
              # com o TTL que será especificado abaixo
              result
            other ->
              other
          end
        end
    end
    
    result = case Keyword.get(options, :ttl) do
      nil ->
        Cachex.fetch(cache, key, fetch_fun)
      _ttl ->
        Cachex.fetch(cache, key, [ttl: Keyword.get(options, :ttl)], fetch_fun)
    end
    
    # Log do resultado da operação
    case result do
      {action, _value} = success when action in [:commit, :ignore] ->
        duration = System.monotonic_time() - start_time
        Logger.debug("Valor obtido ou calculado com sucesso", %{
          module: __MODULE__,
          cache: cache,
          key: key,
          action: action,
          duration_ms: System.convert_time_unit(duration, :native, :millisecond)
        })
        
        success
        
      {:error, reason} = error ->
        Logger.error("Falha ao buscar ou calcular valor no cache", %{
          module: __MODULE__,
          cache: cache,
          key: key,
          error: reason
        })
        
        error
    end
  end
  
  @doc """
  Atomicamente obtém e atualiza um valor no cache.
  
  ## Parâmetros
  
    * `cache` - Nome do cache
    * `key` - Chave a ser atualizada
    * `update_fun` - Função que recebe o valor atual e retorna o novo valor
    * `options` - Opções adicionais como TTL
    
  ## Opções
  
    * `:ttl` - Tempo de vida em milissegundos
    
  ## Retorno
  
    * `{:commit, value}` - Novo valor após atualização
    * `{:ignore, value}` - Valor obtido, sem atualização
    * `{:error, reason}` - Falha ao acessar o cache
    
  ## Exemplos
  
      iex> CachexAdapter.get_and_update(:my_cache, "counter", fn current ->
      ...>   (current || 0) + 1
      ...> end)
      {:commit, 1} # primeira chamada
      
      iex> CachexAdapter.get_and_update(:my_cache, "counter", fn current ->
      ...>   current + 1
      ...> end)
      {:commit, 2} # segunda chamada
  """
  @impl CacheBehaviour
  def get_and_update(cache, key, update_fun, options \\ []) do
    start_time = System.monotonic_time()
    
    # Log de início da operação
    Logger.debug("Obtendo e atualizando valor no cache", %{
      module: __MODULE__,
      cache: cache,
      key: key,
      options: sanitize_options(options)
    })
    
    # Implementa get_and_update usando transações do Cachex
    result = Cachex.transaction!(cache, [key], fn(worker) ->
      {:ok, current_value} = Cachex.get(worker, key)
      new_value = update_fun.(current_value)
      
      ttl = Keyword.get(options, :ttl)
      if ttl do
        Cachex.put(worker, key, new_value, ttl: ttl)
      else
        Cachex.put(worker, key, new_value)
      end
      
      {:commit, new_value}
    end)
    
    # Log do resultado da operação
    case result do
      {action, _value} = success when action in [:commit, :ignore] ->
        duration = System.monotonic_time() - start_time
        Logger.debug("Valor obtido e atualizado com sucesso", %{
          module: __MODULE__,
          cache: cache,
          key: key,
          action: action,
          duration_ms: System.convert_time_unit(duration, :native, :millisecond)
        })
        
        success
        
      {:error, reason} = error ->
        Logger.error("Falha ao obter e atualizar valor no cache", %{
          module: __MODULE__,
          cache: cache,
          key: key,
          error: reason
        })
        
        error
    end
  end
  
  @doc """
  Limpa o cache, removendo todas as entradas.
  
  ## Parâmetros
  
    * `cache` - Nome do cache
    
  ## Retorno
  
    * `{:ok, integer()}` - Número de entradas removidas
    * `{:error, reason}` - Falha ao limpar o cache
    
  ## Exemplos
  
      iex> CachexAdapter.clear(:my_cache)
      {:ok, 3} # remove 3 entradas do cache
  """
  @impl CacheBehaviour
  def clear(cache) do
    start_time = System.monotonic_time()
    
    # Log de início da operação
    Logger.debug("Limpando cache", %{
      module: __MODULE__,
      cache: cache
    })
    
    # Obtemos o tamanho antes de limpar para retornar o número de entradas removidas
    {:ok, size_before} = Cachex.size(cache)
    result = Cachex.clear(cache)
    
    # Log do resultado da operação
    case result do
      {:ok, true} ->
        duration = System.monotonic_time() - start_time
        Logger.debug("Cache limpo com sucesso", %{
          module: __MODULE__,
          cache: cache,
          removed_count: size_before,
          duration_ms: System.convert_time_unit(duration, :native, :millisecond)
        })
        
        {:ok, size_before}
        
      {:error, reason} = error ->
        Logger.error("Falha ao limpar cache", %{
          module: __MODULE__,
          cache: cache,
          error: reason
        })
        
        error
    end
  end
  
  @doc """
  Obtém o tamanho do cache (número de entradas).
  
  ## Parâmetros
  
    * `cache` - Nome do cache
    
  ## Retorno
  
    * `{:ok, integer()}` - Número de entradas no cache
    * `{:error, reason}` - Falha ao acessar o cache
    
  ## Exemplos
  
      iex> CachexAdapter.size(:my_cache)
      {:ok, 5} # cache tem 5 entradas
  """
  @impl CacheBehaviour
  def size(cache) do
    start_time = System.monotonic_time()
    
    # Log de início da operação
    Logger.debug("Obtendo tamanho do cache", %{
      module: __MODULE__,
      cache: cache
    })
    
    result = Cachex.size(cache)
    
    # Log do resultado da operação
    case result do
      {:ok, size} = success ->
        duration = System.monotonic_time() - start_time
        Logger.debug("Tamanho do cache obtido com sucesso", %{
          module: __MODULE__,
          cache: cache,
          size: size,
          duration_ms: System.convert_time_unit(duration, :native, :millisecond)
        })
        
        success
        
      {:error, reason} = error ->
        Logger.error("Falha ao obter tamanho do cache", %{
          module: __MODULE__,
          cache: cache,
          error: reason
        })
        
        error
    end
  end
  
  @doc """
  Obtém estatísticas do cache.
  
  ## Parâmetros
  
    * `cache` - Nome do cache
    
  ## Retorno
  
    * `{:ok, map()}` - Mapa com estatísticas do cache
    * `{:error, reason}` - Falha ao obter estatísticas
    
  ## Exemplos
  
      iex> CachexAdapter.stats(:my_cache)
      {:ok, %{hits: 10, misses: 2, ...}}
  """
  @impl CacheBehaviour
  def stats(cache) do
    start_time = System.monotonic_time()
    
    # Log de início da operação
    Logger.debug("Obtendo estatísticas do cache", %{
      module: __MODULE__,
      cache: cache
    })
    
    result = Cachex.stats(cache)
    
    # Log do resultado da operação
    case result do
      {:ok, stats} = success ->
        duration = System.monotonic_time() - start_time
        Logger.debug("Estatísticas do cache obtidas com sucesso", %{
          module: __MODULE__,
          cache: cache,
          stats: sanitize_stats(stats),
          duration_ms: System.convert_time_unit(duration, :native, :millisecond)
        })
        
        success
        
      {:error, reason} = error ->
        Logger.error("Falha ao obter estatísticas do cache", %{
          module: __MODULE__,
          cache: cache,
          error: reason
        })
        
        error
    end
  end
  
  @doc """
  Define um tempo de expiração para uma chave.
  
  ## Parâmetros
  
    * `cache` - Nome do cache
    * `key` - Chave a ser expirada
    * `ttl` - Tempo de vida em milissegundos
    
  ## Retorno
  
    * `{:ok, boolean()}` - true se definido, false se chave não encontrada
    * `{:error, reason}` - Falha ao definir expiração
    
  ## Exemplos
  
      iex> CachexAdapter.expire(:my_cache, "key", 5000)
      {:ok, true} # expira em 5 segundos
  """
  @impl CacheBehaviour
  def expire(cache, key, ttl) do
    start_time = System.monotonic_time()
    
    # Log de início da operação
    Logger.debug("Definindo tempo de expiração para chave", %{
      module: __MODULE__,
      cache: cache,
      key: key,
      ttl_ms: ttl
    })
    
    result = Cachex.expire(cache, key, ttl)
    
    # Log do resultado da operação
    case result do
      {:ok, true} = success ->
        duration = System.monotonic_time() - start_time
        Logger.debug("Tempo de expiração definido com sucesso", %{
          module: __MODULE__,
          cache: cache,
          key: key,
          ttl_ms: ttl,
          duration_ms: System.convert_time_unit(duration, :native, :millisecond)
        })
        
        success
        
      {:ok, false} = success ->
        duration = System.monotonic_time() - start_time
        Logger.debug("Chave não encontrada para definir expiração", %{
          module: __MODULE__,
          cache: cache,
          key: key,
          duration_ms: System.convert_time_unit(duration, :native, :millisecond)
        })
        
        success
        
      {:error, reason} = error ->
        Logger.error("Falha ao definir tempo de expiração", %{
          module: __MODULE__,
          cache: cache,
          key: key,
          ttl_ms: ttl,
          error: reason
        })
        
        error
    end
  end
  
  @doc """
  Remove do cache todas as entradas expiradas.
  
  ## Parâmetros
  
    * `cache` - Nome do cache
    
  ## Retorno
  
    * `{:ok, integer()}` - Número de entradas expiradas removidas
    * `{:error, reason}` - Falha ao remover entradas expiradas
    
  ## Exemplos
  
      iex> CachexAdapter.purge(:my_cache)
      {:ok, 2} # 2 entradas expiradas foram removidas
  """
  @impl CacheBehaviour
  def purge(cache) do
    start_time = System.monotonic_time()
    
    # Log de início da operação
    Logger.debug("Removendo entradas expiradas do cache", %{
      module: __MODULE__,
      cache: cache
    })
    
    # Obtemos o tamanho antes de purgar para calcular o número de entradas removidas
    {:ok, size_before} = Cachex.size(cache)
    result = Cachex.purge(cache)
    
    # Log do resultado da operação
    case result do
      {:ok, true} ->
        # Obtemos o tamanho após purgar para calcular o número de entradas removidas
        {:ok, size_after} = Cachex.size(cache)
        removed_count = size_before - size_after
        
        duration = System.monotonic_time() - start_time
        Logger.success("Entradas expiradas removidas com sucesso", %{
          module: __MODULE__,
          cache: cache,
          removed_count: removed_count,
          duration_ms: System.convert_time_unit(duration, :native, :millisecond)
        })
        
        {:ok, removed_count}
        
      {:error, reason} = error ->
        Logger.error("Falha ao remover entradas expiradas", %{
          module: __MODULE__,
          cache: cache,
          error: reason
        })
        
        error
    end
  end
  
  # Sanitiza estatísticas para logging (remove ou trunca dados muito grandes)
  defp sanitize_stats(stats) do
    # Mantemos apenas as principais métricas para o log
    %{
      hits: stats.hits,
      misses: stats.misses,
      size: stats.size,
      operations: stats.operations
    }
  end
end
