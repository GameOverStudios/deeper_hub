defmodule Deeper_Hub.Core.Cache.StatsHook do
  @moduledoc """
  Hook para coletar estatísticas do cache.
  
  Este módulo implementa um hook do Cachex para coletar estatísticas de uso do cache,
  como hits, misses, operações de escrita e leitura.
  """
  
  @behaviour Cachex.Hook
  
  alias Deeper_Hub.Core.Logger
  
  # Estado inicial do hook
  def initial_state do
    %{
      hits: 0,
      misses: 0,
      writes: 0,
      reads: 0,
      operations: 0,
      creation_date: :os.system_time(:millisecond)
    }
  end
  
  @doc """
  Retorna as ações que este hook deve monitorar.
  
  ## Retorno
  
    - Lista de ações ou :all para todas
  """
  @impl Cachex.Hook
  def actions, do: :all
  
  @doc """
  Indica se este hook é assíncrono.
  
  ## Retorno
  
    - true para hooks assíncronos
  """
  @impl Cachex.Hook
  def async?, do: true
  
  @doc """
  Retorna o tipo deste hook.
  
  ## Retorno
  
    - :post para executar após a ação
  """
  @impl Cachex.Hook
  def type, do: :post
  
  @doc """
  Retorna o timeout para chamadas a este hook.
  
  ## Retorno
  
    - Timeout em milissegundos
  """
  @impl Cachex.Hook
  def timeout, do: 5000
  
  @doc """
  Manipula uma notificação do cache.
  
  ## Parâmetros
  
    - `action`: A ação sendo executada e seus argumentos
    - `result`: O resultado da ação
    - `state`: O estado atual do hook
  
  ## Retorno
  
    - `{:ok, new_state}` com o novo estado
  """
  @impl Cachex.Hook
  def handle_notify({action, _args}, result, state) do
    # Incrementa o contador de operações
    state = Map.update!(state, :operations, &(&1 + 1))
    
    # Atualiza o estado com base na ação e resultado
    state = case {action, result} do
      # Leitura com sucesso (hit)
      {:get, {:ok, value}} when not is_nil(value) ->
        state
        |> Map.update!(:hits, &(&1 + 1))
        |> Map.update!(:reads, &(&1 + 1))
      
      # Leitura sem sucesso (miss)
      {:get, {:ok, nil}} ->
        state
        |> Map.update!(:misses, &(&1 + 1))
        |> Map.update!(:reads, &(&1 + 1))
      
      # Operações de escrita
      {action, {:ok, _}} when action in [:put, :update, :set] ->
        Map.update!(state, :writes, &(&1 + 1))
      
      # Ignoramos outros resultados
      _ ->
        state
    end
    
    # Registra as estatísticas no log para depuração
    Logger.debug("Estatísticas do cache atualizadas", %{
      module: __MODULE__,
      action: action,
      stats: state
    })
    
    {:ok, state}
  end
  
  @doc """
  Obtém as estatísticas atuais do cache.
  
  ## Parâmetros
  
    - `cache`: O nome do cache
  
  ## Retorno
  
    - `{:ok, stats}` com as estatísticas
    - `{:error, reason}` em caso de falha
  """
  def get_stats(cache) do
    # Como não conseguimos acessar o estado do hook diretamente,
    # vamos coletar estatísticas básicas do cache
    try do
      # Obtém o tamanho atual do cache
      {:ok, size} = Cachex.size(cache)
      {:ok, keys} = Cachex.keys(cache)
      
      # Criamos estatísticas básicas
      stats = %{
        size: size,
        keys_count: length(keys),
        operations: 0,  # Não temos acesso a esta informação sem o estado do hook
        hits: 0,        # Não temos acesso a esta informação sem o estado do hook
        misses: 0,      # Não temos acesso a esta informação sem o estado do hook
        hit_rate: 0,    # Não temos acesso a esta informação sem o estado do hook
        miss_rate: 0,   # Não temos acesso a esta informação sem o estado do hook
        timestamp: :os.system_time(:millisecond)
      }
      
      {:ok, stats}
    rescue
      error -> 
        Logger.error("Erro ao obter estatísticas do cache", %{
          module: __MODULE__,
          error: error
        })
        {:error, :stats_error}
    end
  end
end
