defmodule Deeper_Hub.Core.CircuitBreaker.StorageBehaviour do
  @moduledoc """
  Comportamento para adaptadores de armazenamento do estado do CircuitBreaker.
  
  Este módulo define a interface que todos os adaptadores de armazenamento devem implementar
  para persistir e recuperar o estado dos circuit breakers.
  """
  
  @doc """
  Salva o estado de um circuit breaker.
  
  ## Parâmetros
  
    - `service_name`: Nome do serviço (atom)
    - `state`: Estado atual do circuit breaker (:closed, :open, :half_open)
    - `metadata`: Metadados adicionais como timestamps, contadores, etc.
  
  ## Retorno
  
    - `:ok` se o estado for salvo com sucesso
    - `{:error, reason}` em caso de falha
  """
  @callback save_state(service_name :: atom(), state :: atom(), metadata :: map()) :: :ok | {:error, term()}
  
  @doc """
  Carrega o estado de um circuit breaker.
  
  ## Parâmetros
  
    - `service_name`: Nome do serviço (atom)
  
  ## Retorno
  
    - `{:ok, {state, metadata}}` se o estado for carregado com sucesso
    - `{:error, reason}` em caso de falha
  """
  @callback load_state(service_name :: atom()) :: {:ok, {atom(), map()}} | {:error, term()}
  
  @doc """
  Remove o estado de um circuit breaker.
  
  ## Parâmetros
  
    - `service_name`: Nome do serviço (atom)
  
  ## Retorno
  
    - `:ok` se o estado for removido com sucesso
    - `{:error, reason}` em caso de falha
  """
  @callback delete_state(service_name :: atom()) :: :ok | {:error, term()}
  
  @doc """
  Lista todos os circuit breakers registrados.
  
  ## Retorno
  
    - `{:ok, list}` com a lista de nomes de serviços
    - `{:error, reason}` em caso de falha
  """
  @callback list_all() :: {:ok, list(atom())} | {:error, term()}
end
