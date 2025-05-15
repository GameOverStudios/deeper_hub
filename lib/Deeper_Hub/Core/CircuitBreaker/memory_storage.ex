defmodule Deeper_Hub.Core.CircuitBreaker.MemoryStorage do
  @moduledoc """
  Implementação do adaptador de armazenamento em memória para o CircuitBreaker.
  
  Este módulo utiliza ETS para armazenar o estado dos circuit breakers em memória.
  É a implementação padrão e mais simples, adequada para a maioria dos casos.
  """
  
  @behaviour Deeper_Hub.Core.CircuitBreaker.StorageBehaviour
  
  alias Deeper_Hub.Core.Logger
  
  # Nome da tabela ETS
  @table_name :circuit_breaker_states
  
  @doc """
  Inicializa o armazenamento em memória.
  
  Cria a tabela ETS se ela ainda não existir.
  """
  @spec initialize() :: :ok
  def initialize do
    if !table_exists?() do
      :ets.new(@table_name, [:set, :public, :named_table])
    end
    
    :ok
  end
  
  @impl true
  def save_state(service_name, state, metadata) when is_atom(service_name) and is_atom(state) and is_map(metadata) do
    try do
      ensure_table_exists()
      
      # Adiciona timestamp atual aos metadados
      updated_metadata = Map.put(metadata, :updated_at, DateTime.utc_now())
      
      # Insere na tabela ETS
      :ets.insert(@table_name, {service_name, state, updated_metadata})
      
      Logger.debug("Estado do circuit breaker salvo", %{
        module: __MODULE__,
        service_name: service_name,
        state: state
      })
      
      :ok
    rescue
      e ->
        Logger.error("Falha ao salvar estado do circuit breaker", %{
          module: __MODULE__,
          service_name: service_name,
          error: e,
          stacktrace: __STACKTRACE__
        })
        
        {:error, e}
    end
  end
  
  @impl true
  def load_state(service_name) when is_atom(service_name) do
    try do
      ensure_table_exists()
      
      case :ets.lookup(@table_name, service_name) do
        [{^service_name, state, metadata}] ->
          Logger.debug("Estado do circuit breaker carregado", %{
            module: __MODULE__,
            service_name: service_name,
            state: state
          })
          
          {:ok, {state, metadata}}
          
        [] ->
          # Se não encontrar, retorna o estado padrão (fechado)
          Logger.debug("Estado do circuit breaker não encontrado, usando padrão", %{
            module: __MODULE__,
            service_name: service_name
          })
          
          {:error, :not_found}
      end
    rescue
      e ->
        Logger.error("Falha ao carregar estado do circuit breaker", %{
          module: __MODULE__,
          service_name: service_name,
          error: e,
          stacktrace: __STACKTRACE__
        })
        
        {:error, e}
    end
  end
  
  @impl true
  def delete_state(service_name) when is_atom(service_name) do
    try do
      ensure_table_exists()
      
      :ets.delete(@table_name, service_name)
      
      Logger.debug("Estado do circuit breaker removido", %{
        module: __MODULE__,
        service_name: service_name
      })
      
      :ok
    rescue
      e ->
        Logger.error("Falha ao remover estado do circuit breaker", %{
          module: __MODULE__,
          service_name: service_name,
          error: e,
          stacktrace: __STACKTRACE__
        })
        
        {:error, e}
    end
  end
  
  @impl true
  def list_all do
    try do
      ensure_table_exists()
      
      # Obtém todas as chaves da tabela ETS
      service_names = :ets.tab2list(@table_name)
                      |> Enum.map(fn {service_name, _state, _metadata} -> service_name end)
      
      Logger.debug("Lista de circuit breakers obtida", %{
        module: __MODULE__,
        count: length(service_names)
      })
      
      {:ok, service_names}
    rescue
      e ->
        Logger.error("Falha ao listar circuit breakers", %{
          module: __MODULE__,
          error: e,
          stacktrace: __STACKTRACE__
        })
        
        {:error, e}
    end
  end
  
  # Funções privadas
  
  defp table_exists? do
    case :ets.info(@table_name) do
      :undefined -> false
      _ -> true
    end
  end
  
  defp ensure_table_exists do
    if !table_exists?() do
      initialize()
    end
  end
end
