defmodule Deeper_Hub.Core.WebSockets.Security.DdosProtection do
  @moduledoc """
  Proteção contra ataques DDoS (Distributed Denial of Service) para WebSockets.
  
  Este módulo implementa mecanismos para detectar e mitigar ataques DDoS,
  incluindo limitação de taxa, detecção de anomalias e bloqueio temporário.
  """
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.WebSockets.Security.SecurityConfig
  
  # Tabela ETS para armazenar contadores de requisições
  @ets_table :ddos_protection_counters
  
  @doc """
  Inicializa o módulo de proteção DDoS.
  
  Deve ser chamado durante a inicialização da aplicação.
  
  ## Retorno
  
    - `:ok` se a inicialização for bem-sucedida
  """
  def init do
    # Cria a tabela ETS se não existir
    if :ets.info(@ets_table) == :undefined do
      :ets.new(@ets_table, [:named_table, :set, :public])
    end
    
    # Inicia o processo de limpeza periódica
    spawn(fn -> cleanup_loop() end)
    
    :ok
  end
  
  @doc """
  Verifica se uma requisição deve ser permitida com base nas políticas de limitação de taxa.
  
  ## Parâmetros
  
    - `ip`: Endereço IP do cliente
    - `opts`: Opções adicionais
      - `:rate_limit` - Limite de requisições (padrão: 100)
      - `:time_window` - Janela de tempo em ms (padrão: 60000)
  
  ## Retorno
  
    - `{:ok, remaining}` se a requisição for permitida, com o número restante de requisições
    - `{:error, :rate_limited, retry_after}` se a requisição exceder o limite
  """
  def check_rate_limit(ip, opts \\ []) do
    # Verifica se o módulo está habilitado
    enabled = SecurityConfig.get_ddos_config(:enabled, true)
    
    if not enabled do
      {:ok, 999} # Valor alto para indicar que não há limite
    else
      # Obtém configurações
      rate_limit = Keyword.get(opts, :rate_limit, 
                   SecurityConfig.get_ddos_config(:rate_limit, 100))
      time_window = Keyword.get(opts, :time_window, 
                    SecurityConfig.get_ddos_config(:time_window, 60_000))
      block_time = SecurityConfig.get_ddos_config(:block_time, 300_000)
      
      current_time = :os.system_time(:millisecond)
      window_start = current_time - time_window
      
      # Verifica se o IP está bloqueado
      case get_block_info(ip) do
        {:blocked, unblock_time} ->
          retry_after = max(0, unblock_time - current_time)
          
          Logger.warning("Requisição bloqueada por limitação de taxa", %{
            module: __MODULE__,
            ip: ip,
            retry_after: retry_after
          })
          
          {:error, :rate_limited, retry_after}
          
        :not_blocked ->
          # Obtém ou cria o contador para este IP
          counter_key = {:counter, ip}
          counter = case :ets.lookup(@ets_table, counter_key) do
            [{^counter_key, count, timestamps}] -> 
              # Filtra timestamps dentro da janela atual
              current_timestamps = Enum.filter(timestamps, fn ts -> ts >= window_start end)
              {count, current_timestamps}
              
            [] -> 
              {0, []}
          end
          
          {count, timestamps} = counter
          
          # Verifica se o limite foi excedido
          if count >= rate_limit do
            # Bloqueia o IP temporariamente
            block_ip(ip, block_time)
            
            Logger.warning("IP bloqueado por exceder limite de requisições", %{
              module: __MODULE__,
              ip: ip,
              count: count,
              rate_limit: rate_limit
            })
            
            # Publica evento de segurança
            if Code.ensure_loaded?(Deeper_Hub.Core.EventBus) do
              Deeper_Hub.Core.EventBus.publish(:security_violation, %{
                type: :ddos_protection,
                subtype: :rate_limit_exceeded,
                ip: ip,
                count: count,
                rate_limit: rate_limit,
                block_time: block_time,
                timestamp: current_time
              })
            end
            
            {:error, :rate_limited, block_time}
          else
            # Incrementa o contador
            new_count = count + 1
            new_timestamps = [current_time | timestamps]
            
            :ets.insert(@ets_table, {counter_key, new_count, new_timestamps})
            
            remaining = rate_limit - new_count
            
            {:ok, remaining}
          end
      end
    end
  end
  
  @doc """
  Bloqueia um IP temporariamente.
  
  ## Parâmetros
  
    - `ip`: Endereço IP a ser bloqueado
    - `duration`: Duração do bloqueio em milissegundos (padrão: 5 minutos)
  
  ## Retorno
  
    - `:ok` se o bloqueio for bem-sucedido
  """
  def block_ip(ip, duration \\ nil) do
    # Obtém duração do bloqueio da configuração se não fornecida
    block_time = duration || SecurityConfig.get_ddos_config(:block_time, 300_000)
    current_time = :os.system_time(:millisecond)
    unblock_time = current_time + block_time
    
    # Armazena o tempo de desbloqueio
    :ets.insert(@ets_table, {{:blocked, ip}, unblock_time})
    
    # Publica evento de bloqueio
    if Code.ensure_loaded?(Deeper_Hub.Core.EventBus) do
      Deeper_Hub.Core.EventBus.publish(:security_action, %{
        type: :ddos_protection,
        subtype: :ip_blocked,
        ip: ip,
        block_time: block_time,
        unblock_time: unblock_time,
        timestamp: current_time
      })
    end
    
    :ok
  end
  
  @doc """
  Desbloqueia um IP bloqueado.
  
  ## Parâmetros
  
    - `ip`: Endereço IP a ser desbloqueado
  
  ## Retorno
  
    - `:ok` se o desbloqueio for bem-sucedido
  """
  def unblock_ip(ip) do
    # Remove o bloqueio
    :ets.delete(@ets_table, {:blocked, ip})
    
    # Publica evento de desbloqueio
    if Code.ensure_loaded?(Deeper_Hub.Core.EventBus) do
      Deeper_Hub.Core.EventBus.publish(:security_action, %{
        type: :ddos_protection,
        subtype: :ip_unblocked,
        ip: ip,
        timestamp: :os.system_time(:millisecond)
      })
    end
    
    :ok
  end
  
  @doc """
  Verifica se um IP está bloqueado.
  
  ## Parâmetros
  
    - `ip`: Endereço IP a ser verificado
  
  ## Retorno
  
    - `{:blocked, unblock_time}` se o IP estiver bloqueado
    - `:not_blocked` se o IP não estiver bloqueado
  """
  def get_block_info(ip) do
    case :ets.lookup(@ets_table, {:blocked, ip}) do
      [{_, unblock_time}] ->
        current_time = :os.system_time(:millisecond)
        
        if current_time >= unblock_time do
          # O bloqueio expirou, remove-o
          unblock_ip(ip)
          :not_blocked
        else
          {:blocked, unblock_time}
        end
        
      [] ->
        :not_blocked
    end
  end
  
  @doc """
  Detecta comportamentos anômalos que podem indicar ataques DDoS.
  
  ## Parâmetros
  
    - `ip`: Endereço IP a ser analisado
    - `opts`: Opções adicionais
  
  ## Retorno
  
    - `{:ok, score}` com a pontuação de anomalia (0-100)
    - `{:error, reason}` se a análise falhar
  """
  def detect_anomalies(ip, _opts \\ []) do
    # Verifica se o módulo está habilitado
    enabled = SecurityConfig.get_ddos_config(:enabled, true)
    
    if not enabled do
      {:ok, 0} # Sem anomalias se o módulo estiver desabilitado
    else
      # Obtém configurações
      time_window = SecurityConfig.get_ddos_config(:time_window, 60_000)
      anomaly_threshold = SecurityConfig.get_ddos_config(:anomaly_threshold, 75)
      
      # Implementação simplificada de detecção de anomalias
      # Em um sistema real, isso seria mais sofisticado
      
      counter_key = {:counter, ip}
      case :ets.lookup(@ets_table, counter_key) do
        [{^counter_key, _count, timestamps}] ->
          # Calcula a taxa de requisições por segundo
          current_time = :os.system_time(:millisecond)
          window_start = current_time - time_window
          
          recent_timestamps = Enum.filter(timestamps, fn ts -> ts >= window_start end)
          num_requests = length(recent_timestamps)
          
          if num_requests == 0 do
            {:ok, 0}
          else
            # Calcula o tempo médio entre requisições
            sorted_timestamps = Enum.sort(recent_timestamps, :desc)
            
            time_diffs = Enum.zip(Enum.drop(sorted_timestamps, 1), sorted_timestamps)
            |> Enum.map(fn {t1, t2} -> abs(t2 - t1) end)
            
            avg_time_diff = if length(time_diffs) > 0 do
              Enum.sum(time_diffs) / length(time_diffs)
            else
              SecurityConfig.get_ddos_config(:time_window, 60_000)
            end
            
            # Calcula o desvio padrão
            variance = if length(time_diffs) > 1 do
              mean = avg_time_diff
              Enum.map(time_diffs, fn diff -> :math.pow(diff - mean, 2) end)
              |> Enum.sum()
              |> Kernel./(length(time_diffs) - 1)
            else
              0
            end
            
            std_dev = :math.sqrt(variance)
            
            # Calcula a pontuação de anomalia (0-100)
            # Baixo desvio padrão indica padrão regular (possivelmente automatizado)
            # Alta taxa de requisições também aumenta a pontuação
            
            rate_limit = SecurityConfig.get_ddos_config(:rate_limit, 100)
            rate_score = min(100, num_requests / rate_limit * 100)
            
            regularity_score = if avg_time_diff > 0 do
              min(100, 100 - min(100, std_dev / avg_time_diff * 100))
            else
              100
            end
            
            # Combina as pontuações
            anomaly_score = (rate_score + regularity_score) / 2
            
            # Verifica se a pontuação está acima do limiar
            if anomaly_score >= anomaly_threshold do
              # Publica evento de anomalia detectada
              if Code.ensure_loaded?(Deeper_Hub.Core.EventBus) do
                Deeper_Hub.Core.EventBus.publish(:security_alert, %{
                  type: :ddos_protection,
                  subtype: :anomaly_detected,
                  ip: ip,
                  score: anomaly_score,
                  threshold: anomaly_threshold,
                  timestamp: current_time
                })
              end
            end
            
            {:ok, anomaly_score}
          end
          
        [] ->
          {:ok, 0}
      end
    end
  end
  
  @doc """
  Detecta anomalias para um usuário específico.
  
  ## Parâmetros
  
    - `ip`: Endereço IP do cliente
    - `user_id`: ID do usuário
  
  ## Retorno
  
    - `{:ok, score}` com a pontuação de anomalia (0-100)
    - `{:error, reason}` se a análise falhar
  """
  def detect_anomaly(ip, _user_id) do
    # Implementação simplificada que delega para detect_anomalies
    detect_anomalies(ip)
  end
  
  @doc """
  Registra um padrão de requisição para análise posterior.
  
  ## Parâmetros
  
    - `ip`: Endereço IP do cliente
    - `user_id`: ID do usuário
    - `method`: Método HTTP
    - `path`: Caminho da requisição
  
  ## Retorno
  
    - `:ok` se o registro for bem-sucedido
  """
  def record_request_pattern(ip, _user_id, _method, _path) do
    # Implementação simplificada que apenas incrementa o contador
    check_rate_limit(ip)
    :ok
  end
  
  @doc """
  Limpa o estado do módulo, removendo todos os contadores e bloqueios.
  
  ## Retorno
  
    - `:ok` se a limpeza for bem-sucedida
  """
  def reset_state do
    # Limpa a tabela ETS
    :ets.delete_all_objects(@ets_table)
    :ok
  end
  
  # Funções privadas
  
  defp cleanup_loop do
    # Remove entradas expiradas periodicamente
    cleanup_expired_entries()
    
    # Executa novamente após um intervalo
    cleanup_interval = SecurityConfig.get_ddos_config(:cleanup_interval, 60_000)
    :timer.sleep(cleanup_interval)
    cleanup_loop()
  end
  
  defp cleanup_expired_entries do
    current_time = :os.system_time(:millisecond)
    time_window = SecurityConfig.get_ddos_config(:time_window, 60_000)
    window_start = current_time - time_window
    
    # Limpa contadores expirados
    :ets.match(@ets_table, {{:counter, :'$1'}, :'$2', :'$3'})
    |> Enum.each(fn [ip, _count, timestamps] ->
      current_timestamps = Enum.filter(timestamps, fn ts -> ts >= window_start end)
      
      if current_timestamps == [] do
        # Remove entradas sem timestamps recentes
        :ets.delete(@ets_table, {:counter, ip})
      else
        # Atualiza com apenas timestamps recentes
        :ets.insert(@ets_table, {{:counter, ip}, length(current_timestamps), current_timestamps})
      end
    end)
    
    # Limpa bloqueios expirados
    :ets.match(@ets_table, {{:blocked, :'$1'}, :'$2'})
    |> Enum.each(fn [ip, unblock_time] ->
      if current_time >= unblock_time do
        unblock_ip(ip)
      end
    end)
  end
end
