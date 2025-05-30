defmodule DeeperHub.Core.Cache.Hooks.LoggerHook do
  @moduledoc """
  Hook para registrar operações de cache no sistema de log.
  
  Este hook registra todas as operações principais do cache (escrita, leitura, 
  exclusão, etc.) no sistema de log do DeeperHub, permitindo um acompanhamento
  detalhado das operações realizadas.
  """
  
  @behaviour Cachex.Hook
  
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  
  @doc """
  Retorna as ações que este hook deve monitorar.
  
  Monitoramos as seguintes ações:
  - :get - Leituras do cache
  - :put - Escritas no cache
  - :delete - Exclusões do cache
  - :clear - Limpeza do cache
  - :purge - Limpeza de itens expirados
  """
  @impl Cachex.Hook
  def actions do
    [
      :get,
      :put, 
      :update,
      :delete, 
      :clear,
      :purge
    ]
  end
  
  @doc """
  Indica se este hook é assíncrono.
  
  Utilizamos hooks assíncronos para evitar impacto no desempenho
  das operações de cache.
  """
  @impl Cachex.Hook
  def async?, do: true
  
  @doc """
  Processa uma notificação de operação no cache.
  
  ## Parâmetros
  
    * `action` - A ação realizada (ex: `:get`, `:put`, etc.)
    * `result` - O resultado da operação
    * `state` - O estado atual do hook
  """
  @impl Cachex.Hook
  def handle_notify(action, result, state) do
    log_cache_operation(action, result)
    {:ok, state}
  end
  
  @doc """
  Define o timeout para as chamadas a este hook.
  
  Define um timeout curto para evitar bloqueios, já que
  operações de log podem falhar.
  """
  @impl Cachex.Hook
  def timeout, do: 1000
  
  @doc """
  Retorna o tipo deste hook.
  
  Este hook é do tipo `:post`, o que significa que ele é executado
  após a operação de cache ser concluída.
  """
  @impl Cachex.Hook
  def type, do: :post
  
  @doc """
  Define as provisões que este hook fornece ao Cachex.
  
  No caso deste hook, não fornecemos nenhuma provisão especial,
  apenas monitoramos as operações para log.
  """
  def provisions, do: []
  
  @doc """
  Inicializa o hook com um estado personalizado.
  
  ## Parâmetros
  
    * `state` - Estado inicial, geralmente opções de configuração
  
  ## Retorno
  
    * `{:ok, state}` - Estado inicializado com sucesso
  """
  def init(state) do
    Logger.debug("Inicializando hook de logging para o cache", module: __MODULE__)
    {:ok, state}
  end
  
  # Funções privadas
  
  # Registra a operação de cache no sistema de log
  defp log_cache_operation(:get, {:ok, nil}), do: 
    Logger.debug("Cache MISS", module: __MODULE__)
    
  defp log_cache_operation(:get, {:ok, _value}), do: 
    Logger.debug("Cache HIT", module: __MODULE__)
    
  defp log_cache_operation(:put, {:ok, true}), do: 
    Logger.debug("Cache PUT: sucesso", module: __MODULE__)
    
  defp log_cache_operation(:update, {:ok, true}), do: 
    Logger.debug("Cache UPDATE: sucesso", module: __MODULE__)
    
  defp log_cache_operation(:delete, {:ok, _result}), do: 
    Logger.debug("Cache DELETE: sucesso", module: __MODULE__)
    
  defp log_cache_operation(:clear, {:ok, count}), do: 
    Logger.info("Cache CLEAR: #{count} entradas removidas", module: __MODULE__)
    
  defp log_cache_operation(:purge, {:ok, count}), do: 
    Logger.info("Cache PURGE: #{count} entradas expiradas removidas", module: __MODULE__)
    
  defp log_cache_operation(action, result), do: 
    Logger.debug("Cache #{action}: #{inspect(result)}", module: __MODULE__)
end
