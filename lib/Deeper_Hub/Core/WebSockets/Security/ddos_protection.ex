defmodule Deeper_Hub.Core.WebSockets.Security.DdosProtection do
  @moduledoc """
  Proteção contra ataques DDoS (Distributed Denial of Service) para WebSockets.
  
  Este módulo implementa mecanismos para detectar e mitigar ataques DDoS,
  incluindo limitação de taxa, detecção de anomalias e bloqueio temporário.
  """
  
  alias Deeper_Hub.Core.Logger
  
  # Configurações padrão
  @default_rate_limit 100     # Máximo de requisições por intervalo
  @default_time_window 60_000 # Intervalo de tempo em milissegundos (1 minuto)
  @default_block_time 300_000 # Tempo de bloqueio em milissegundos (5 minutos)
  
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
    rate_limit = Keyword.get(opts, :rate_limit, @default_rate_limit)
    time_window = Keyword.get(opts, :time_window, @default_time_window)
    
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
          block_ip(ip)
          
          Logger.warning("IP bloqueado por exceder limite de requisições", %{
            module: __MODULE__,
            ip: ip,
            count: count,
            rate_limit: rate_limit
          })
          
          {:error, :rate_limited, @default_block_time}
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
  
  @doc """
  Bloqueia um IP temporariamente.
  
  ## Parâmetros
  
    - `ip`: Endereço IP a ser bloqueado
    - `duration`: Duração do bloqueio em milissegundos (padrão: 5 minutos)
  
  ## Retorno
  
    - `:ok` se o bloqueio for bem-sucedido
  """
  def block_ip(ip, duration \\ @default_block_time) do
    current_time = :os.system_time(:millisecond)
    unblock_time = current_time + duration
    
    :ets.insert(@ets_table, {{:blocked, ip}, unblock_time})
    
    Logger.info("IP bloqueado temporariamente", %{
      module: __MODULE__,
      ip: ip,
      duration: duration,
      unblock_time: unblock_time
    })
    
    :ok
  end
  
  @doc """
  Desbloqueia um IP.
  
  ## Parâmetros
  
    - `ip`: Endereço IP a ser desbloqueado
  
  ## Retorno
  
    - `:ok` se o desbloqueio for bem-sucedido
  """
  def unblock_ip(ip) do
    :ets.delete(@ets_table, {:blocked, ip})
    
    Logger.info("IP desbloqueado", %{
      module: __MODULE__,
      ip: ip
    })
    
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
  Detecta anomalias no padrão de tráfego de um IP.
  
  ## Parâmetros
  
    - `ip`: Endereço IP a ser analisado
    - `opts`: Opções adicionais
  
  ## Retorno
  
    - `{:ok, score}` com a pontuação de anomalia (0-100)
    - `{:error, reason}` se a análise falhar
  """
  def detect_anomalies(ip, _opts \\ []) do
    # Implementação simplificada de detecção de anomalias
    # Em um sistema real, isso seria mais sofisticado
    
    counter_key = {:counter, ip}
    case :ets.lookup(@ets_table, counter_key) do
      [{^counter_key, count, timestamps}] ->
        # Calcula a taxa de requisições por segundo
        current_time = :os.system_time(:millisecond)
        window_start = current_time - @default_time_window
        
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
            @default_time_window
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
          
          rate_score = min(100, num_requests / @default_rate_limit * 100)
          
          regularity_score = if avg_time_diff > 0 do
            min(100, 100 - min(100, std_dev / avg_time_diff * 100))
          else
            100
          end
          
          # Combina as pontuações
          anomaly_score = (rate_score + regularity_score) / 2
          
          {:ok, anomaly_score}
        end
        
      [] ->
        {:ok, 0}
    end
  end
  
  # Funções privadas
  
  defp cleanup_loop do
    # Remove entradas expiradas periodicamente
    cleanup_expired_entries()
    
    # Executa novamente após um intervalo
    :timer.sleep(60_000) # 1 minuto
    cleanup_loop()
  end
  
  defp cleanup_expired_entries do
    current_time = :os.system_time(:millisecond)
    window_start = current_time - @default_time_window
    
    # Limpa contadores expirados
    :ets.match(@ets_table, {{:counter, :'$1'}, :'$2', :'$3'})
    |> Enum.each(fn [ip, count, timestamps] ->
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
