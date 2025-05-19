defmodule DeeperHub.Accounts.Auth.EmailVerificationCleanupWorker do
  @moduledoc """
  Worker para limpeza periódica de tokens de verificação de e-mail.
  
  Este módulo implementa um processo GenServer que executa periodicamente
  a limpeza de tokens de verificação de e-mail expirados ou já utilizados,
  evitando o crescimento desnecessário da tabela.
  """
  
  use GenServer
  
  alias DeeperHub.Accounts.Auth.EmailVerification
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  
  # Intervalo padrão de limpeza: 12 horas
  @default_interval 12 * 60 * 60 * 1000
  
  @doc """
  Inicia o worker de limpeza de tokens de verificação de e-mail.
  
  ## Opções
    * `:interval` - Intervalo de limpeza em milissegundos (padrão: 12 horas)
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @impl true
  def init(opts) do
    # Obtém o intervalo de limpeza das opções ou usa o padrão
    interval = Keyword.get(opts, :interval, @default_interval)
    
    # Agenda a primeira limpeza
    schedule_cleanup(interval)
    
    Logger.info("Worker de limpeza de tokens de verificação de e-mail iniciado. Intervalo: #{interval}ms", 
      module: __MODULE__
    )
    
    {:ok, %{interval: interval}}
  end
  
  @impl true
  def handle_info(:cleanup, state) do
    # Executa a limpeza
    case EmailVerification.clean_tokens() do
      {:ok, count} ->
        Logger.info("Limpeza de tokens de verificação de e-mail concluída. Tokens removidos: #{count}", 
          module: __MODULE__
        )
        
      {:error, reason} ->
        Logger.error("Erro durante a limpeza de tokens de verificação de e-mail: #{inspect(reason)}", 
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
