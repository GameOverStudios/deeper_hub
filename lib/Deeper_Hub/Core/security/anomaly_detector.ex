defmodule DeeperHub.Core.Security.AnomalyDetector do
  @moduledoc """
  Módulo para detecção de anomalias e padrões de ataque.
  
  Este módulo monitora o tráfego da aplicação e identifica padrões
  que podem indicar tentativas de ataque, como:
  
  - Múltiplas tentativas de login falhas
  - Padrões de requisição suspeitos
  - Comportamento anômalo de IPs
  - Tentativas de exploração de vulnerabilidades conhecidas
  """
  
  use GenServer
  
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  alias DeeperHub.Core.Security
  
  # Configurações padrão
  @default_config [
    # Limite de tentativas de login falhas antes de considerar um ataque
    login_failure_threshold: 5,
    # Janela de tempo para considerar tentativas de login (em segundos)
    login_failure_window: 300,
    # Limite de requisições 404 antes de considerar um ataque
    not_found_threshold: 10,
    # Janela de tempo para considerar requisições 404 (em segundos)
    not_found_window: 60,
    # Limite de requisições com payload malicioso antes de considerar um ataque
    malicious_payload_threshold: 3,
    # Janela de tempo para considerar requisições com payload malicioso (em segundos)
    malicious_payload_window: 600
  ]
  
  # Tabela ETS para armazenar estatísticas de IPs
  @stats_table :deeper_hub_anomaly_stats
  
  # Intervalo de limpeza de estatísticas antigas (1 hora)
  @cleanup_interval 3_600_000
  
  #
  # API Pública
  #
  
  @doc """
  Inicia o detector de anomalias.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Registra uma tentativa de login falha.
  
  ## Parâmetros
  
  - `ip` - Endereço IP do cliente
  - `username` - Nome de usuário tentado
  """
  def register_login_failure(ip, username) do
    GenServer.cast(__MODULE__, {:login_failure, ip, username})
  end
  
  @doc """
  Registra uma requisição não encontrada (404).
  
  ## Parâmetros
  
  - `ip` - Endereço IP do cliente
  - `path` - Caminho da requisição
  """
  def register_not_found(ip, path) do
    GenServer.cast(__MODULE__, {:not_found, ip, path})
  end
  
  @doc """
  Registra uma requisição com payload potencialmente malicioso.
  
  ## Parâmetros
  
  - `ip` - Endereço IP do cliente
  - `path` - Caminho da requisição
  - `reason` - Motivo da detecção
  """
  def register_malicious_payload(ip, path, reason) do
    GenServer.cast(__MODULE__, {:malicious_payload, ip, path, reason})
  end
  
  @doc """
  Obtém a pontuação de reputação de um IP.
  
  ## Parâmetros
  
  - `ip` - Endereço IP do cliente
  
  ## Retorno
  
  - Pontuação de reputação (0-100, onde 0 é o pior e 100 é o melhor)
  """
  def get_reputation(ip) do
    case :ets.lookup(@stats_table, ip) do
      [{^ip, stats}] -> calculate_reputation(stats)
      [] -> 100 # IP sem histórico tem reputação máxima
    end
  end
  
  #
  # Callbacks do GenServer
  #
  
  @impl true
  def init(_opts) do
    # Inicializa a tabela ETS para estatísticas
    create_stats_table()
    
    # Agenda a limpeza periódica
    schedule_cleanup()
    
    # Carrega a configuração
    config = Application.get_env(:deeper_hub, :anomaly_detection, @default_config)
    
    Logger.info("Detector de anomalias iniciado", module: __MODULE__)
    
    {:ok, %{config: config}}
  end
  
  @impl true
  def handle_cast({:login_failure, ip, username}, state) do
    now = :os.system_time(:second)
    
    # Obtém ou cria estatísticas para o IP
    stats = get_or_create_stats(ip)
    
    # Adiciona a falha de login às estatísticas
    login_failures = stats.login_failures || []
    updated_failures = [{now, username} | login_failures]
    
    # Atualiza as estatísticas
    updated_stats = Map.put(stats, :login_failures, updated_failures)
    :ets.insert(@stats_table, {ip, updated_stats})
    
    # Verifica se excedeu o limite
    check_login_failures(ip, updated_stats, state.config)
    
    {:noreply, state}
  end
  
  @impl true
  def handle_cast({:not_found, ip, path}, state) do
    now = :os.system_time(:second)
    
    # Obtém ou cria estatísticas para o IP
    stats = get_or_create_stats(ip)
    
    # Adiciona a requisição 404 às estatísticas
    not_founds = stats.not_founds || []
    updated_not_founds = [{now, path} | not_founds]
    
    # Atualiza as estatísticas
    updated_stats = Map.put(stats, :not_founds, updated_not_founds)
    :ets.insert(@stats_table, {ip, updated_stats})
    
    # Verifica se excedeu o limite
    check_not_founds(ip, updated_stats, state.config)
    
    {:noreply, state}
  end
  
  @impl true
  def handle_cast({:malicious_payload, ip, path, reason}, state) do
    now = :os.system_time(:second)
    
    # Obtém ou cria estatísticas para o IP
    stats = get_or_create_stats(ip)
    
    # Adiciona o payload malicioso às estatísticas
    payloads = stats.malicious_payloads || []
    updated_payloads = [{now, path, reason} | payloads]
    
    # Atualiza as estatísticas
    updated_stats = Map.put(stats, :malicious_payloads, updated_payloads)
    :ets.insert(@stats_table, {ip, updated_stats})
    
    # Verifica se excedeu o limite
    check_malicious_payloads(ip, updated_stats, state.config)
    
    {:noreply, state}
  end
  
  @impl true
  def handle_info(:cleanup, state) do
    cleanup_old_stats()
    schedule_cleanup()
    {:noreply, state}
  end
  
  #
  # Funções privadas
  #
  
  # Cria a tabela ETS para estatísticas
  defp create_stats_table do
    try do
      :ets.new(@stats_table, [:named_table, :public, :set, {:read_concurrency, true}, {:write_concurrency, true}])
      Logger.debug("Tabela ETS #{@stats_table} criada com sucesso", module: __MODULE__)
    rescue
      ArgumentError -> 
        Logger.debug("Tabela ETS #{@stats_table} já existe", module: __MODULE__)
    end
  end
  
  # Agenda a limpeza periódica
  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end
  
  # Limpa estatísticas antigas
  defp cleanup_old_stats do
    now = :os.system_time(:second)
    
    # Remove entradas de login falhas antigas
    :ets.foldl(
      fn {ip, stats}, _ ->
        updated_stats = stats
        |> clean_old_entries(:login_failures, now - 86400) # 24 horas
        |> clean_old_entries(:not_founds, now - 3600) # 1 hora
        |> clean_old_entries(:malicious_payloads, now - 86400) # 24 horas
        
        :ets.insert(@stats_table, {ip, updated_stats})
      end,
      nil,
      @stats_table
    )
    
    Logger.debug("Limpeza de estatísticas antigas concluída", module: __MODULE__)
  end
  
  # Remove entradas antigas de uma lista
  defp clean_old_entries(stats, key, cutoff_time) do
    case Map.get(stats, key) do
      nil -> stats
      entries ->
        # Filtra apenas entradas mais recentes que o tempo de corte
        updated_entries = Enum.filter(entries, fn
          {timestamp, _} -> timestamp > cutoff_time
          {timestamp, _, _} -> timestamp > cutoff_time
        end)
        
        Map.put(stats, key, updated_entries)
    end
  end
  
  # Obtém ou cria estatísticas para um IP
  defp get_or_create_stats(ip) do
    case :ets.lookup(@stats_table, ip) do
      [{^ip, stats}] -> stats
      [] -> %{
        login_failures: [],
        not_founds: [],
        malicious_payloads: [],
        blocks: []
      }
    end
  end
  
  # Verifica se o número de falhas de login excedeu o limite
  defp check_login_failures(ip, stats, config) do
    now = :os.system_time(:second)
    window = now - config[:login_failure_window]
    
    # Conta falhas dentro da janela de tempo
    recent_failures = Enum.count(stats.login_failures, fn {timestamp, _} -> 
      timestamp > window
    end)
    
    if recent_failures >= config[:login_failure_threshold] do
      # Registra o bloqueio
      register_block(ip, "Múltiplas tentativas de login falhas", recent_failures)
      
      # Bloqueia o IP
      Security.block_ip(ip, "Múltiplas tentativas de login falhas (#{recent_failures} em #{config[:login_failure_window]} segundos)")
    end
  end
  
  # Verifica se o número de requisições 404 excedeu o limite
  defp check_not_founds(ip, stats, config) do
    now = :os.system_time(:second)
    window = now - config[:not_found_window]
    
    # Conta requisições 404 dentro da janela de tempo
    recent_not_founds = Enum.count(stats.not_founds, fn {timestamp, _} -> 
      timestamp > window
    end)
    
    if recent_not_founds >= config[:not_found_threshold] do
      # Registra o bloqueio
      register_block(ip, "Múltiplas requisições 404", recent_not_founds)
      
      # Bloqueia o IP
      Security.block_ip(ip, "Múltiplas requisições 404 (#{recent_not_founds} em #{config[:not_found_window]} segundos)")
    end
  end
  
  # Verifica se o número de payloads maliciosos excedeu o limite
  defp check_malicious_payloads(ip, stats, config) do
    now = :os.system_time(:second)
    window = now - config[:malicious_payload_window]
    
    # Conta payloads maliciosos dentro da janela de tempo
    recent_payloads = Enum.count(stats.malicious_payloads, fn {timestamp, _, _} -> 
      timestamp > window
    end)
    
    if recent_payloads >= config[:malicious_payload_threshold] do
      # Registra o bloqueio
      register_block(ip, "Múltiplos payloads maliciosos", recent_payloads)
      
      # Bloqueia o IP
      Security.block_ip(ip, "Múltiplos payloads maliciosos (#{recent_payloads} em #{config[:malicious_payload_window]} segundos)")
    end
  end
  
  # Registra um bloqueio nas estatísticas do IP
  defp register_block(ip, reason, count) do
    now = :os.system_time(:second)
    
    # Obtém estatísticas atuais
    stats = get_or_create_stats(ip)
    
    # Adiciona o bloqueio às estatísticas
    blocks = stats.blocks || []
    updated_blocks = [{now, reason, count} | blocks]
    
    # Atualiza as estatísticas
    updated_stats = Map.put(stats, :blocks, updated_blocks)
    :ets.insert(@stats_table, {ip, updated_stats})
    
    Logger.warn("IP bloqueado por comportamento suspeito: #{ip}", 
                module: __MODULE__,
                reason: reason,
                count: count)
  end
  
  # Calcula a pontuação de reputação de um IP
  defp calculate_reputation(stats) do
    now = :os.system_time(:second)
    
    # Pesos para cada tipo de evento
    login_failure_weight = 5
    not_found_weight = 2
    malicious_payload_weight = 10
    block_weight = 20
    
    # Janelas de tempo para considerar eventos
    login_window = now - 86400 # 24 horas
    not_found_window = now - 3600 # 1 hora
    malicious_window = now - 86400 # 24 horas
    block_window = now - 604800 # 7 dias
    
    # Conta eventos recentes
    login_failures = count_recent_events(stats.login_failures || [], login_window)
    not_founds = count_recent_events(stats.not_founds || [], not_found_window)
    malicious_payloads = count_recent_events(stats.malicious_payloads || [], malicious_window)
    blocks = count_recent_events(stats.blocks || [], block_window)
    
    # Calcula a pontuação
    penalty = login_failures * login_failure_weight +
              not_founds * not_found_weight +
              malicious_payloads * malicious_payload_weight +
              blocks * block_weight
    
    # Limita a pontuação entre 0 e 100
    max(0, min(100, 100 - penalty))
  end
  
  # Conta eventos recentes
  defp count_recent_events(events, cutoff_time) do
    Enum.count(events, fn
      {timestamp, _} -> timestamp > cutoff_time
      {timestamp, _, _} -> timestamp > cutoff_time
    end)
  end
end
