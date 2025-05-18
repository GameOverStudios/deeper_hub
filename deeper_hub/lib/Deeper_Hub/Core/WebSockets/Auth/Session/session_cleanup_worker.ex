defmodule Deeper_Hub.Core.WebSockets.Auth.Session.SessionCleanupWorker do
  @moduledoc """
  Worker para limpeza periódica de sessões expiradas.
  
  Este módulo executa periodicamente a limpeza de:
  - Sessões expiradas
  - Tokens na blacklist que não são mais necessários
  """
  
  use GenServer
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.WebSockets.Auth.Session.SessionService
  alias Deeper_Hub.Core.WebSockets.Auth.Session.SessionPolicy
  alias Deeper_Hub.Core.WebSockets.Auth.Token.BlacklistService
  
  # Intervalo padrão de limpeza: 1 hora
  @default_cleanup_interval 3_600_000
  
  # API Pública
  
  @doc """
  Inicia o worker de limpeza.
  
  ## Parâmetros
  
    - `opts`: Opções de configuração
      - `:cleanup_interval`: Intervalo de limpeza em milissegundos
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Executa a limpeza manualmente.
  """
  def run_cleanup do
    GenServer.cast(__MODULE__, :cleanup)
  end
  
  # Callbacks do GenServer
  
  @impl true
  def init(opts) do
    Logger.info("Iniciando worker de limpeza de sessões", %{module: __MODULE__})
    
    # Obtém o intervalo de limpeza das opções ou usa o padrão
    cleanup_interval = Keyword.get(opts, :cleanup_interval, @default_cleanup_interval)
    
    # Agenda a primeira limpeza
    schedule_cleanup(cleanup_interval)
    
    {:ok, %{cleanup_interval: cleanup_interval}}
  end
  
  @impl true
  def handle_info(:cleanup, state) do
    # Executa a limpeza
    do_cleanup()
    
    # Agenda a próxima limpeza
    schedule_cleanup(state.cleanup_interval)
    
    {:noreply, state}
  end
  
  @impl true
  def handle_cast(:cleanup, state) do
    # Executa a limpeza
    do_cleanup()
    
    {:noreply, state}
  end
  
  # Funções privadas
  
  defp schedule_cleanup(interval) do
    Process.send_after(self(), :cleanup, interval)
  end
  
  defp do_cleanup do
    Logger.info("Executando limpeza de sessões expiradas", %{module: __MODULE__})
    
    # Obtém todas as sessões (em uma implementação real, isso seria paginado)
    cleanup_expired_sessions()
    
    # Limpa tokens na blacklist
    cleanup_blacklisted_tokens()
    
    Logger.info("Limpeza de sessões concluída", %{module: __MODULE__})
  end
  
  defp cleanup_expired_sessions do
    # Em uma implementação real, isso seria feito diretamente no banco de dados
    # com uma consulta eficiente. Para esta implementação em memória, precisamos
    # verificar cada sessão.
    
    # Obtém todas as sessões da tabela ETS
    all_sessions = :ets.tab2list(:sessions)
    now = DateTime.utc_now()
    
    # Filtra sessões expiradas ou inativas
    expired_sessions = Enum.filter(all_sessions, fn {_id, session} ->
      # Verifica se a sessão expirou
      expired = DateTime.compare(session.expires_at, now) == :lt
      
      # Verifica timeout por inatividade
      inactive = SessionPolicy.should_timeout?(session.last_activity)
      
      expired or inactive
    end)
    
    # Remove as sessões expiradas
    Enum.each(expired_sessions, fn {id, session} ->
      Logger.debug("Removendo sessão expirada", %{
        module: __MODULE__,
        session_id: id,
        user_id: session.user_id
      })
      
      SessionService.end_session(id, session.access_token, session.refresh_token)
    end)
    
    length(expired_sessions)
  end
  
  defp cleanup_blacklisted_tokens do
    # Delega para o serviço de blacklist
    BlacklistService.cleanup_expired_tokens()
  end
end
