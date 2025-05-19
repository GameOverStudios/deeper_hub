defmodule DeeperHub.Accounts.SessionCleanupWorker do
  @moduledoc """
  Worker para limpeza periódica de sessões expiradas e inativas.
  
  Este módulo implementa um processo GenServer que executa periodicamente
  a limpeza de sessões expiradas e inativas, garantindo que o sistema
  mantenha apenas sessões válidas e ativas.
  """
  
  use GenServer
  
  alias DeeperHub.Accounts.SessionManager
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  
  # Intervalo padrão de limpeza: 1 hora
  @default_interval 60 * 60 * 1000
  
  # Período padrão de inatividade: 24 horas
  @default_inactivity_period 24 * 60 * 60
  
  @doc """
  Inicia o worker de limpeza de sessões.
  
  ## Opções
    * `:interval` - Intervalo de limpeza em milissegundos (padrão: 1 hora)
    * `:inactivity_period` - Período de inatividade em segundos (padrão: 24 horas)
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @impl true
  def init(opts) do
    # Obtém o intervalo de limpeza das opções ou usa o padrão
    interval = Keyword.get(opts, :interval, @default_interval)
    
    # Obtém o período de inatividade das opções ou usa o padrão
    inactivity_period = Keyword.get(opts, :inactivity_period, @default_inactivity_period)
    
    # Agenda a primeira limpeza
    schedule_cleanup(interval)
    
    Logger.info("Worker de limpeza de sessões iniciado. Intervalo: #{interval}ms, Período de inatividade: #{inactivity_period}s", 
      module: __MODULE__
    )
    
    {:ok, %{interval: interval, inactivity_period: inactivity_period}}
  end
  
  @impl true
  def handle_info(:cleanup, state) do
    # Executa a limpeza de sessões expiradas
    case SessionManager.clean_expired_sessions() do
      {:ok, count} ->
        Logger.info("Limpeza de sessões expiradas concluída. Sessões removidas: #{count}", 
          module: __MODULE__
        )
        
      {:error, reason} ->
        Logger.error("Erro durante a limpeza de sessões expiradas: #{inspect(reason)}", 
          module: __MODULE__
        )
    end
    
    # Executa a limpeza de sessões inativas
    case SessionManager.clean_inactive_sessions(state.inactivity_period) do
      {:ok, count} ->
        Logger.info("Limpeza de sessões inativas concluída. Sessões removidas: #{count}", 
          module: __MODULE__
        )
        
      {:error, reason} ->
        Logger.error("Erro durante a limpeza de sessões inativas: #{inspect(reason)}", 
          module: __MODULE__
        )
    end
    
    # Agenda a próxima limpeza
    schedule_cleanup(state.interval)
    
    {:noreply, state}
  end
  
  # Agenda a próxima limpeza
  defp schedule_cleanup(interval) do
    Process.send_after(self(), :cleanup, interval)
  end
end
