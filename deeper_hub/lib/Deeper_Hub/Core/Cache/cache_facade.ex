defmodule Deeper_Hub.Core.Cache.CacheFacade do
  @moduledoc """
  Fachada para operações de cache no sistema Deeper_Hub.

  Este módulo fornece uma interface simplificada para todas as operações de cache,
  permitindo que outros módulos do sistema utilizem o cache sem conhecer os detalhes
  de implementação.

  A fachada delega as chamadas para o adaptador de cache configurado, permitindo
  trocar a implementação subjacente sem afetar os consumidores do serviço.

  ## Exemplo de Uso

  ```elixir
  alias Deeper_Hub.Core.Cache.CacheFacade

  # Armazenar um valor no cache
  CacheFacade.put(:my_cache, "key", "value")

  # Recuperar um valor do cache
  {:ok, "value"} = CacheFacade.get(:my_cache, "key")

  # Limpar o cache
  CacheFacade.clear(:my_cache)
  ```
  """

  @doc """
  Inicializa um novo cache com o nome e opções fornecidas.

  ## Parâmetros

    * `name` - Nome do cache a ser inicializado
    * `options` - Opções de configuração para o cache

  ## Retorno

    * `{:ok, pid}` - Cache inicializado com sucesso
    * `{:error, reason}` - Falha ao inicializar o cache
  """
  @spec start_cache(atom(), Keyword.t()) :: {:ok, pid()} | {:error, term()}
  def start_cache(name, options \\ []) do
    cache_adapter().start_cache(name, options)
  end

  @doc """
  Armazena um valor no cache associado a uma chave.

  ## Parâmetros

    * `cache` - Nome do cache
    * `key` - Chave para armazenar o valor
    * `value` - Valor a ser armazenado
    * `options` - Opções adicionais como TTL
  """
  @spec put(atom(), term(), term(), Keyword.t()) :: {:ok, boolean()} | {:error, term()}
  def put(cache, key, value, options \\ []) do
    cache_adapter().put(cache, key, value, options)
  end

  @doc """
  Obtém um valor do cache a partir de uma chave.

  ## Parâmetros

    * `cache` - Nome do cache
    * `key` - Chave do valor a ser obtido
    * `default` - Valor padrão se a chave não for encontrada
  """
  @spec get(atom(), term(), term() | nil) :: {:ok, term() | nil} | {:error, term()}
  def get(cache, key, default \\ nil) do
    cache_adapter().get(cache, key, default)
  end

  @doc """
  Verifica se uma chave existe no cache.

  ## Parâmetros

    * `cache` - Nome do cache
    * `key` - Chave a ser verificada
  """
  @spec exists?(atom(), term()) :: {:ok, boolean()} | {:error, term()}
  def exists?(cache, key) do
    cache_adapter().exists?(cache, key)
  end

  @doc """
  Remove um valor do cache a partir de uma chave.

  ## Parâmetros

    * `cache` - Nome do cache
    * `key` - Chave a ser removida
  """
  @spec del(atom(), term()) :: {:ok, boolean()} | {:error, term()}
  def del(cache, key) do
    cache_adapter().del(cache, key)
  end

  @doc """
  Armazena múltiplos valores no cache em uma única operação.

  ## Parâmetros

    * `cache` - Nome do cache
    * `entries` - Lista de tuplas {chave, valor}
    * `options` - Opções adicionais como TTL
  """
  @spec put_many(atom(), list({term(), term()}), Keyword.t()) :: {:ok, boolean()} | {:error, term()}
  def put_many(cache, entries, options \\ []) do
    cache_adapter().put_many(cache, entries, options)
  end

  @doc """
  Obtém múltiplos valores do cache em uma única operação.

  ## Parâmetros

    * `cache` - Nome do cache
    * `keys` - Lista de chaves a serem obtidas
  """
  @spec get_many(atom(), list(term())) :: {:ok, map()} | {:error, term()}
  def get_many(cache, keys) do
    cache_adapter().get_many(cache, keys)
  end

  @doc """
  Incrementa o valor numérico associado a uma chave.

  ## Parâmetros

    * `cache` - Nome do cache
    * `key` - Chave a ser incrementada
    * `amount` - Quantidade a incrementar
  """
  @spec incr(atom(), term(), integer()) :: {:ok, integer()} | {:error, term()}
  def incr(cache, key, amount \\ 1) do
    cache_adapter().incr(cache, key, amount)
  end

  @doc """
  Decrementa o valor numérico associado a uma chave.

  ## Parâmetros

    * `cache` - Nome do cache
    * `key` - Chave a ser decrementada
    * `amount` - Quantidade a decrementar
  """
  @spec decr(atom(), term(), integer()) :: {:ok, integer()} | {:error, term()}
  def decr(cache, key, amount \\ 1) do
    cache_adapter().decr(cache, key, amount)
  end

  @doc """
  Busca um valor no cache, calculando-o caso não exista.

  ## Parâmetros

    * `cache` - Nome do cache
    * `key` - Chave a ser buscada
    * `compute_fun` - Função que calcula o valor se não estiver no cache
    * `options` - Opções adicionais como TTL
  """
  @spec fetch(atom(), term(), (term() -> {:commit | :ignore, term()}), Keyword.t()) ::
          {:commit | :ignore, term()} | {:error, term()}
  def fetch(cache, key, compute_fun, options \\ []) do
    cache_adapter().fetch(cache, key, compute_fun, options)
  end

  @doc """
  Atomicamente obtém e atualiza um valor no cache.

  ## Parâmetros

    * `cache` - Nome do cache
    * `key` - Chave a ser atualizada
    * `update_fun` - Função que recebe o valor atual e retorna o novo valor
    * `options` - Opções adicionais como TTL
  """
  @spec get_and_update(atom(), term(), (term() -> term()), Keyword.t()) ::
          {:commit | :ignore, term()} | {:error, term()}
  def get_and_update(cache, key, update_fun, options \\ []) do
    cache_adapter().get_and_update(cache, key, update_fun, options)
  end

  @doc """
  Limpa o cache, removendo todas as entradas.

  ## Parâmetros

    * `cache` - Nome do cache
  """
  @spec clear(atom()) :: {:ok, integer()} | {:error, term()}
  def clear(cache) do
    cache_adapter().clear(cache)
  end

  @doc """
  Obtém o tamanho do cache (número de entradas).

  ## Parâmetros

    * `cache` - Nome do cache
  """
  @spec size(atom()) :: {:ok, integer()} | {:error, term()}
  def size(cache) do
    cache_adapter().size(cache)
  end

  @doc """
  Obtém estatísticas do cache.

  ## Parâmetros

    * `cache` - Nome do cache
  """
  @spec stats(atom()) :: {:ok, map()} | {:error, term()}
  def stats(cache) do
    cache_adapter().stats(cache)
  end

  @doc """
  Define um tempo de expiração para uma chave.

  ## Parâmetros

    * `cache` - Nome do cache
    * `key` - Chave a ser expirada
    * `ttl` - Tempo de vida em milissegundos
  """
  @spec expire(atom(), term(), integer()) :: {:ok, boolean()} | {:error, term()}
  def expire(cache, key, ttl) do
    cache_adapter().expire(cache, key, ttl)
  end

  @doc """
  Remove do cache todas as entradas expiradas.

  ## Parâmetros

    * `cache` - Nome do cache
  """
  @spec purge(atom()) :: {:ok, integer()} | {:error, term()}
  def purge(cache) do
    cache_adapter().purge(cache)
  end

  # Função privada para obter o adaptador de cache configurado
  defp cache_adapter do
    # Por enquanto, retornamos diretamente o adaptador Cachex
    # No futuro, isso pode ser alterado para usar um módulo de configuração
    Deeper_Hub.Core.Cache.CachexAdapter
  end
end
