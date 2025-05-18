defmodule DeeperHub.LoadTest.RealTimeMonitor do
  @moduledoc """
  Monitor em tempo real para testes de carga do DeeperHub.
  
  Este módulo fornece uma interface para monitorar o desempenho do sistema
  durante os testes de carga, exibindo métricas em tempo real no terminal.
  """
  
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  
  @doc """
  Inicia o monitor em tempo real para um teste de carga.
  
  ## Parâmetros
  
  - `test_name` - Nome do teste sendo monitorado
  - `config` - Configuração do teste
  
  ## Retorno
  
  - `{:ok, pid}` - Monitor iniciado com sucesso
  - `{:error, reason}` - Falha ao iniciar o monitor
  """
  def start_link(test_name, config) do
    pid = spawn_link(fn ->
      # Inicializa o estado do monitor
      state = %{
        test_name: test_name,
        config: config,
        start_time: :os.timestamp(),
        stats: %{
          connections: %{
            attempted: 0,
            successful: 0,
            failed: 0,
            current: 0
          },
          messages: %{
            sent: 0,
            received: 0,
            failed: 0
          },
          latency: %{
            min: nil,
            max: nil,
            total: 0,
            samples: 0
          },
          system: %{
            cpu_usage: 0,
            memory_usage: 0,
            process_count: 0
          }
        },
        last_update: :os.timestamp()
      }
      
      # Registra o processo para facilitar o envio de atualizações
      Process.register(self(), :load_test_monitor)
      
      # Exibe o cabeçalho inicial
      print_header(state)
      
      # Agenda a primeira atualização
      Process.send_after(self(), :update_display, 1000)
      
      # Inicia o loop do monitor
      monitor_loop(state)
    end)
    
    {:ok, pid}
  end
  
  @doc """
  Atualiza as estatísticas do monitor.
  
  ## Parâmetros
  
  - `update` - Atualização a ser aplicada às estatísticas
  """
  def update_stats(update) do
    case Process.whereis(:load_test_monitor) do
      nil -> :ok  # Ignora se o processo não existir
      pid -> send(pid, {:update_stats, update})
    end
  end
  
  @doc """
  Finaliza o monitor e retorna as estatísticas finais.
  
  ## Retorno
  
  - `{:ok, stats}` - Estatísticas finais do teste
  - `{:error, reason}` - Falha ao obter estatísticas
  """
  def stop do
    case Process.whereis(:load_test_monitor) do
      nil -> 
        {:error, :not_running}
        
      pid -> 
        ref = Process.monitor(pid)
        send(pid, {:stop, self()})
        
        receive do
          {:final_stats, stats} ->
            Process.demonitor(ref, [:flush])
            {:ok, stats}
            
          {:DOWN, ^ref, :process, ^pid, _reason} ->
            {:error, :monitor_crashed}
        after
          5000 ->
            Process.demonitor(ref, [:flush])
            {:error, :timeout}
        end
    end
  end
  
  # Loop principal do monitor
  defp monitor_loop(state) do
    receive do
      # Atualização de estatísticas
      {:update_stats, update} ->
        # Aplica a atualização ao estado
        state = apply_update(state, update)
        monitor_loop(state)
        
      # Atualização periódica do display
      :update_display ->
        # Atualiza as estatísticas do sistema
        state = update_system_stats(state)
        
        # Exibe as estatísticas atuais
        print_stats(state)
        
        # Agenda a próxima atualização
        Process.send_after(self(), :update_display, 1000)
        
        # Atualiza o timestamp da última atualização
        state = %{state | last_update: :os.timestamp()}
        monitor_loop(state)
        
      # Comando para parar o monitor
      {:stop, caller} ->
        # Exibe as estatísticas finais
        print_final_stats(state)
        
        # Envia as estatísticas finais para o chamador
        send(caller, {:final_stats, state.stats})
        
        :ok
        
      # Ignora outras mensagens
      _ ->
        monitor_loop(state)
    end
  end
  
  # Aplica uma atualização às estatísticas
  defp apply_update(state, update) do
    case update do
      # Atualização de conexão
      {:connection, :attempted} ->
        connections = state.stats.connections
        connections = %{connections | attempted: connections.attempted + 1}
        put_in(state, [:stats, :connections], connections)
        
      {:connection, :successful} ->
        connections = state.stats.connections
        connections = %{connections | 
          successful: connections.successful + 1,
          current: connections.current + 1
        }
        put_in(state, [:stats, :connections], connections)
        
      {:connection, :failed} ->
        connections = state.stats.connections
        connections = %{connections | failed: connections.failed + 1}
        put_in(state, [:stats, :connections], connections)
        
      {:connection, :closed} ->
        connections = state.stats.connections
        connections = %{connections | current: max(0, connections.current - 1)}
        put_in(state, [:stats, :connections], connections)
        
      # Atualização de mensagem
      {:message, :sent} ->
        messages = state.stats.messages
        messages = %{messages | sent: messages.sent + 1}
        put_in(state, [:stats, :messages], messages)
        
      {:message, :received} ->
        messages = state.stats.messages
        messages = %{messages | received: messages.received + 1}
        put_in(state, [:stats, :messages], messages)
        
      {:message, :failed} ->
        messages = state.stats.messages
        messages = %{messages | failed: messages.failed + 1}
        put_in(state, [:stats, :messages], messages)
        
      # Atualização de latência
      {:latency, value} when is_number(value) ->
        latency = state.stats.latency
        latency = %{latency |
          min: if(is_nil(latency.min), do: value, else: min(latency.min, value)),
          max: if(is_nil(latency.max), do: value, else: max(latency.max, value)),
          total: latency.total + value,
          samples: latency.samples + 1
        }
        put_in(state, [:stats, :latency], latency)
        
      # Ignora atualizações desconhecidas
      _ ->
        state
    end
  end
  
  # Atualiza as estatísticas do sistema
  defp update_system_stats(state) do
    # Coleta estatísticas do sistema
    system = %{
      cpu_usage: get_cpu_usage(),
      memory_usage: get_memory_usage(),
      process_count: :erlang.system_info(:process_count)
    }
    
    # Atualiza o estado
    put_in(state, [:stats, :system], system)
  end
  
  # Obtém o uso de CPU
  defp get_cpu_usage do
    # Implementação simplificada - em um sistema real, usaríamos
    # uma biblioteca como :cpu_sup ou :os_mon
    try do
      {output, 0} = System.cmd("wmic", ["cpu", "get", "loadpercentage"])
      output
      |> String.split("\n", trim: true)
      |> Enum.at(1)
      |> String.trim()
      |> String.to_integer()
    rescue
      _ -> 0
    catch
      _, _ -> 0
    end
  end
  
  # Obtém o uso de memória
  defp get_memory_usage do
    # Obtém estatísticas de memória do Erlang
    mem = :erlang.memory()
    total = mem[:total]
    
    # Converte para MB
    total / 1024 / 1024
  end
  
  # Imprime o cabeçalho do monitor
  defp print_header(state) do
    IO.puts("\n")
    IO.puts(String.duplicate("=", 80))
    IO.puts("MONITOR DE TESTE DE CARGA - #{state.test_name}")
    IO.puts("Configuração: #{state.config.num_connections} conexões, #{state.config.message_rate} msg/s por conexão")
    IO.puts(String.duplicate("=", 80))
    IO.puts("\n")
  end
  
  # Imprime as estatísticas atuais
  defp print_stats(state) do
    # Limpa a tela
    IO.write("\e[H\e[2J")
    
    # Calcula o tempo decorrido
    elapsed = timer_diff_ms(:os.timestamp(), state.start_time) / 1000
    
    # Calcula a latência média
    avg_latency = 
      if state.stats.latency.samples > 0 do
        state.stats.latency.total / state.stats.latency.samples
      else
        0
      end
    
    # Calcula taxas
    conn_rate = state.stats.connections.attempted / max(1, elapsed)
    msg_rate = state.stats.messages.sent / max(1, elapsed)
    
    # Imprime o cabeçalho
    IO.puts("\n")
    IO.puts(String.duplicate("=", 80))
    IO.puts("MONITOR DE TESTE DE CARGA - #{state.test_name} - #{trunc(elapsed)}s")
    IO.puts(String.duplicate("=", 80))
    
    # Imprime estatísticas de conexão
    IO.puts("\nCONEXÕES:")
    IO.puts("  Tentadas: #{state.stats.connections.attempted} (#{trunc(conn_rate)}/s)")
    IO.puts("  Bem-sucedidas: #{state.stats.connections.successful} (#{percentage(state.stats.connections.successful, state.stats.connections.attempted)}%)")
    IO.puts("  Falhas: #{state.stats.connections.failed} (#{percentage(state.stats.connections.failed, state.stats.connections.attempted)}%)")
    IO.puts("  Ativas: #{state.stats.connections.current}")
    
    # Imprime estatísticas de mensagem
    IO.puts("\nMENSAGENS:")
    IO.puts("  Enviadas: #{state.stats.messages.sent} (#{trunc(msg_rate)}/s)")
    IO.puts("  Recebidas: #{state.stats.messages.received} (#{percentage(state.stats.messages.received, state.stats.messages.sent)}%)")
    IO.puts("  Falhas: #{state.stats.messages.failed} (#{percentage(state.stats.messages.failed, state.stats.messages.sent)}%)")
    
    # Imprime estatísticas de latência
    IO.puts("\nLATÊNCIA (ms):")
    IO.puts("  Mínima: #{format_latency(state.stats.latency.min)}")
    IO.puts("  Média: #{format_latency(avg_latency)}")
    IO.puts("  Máxima: #{format_latency(state.stats.latency.max)}")
    
    # Imprime estatísticas do sistema
    IO.puts("\nSISTEMA:")
    IO.puts("  CPU: #{state.stats.system.cpu_usage}%")
    IO.puts("  Memória: #{Float.round(state.stats.system.memory_usage, 2)} MB")
    IO.puts("  Processos Erlang: #{state.stats.system.process_count}")
    
    IO.puts("\n#{String.duplicate("-", 80)}")
    IO.puts("Pressione Ctrl+C para interromper o teste")
    IO.puts("\n")
  end
  
  # Imprime as estatísticas finais
  defp print_final_stats(state) do
    # Limpa a tela
    IO.write("\e[H\e[2J")
    
    # Calcula o tempo total
    total_time = timer_diff_ms(:os.timestamp(), state.start_time) / 1000
    
    # Calcula a latência média
    avg_latency = 
      if state.stats.latency.samples > 0 do
        state.stats.latency.total / state.stats.latency.samples
      else
        0
      end
    
    # Imprime o cabeçalho
    IO.puts("\n")
    IO.puts(String.duplicate("=", 80))
    IO.puts("RESULTADOS FINAIS - #{state.test_name} - #{trunc(total_time)}s")
    IO.puts(String.duplicate("=", 80))
    
    # Imprime estatísticas de conexão
    IO.puts("\nCONEXÕES:")
    IO.puts("  Total: #{state.stats.connections.attempted}")
    IO.puts("  Bem-sucedidas: #{state.stats.connections.successful} (#{percentage(state.stats.connections.successful, state.stats.connections.attempted)}%)")
    IO.puts("  Falhas: #{state.stats.connections.failed} (#{percentage(state.stats.connections.failed, state.stats.connections.attempted)}%)")
    
    # Imprime estatísticas de mensagem
    IO.puts("\nMENSAGENS:")
    IO.puts("  Enviadas: #{state.stats.messages.sent}")
    IO.puts("  Recebidas: #{state.stats.messages.received} (#{percentage(state.stats.messages.received, state.stats.messages.sent)}%)")
    IO.puts("  Falhas: #{state.stats.messages.failed} (#{percentage(state.stats.messages.failed, state.stats.messages.sent)}%)")
    IO.puts("  Taxa média: #{Float.round(state.stats.messages.sent / total_time, 2)} msg/s")
    
    # Imprime estatísticas de latência
    IO.puts("\nLATÊNCIA (ms):")
    IO.puts("  Mínima: #{format_latency(state.stats.latency.min)}")
    IO.puts("  Média: #{format_latency(avg_latency)}")
    IO.puts("  Máxima: #{format_latency(state.stats.latency.max)}")
    
    # Imprime estatísticas do sistema
    IO.puts("\nSISTEMA:")
    IO.puts("  Pico de CPU: #{state.stats.system.cpu_usage}%")
    IO.puts("  Pico de Memória: #{Float.round(state.stats.system.memory_usage, 2)} MB")
    IO.puts("  Pico de Processos Erlang: #{state.stats.system.process_count}")
    
    IO.puts("\n#{String.duplicate("=", 80)}")
    IO.puts("\n")
  end
  
  # Formata um valor de latência
  defp format_latency(nil), do: "N/A"
  defp format_latency(value), do: Float.round(value, 2)
  
  # Calcula uma porcentagem
  defp percentage(_numerator, 0), do: 0
  defp percentage(numerator, denominator), do: Float.round(numerator / denominator * 100, 2)
  
  # Calcula a diferença entre dois timestamps em milissegundos
  defp timer_diff_ms({sec2, msec2, usec2}, {sec1, msec1, usec1}) do
    ((sec2 - sec1) * 1_000_000 + (msec2 - msec1)) / 1_000 + (usec2 - usec1) / 1_000_000
  end
end
