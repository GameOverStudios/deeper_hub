defmodule DeeperHub.Core.Security.IPReputation do
  @moduledoc """
  Sistema de reputação de IPs para o DeeperHub.
  
  Este módulo gerencia a reputação de IPs com base em seu comportamento,
  permitindo decisões de segurança mais inteligentes e adaptativas.
  
  A pontuação de reputação varia de 0 a 100, onde:
  - 0-30: Alto risco (bloqueado automaticamente)
  - 31-60: Médio risco (sob vigilância)
  - 61-100: Baixo risco (permitido)
  """
  
  use GenServer
  
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  alias DeeperHub.Core.Security
  alias DeeperHub.Core.Security.AnomalyDetector
  
  # Tabela ETS para armazenar reputações de IPs
  @reputation_table :deeper_hub_ip_reputation
  
  # Valores padrão que podem ser sobrescritos pela configuração
  @default_config [
    # Intervalo de verificação de reputação (5 minutos)
    check_interval: 300_000,
    
    # Limites de reputação
    high_risk_threshold: 30,
    medium_risk_threshold: 60,
    
    # Tempo mínimo de bloqueio (24 horas)
    min_block_time: 86400
  ]
  
  #
  # API Pública
  #
  
  @doc """
  Inicia o sistema de reputação de IPs.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Obtém a reputação de um IP.
  
  ## Parâmetros
  
  - `ip` - Endereço IP
  
  ## Retorno
  
  - Mapa com informações de reputação
  """
  def get_reputation(ip) do
    case :ets.lookup(@reputation_table, ip) do
      [{^ip, reputation}] -> reputation
      [] -> 
        # Se não houver reputação registrada, obtém do detector de anomalias
        score = AnomalyDetector.get_reputation(ip)
        %{
          ip: ip,
          score: score,
          risk_level: calculate_risk_level(score),
          last_updated: :os.system_time(:second),
          events: []
        }
    end
  end
  
  @doc """
  Ajusta a reputação de um IP.
  
  ## Parâmetros
  
  - `ip` - Endereço IP
  - `adjustment` - Valor de ajuste (positivo ou negativo)
  - `reason` - Motivo do ajuste
  
  ## Retorno
  
  - Nova pontuação de reputação
  """
  def adjust_reputation(ip, adjustment, reason) do
    GenServer.call(__MODULE__, {:adjust_reputation, ip, adjustment, reason})
  end
  
  @doc """
  Verifica se um IP deve ser bloqueado com base em sua reputação.

  ## Parâmetros

  - `ip` - Endereço IP

  ## Retorno

  - `true` se o IP deve ser bloqueado, `false` caso contrário
  """
  def should_block?(ip) do
    config = Application.get_env(:deeper_hub, :ip_reputation, @default_config)
    high_risk_threshold = config[:high_risk_threshold]
    
    reputation = get_reputation(ip)
    reputation.score <= high_risk_threshold
  end
  
  #
  # Callbacks do GenServer
  #
  
  @impl true
  def init(_opts) do
    # Inicializa a tabela ETS para reputações
    create_reputation_table()
    
    # Carrega a configuração
    config = Application.get_env(:deeper_hub, :ip_reputation, @default_config)
    
    # Agenda a verificação periódica
    schedule_check(config[:check_interval])
    
    Logger.info("Sistema de reputação de IPs iniciado", module: __MODULE__)
    
    {:ok, %{config: config}}
  end
  
  @impl true
  def handle_call({:adjust_reputation, ip, adjustment, reason}, _from, state) do
    now = :os.system_time(:second)
    
    # Obtém a reputação atual
    current = get_reputation(ip)
    
    # Calcula a nova pontuação
    new_score = max(0, min(100, current.score + adjustment))
    
    # Registra o evento
    event = %{
      timestamp: now,
      adjustment: adjustment,
      reason: reason,
      previous_score: current.score,
      new_score: new_score
    }
    
    # Atualiza a reputação
    updated = %{
      ip: ip,
      score: new_score,
      risk_level: calculate_risk_level(new_score),
      last_updated: now,
      events: [event | (current.events || [])]
    }
    
    :ets.insert(@reputation_table, {ip, updated})
    
    # Registra o ajuste
    Logger.info("Reputação de IP ajustada: #{ip}", 
                module: __MODULE__,
                adjustment: adjustment,
                reason: reason,
                previous_score: current.score,
                new_score: new_score)
    
    # Verifica se o IP deve ser bloqueado
    high_risk_threshold = state.config[:high_risk_threshold]
    if new_score <= high_risk_threshold and current.score > high_risk_threshold do
      Security.block_ip(ip, "Baixa reputação (#{new_score})")
    end
    
    {:reply, new_score, state}
  end
  
  @impl true
  def handle_info(:check_reputations, state) do
    check_all_reputations(state.config)
    schedule_check(state.config[:check_interval])
    {:noreply, state}
  end
  
  #
  # Funções privadas
  #
  
  # Cria a tabela ETS para reputações
  defp create_reputation_table do
    try do
      :ets.new(@reputation_table, [:named_table, :public, :set, {:read_concurrency, true}, {:write_concurrency, true}])
      Logger.debug("Tabela ETS #{@reputation_table} criada com sucesso", module: __MODULE__)
    rescue
      ArgumentError -> 
        Logger.debug("Tabela ETS #{@reputation_table} já existe", module: __MODULE__)
    end
  end
  
  # Agenda a verificação periódica
  defp schedule_check(interval) do
    Process.send_after(self(), :check_reputations, interval)
  end
  
  # Verifica todas as reputações
  defp check_all_reputations(config) do
    # Obtém todos os IPs bloqueados
    blocked_ips = Security.get_blocked_ips()
    
    # Verifica cada IP bloqueado
    Enum.each(blocked_ips, fn ip ->
      reputation = get_reputation(ip)
      
      # Se a reputação melhorou, considera desbloquear
      if reputation.score > config[:high_risk_threshold] do
        # Tempo mínimo de bloqueio (configurável, padrão 24 horas)
        min_block_time = config[:min_block_time]
        
        # Verifica se o IP está bloqueado há tempo suficiente
        block_event = Enum.find(reputation.events, fn event ->
          event.reason == "Baixa reputação" and event.adjustment < 0
        end)
        
        if block_event do
          block_time = :os.system_time(:second) - block_event.timestamp
          
          if block_time > min_block_time do
            Security.unblock_ip(ip, "Reputação melhorada (#{reputation.score})")
          end
        end
      end
    end)
    
    Logger.debug("Verificação de reputações concluída", module: __MODULE__)
  end
  
  # Calcula o nível de risco com base na pontuação
  defp calculate_risk_level(score) do
    config = Application.get_env(:deeper_hub, :ip_reputation, @default_config)
    high_risk_threshold = config[:high_risk_threshold]
    medium_risk_threshold = config[:medium_risk_threshold]
    
    cond do
      score <= high_risk_threshold -> :high
      score <= medium_risk_threshold -> :medium
      true -> :low
    end
  end
end
