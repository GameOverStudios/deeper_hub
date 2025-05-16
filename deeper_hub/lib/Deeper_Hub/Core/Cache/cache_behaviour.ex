defmodule Deeper_Hub.Core.Cache.CacheBehaviour do
  @moduledoc """
  Comportamento que define a interface para operações de cache no sistema DeeperHub.
  
  Este módulo estabelece o contrato para todas as implementações de cache,
  garantindo consistência e intercambialidade.
  
  ## Funcionalidades
  
  * Armazenamento e recuperação de valores
  * Verificação de existência de chaves
  * Remoção de entradas do cache
  * Operações em lote
  * Atualizações atômicas
  * Cache com TTL (Time To Live)
  * Operações de incremento e decremento
  * Limpeza do cache
  """
  
  @doc """
  Inicializa o cache com o nome fornecido e opções.
  
  ## Parâmetros
  
    * `name` - Nome do cache a ser inicializado
    * `options` - Opções de configuração para o cache
    
  ## Retorno
  
    * `{:ok, pid}` - Cache inicializado com sucesso
    * `{:error, reason}` - Falha ao inicializar o cache
  """
  @callback start_cache(name :: atom(), options :: Keyword.t()) :: {:ok, pid()} | {:error, term()}
  
  @doc """
  Armazena um valor no cache associado a uma chave.
  
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
  """
  @callback put(cache :: atom(), key :: term(), value :: term(), options :: Keyword.t()) :: 
    {:ok, boolean()} | {:error, term()}
  
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
  """
  @callback get(cache :: atom(), key :: term(), default :: term() | nil) :: 
    {:ok, term() | nil} | {:error, term()}
  
  @doc """
  Verifica se uma chave existe no cache.
  
  ## Parâmetros
  
    * `cache` - Nome do cache
    * `key` - Chave a ser verificada
    
  ## Retorno
  
    * `{:ok, boolean()}` - true se existe, false caso contrário
    * `{:error, reason}` - Falha ao verificar o cache
  """
  @callback exists?(cache :: atom(), key :: term()) :: 
    {:ok, boolean()} | {:error, term()}
  
  @doc """
  Remove um valor do cache a partir de uma chave.
  
  ## Parâmetros
  
    * `cache` - Nome do cache
    * `key` - Chave a ser removida
    
  ## Retorno
  
    * `{:ok, boolean()}` - true se removido, false se não existia
    * `{:error, reason}` - Falha ao remover do cache
  """
  @callback del(cache :: atom(), key :: term()) :: 
    {:ok, boolean()} | {:error, term()}
  
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
  """
  @callback put_many(cache :: atom(), entries :: list({term(), term()}), options :: Keyword.t()) :: 
    {:ok, boolean()} | {:error, term()}
    
  @doc """
  Obtém múltiplos valores do cache em uma única operação.
  
  ## Parâmetros
  
    * `cache` - Nome do cache
    * `keys` - Lista de chaves a serem obtidas
    
  ## Retorno
  
    * `{:ok, map()}` - Mapa com as chaves e valores encontrados
    * `{:error, reason}` - Falha ao acessar o cache
  """
  @callback get_many(cache :: atom(), keys :: list(term())) :: 
    {:ok, map()} | {:error, term()}
  
  @doc """
  Incrementa o valor numérico associado a uma chave.
  
  ## Parâmetros
  
    * `cache` - Nome do cache
    * `key` - Chave a ser incrementada
    * `amount` - Quantidade a incrementar
    
  ## Retorno
  
    * `{:ok, integer()}` - Novo valor após incremento
    * `{:error, reason}` - Falha ao incrementar o valor
  """
  @callback incr(cache :: atom(), key :: term(), amount :: integer()) :: 
    {:ok, integer()} | {:error, term()}
  
  @doc """
  Decrementa o valor numérico associado a uma chave.
  
  ## Parâmetros
  
    * `cache` - Nome do cache
    * `key` - Chave a ser decrementada
    * `amount` - Quantidade a decrementar
    
  ## Retorno
  
    * `{:ok, integer()}` - Novo valor após decremento
    * `{:error, reason}` - Falha ao decrementar o valor
  """
  @callback decr(cache :: atom(), key :: term(), amount :: integer()) :: 
    {:ok, integer()} | {:error, term()}
  
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
  """
  @callback fetch(cache :: atom(), key :: term(), compute_fun :: (term() -> {:commit | :ignore, term()}), options :: Keyword.t()) :: 
    {:commit | :ignore, term()} | {:error, term()}
  
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
  """
  @callback get_and_update(cache :: atom(), key :: term(), update_fun :: (term() -> term()), options :: Keyword.t()) :: 
    {:commit | :ignore, term()} | {:error, term()}
  
  @doc """
  Limpa o cache, removendo todas as entradas.
  
  ## Parâmetros
  
    * `cache` - Nome do cache
    
  ## Retorno
  
    * `{:ok, integer()}` - Número de entradas removidas
    * `{:error, reason}` - Falha ao limpar o cache
  """
  @callback clear(cache :: atom()) :: 
    {:ok, integer()} | {:error, term()}
  
  @doc """
  Obtém o tamanho do cache (número de entradas).
  
  ## Parâmetros
  
    * `cache` - Nome do cache
    
  ## Retorno
  
    * `{:ok, integer()}` - Número de entradas no cache
    * `{:error, reason}` - Falha ao acessar o cache
  """
  @callback size(cache :: atom()) :: 
    {:ok, integer()} | {:error, term()}
  
  @doc """
  Obtém estatísticas do cache.
  
  ## Parâmetros
  
    * `cache` - Nome do cache
    
  ## Retorno
  
    * `{:ok, map()}` - Mapa com estatísticas do cache
    * `{:error, reason}` - Falha ao obter estatísticas
  """
  @callback stats(cache :: atom()) :: 
    {:ok, map()} | {:error, term()}
  
  @doc """
  Define um tempo de expiração para uma chave.
  
  ## Parâmetros
  
    * `cache` - Nome do cache
    * `key` - Chave a ser expirada
    * `ttl` - Tempo de vida em milissegundos
    
  ## Retorno
  
    * `{:ok, boolean()}` - true se definido, false se chave não encontrada
    * `{:error, reason}` - Falha ao definir expiração
  """
  @callback expire(cache :: atom(), key :: term(), ttl :: integer()) :: 
    {:ok, boolean()} | {:error, term()}
  
  @doc """
  Remove do cache todas as entradas expiradas.
  
  ## Parâmetros
  
    * `cache` - Nome do cache
    
  ## Retorno
  
    * `{:ok, integer()}` - Número de entradas expiradas removidas
    * `{:error, reason}` - Falha ao remover entradas expiradas
  """
  @callback purge(cache :: atom()) :: 
    {:ok, integer()} | {:error, term()}
end
