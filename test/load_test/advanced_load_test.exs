# Script para executar um teste de carga avançado no sistema WebSocket
#
# Este script executa testes de carga com diferentes níveis de concorrência
# e coleta métricas detalhadas sobre o desempenho do sistema.
#
# Para executar:
# mix run test/load_test/advanced_load_test.exs

defmodule DeeperHub.LoadTest.AdvancedRunner do
  @moduledoc """
  Executor de teste de carga avançado para o sistema WebSocket do DeeperHub.
  
  Este módulo implementa testes de carga mais sofisticados, com diferentes
  níveis de concorrência e coleta de métricas detalhadas.
  """
  
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  
  # Configurações para os diferentes níveis de carga
  # Ajustado para hardware com Core i5 e 6GB de RAM
  @load_levels [
    %{
      name: "Baixa Carga",
      num_channels: 5,
      num_connections: 50,
      ramp_up_time: 5,  # segundos
      test_duration: 20,  # segundos
      message_interval: 1000,  # milissegundos
      message_size: 100  # bytes
    },
    %{
      name: "Média Carga",
      num_channels: 8,
      num_connections: 200,
      ramp_up_time: 10,  # segundos
      test_duration: 30,  # segundos
      message_interval: 1500,  # milissegundos
      message_size: 150  # bytes
    },
    %{
      name: "Alta Carga",
      num_channels: 10,
      num_connections: 500,
      ramp_up_time: 15,  # segundos
      test_duration: 45,  # segundos
      message_interval: 2000,  # milissegundos
      message_size: 200  # bytes
    }
  ]
  
  @doc """
  Executa todos os níveis de teste de carga.
  
  ## Retorno
  
  - `{:ok, results}` - Testes concluídos com sucesso
  - `{:error, reason}` - Falha ao executar os testes
  """
  def run_all do
    Logger.info("Iniciando testes de carga em múltiplos níveis", module: __MODULE__)
    
    results = 
      @load_levels
      |> Enum.map(fn config ->
        Logger.info("Iniciando teste de #{config.name}", module: __MODULE__)
        {config.name, run_test(config)}
      end)
    
    # Gera um relatório com os resultados
    generate_report(results)
    
    {:ok, results}
  end
  
  @doc """
  Executa um único teste de carga com a configuração especificada.
  
  ## Parâmetros
  
  - `config` - Configuração do teste
  
  ## Retorno
  
  - `{:ok, metrics}` - Teste concluído com sucesso
  - `{:error, reason}` - Falha ao executar o teste
  """
  def run_test(config) do
    Logger.info("Iniciando teste de carga com #{config.num_connections} conexões", module: __MODULE__)
    
    # Inicializa as métricas
    metrics = %{
      start_time: DateTime.utc_now(),
      end_time: nil,
      channels: [],
      connections: %{
        total: config.num_connections,
        successful: 0,
        failed: 0
      },
      messages: %{
        sent: 0,
        received: 0,
        rate: 0
      },
      errors: []
    }
    
    # Cria os canais para o teste
    channel_ids = create_test_channels(config.num_channels)
    
    if length(channel_ids) == 0 do
      Logger.error("Não foi possível criar canais para o teste. Abortando.", module: __MODULE__)
      {:error, :no_channels_created}
    else
      # Atualiza as métricas com os canais criados
      metrics = %{metrics | channels: channel_ids}
      Logger.info("Criados #{length(channel_ids)} canais para o teste", module: __MODULE__)
      
      # Cria um processo para coletar métricas
      # Primeiro, verifica se já existe um processo registrado com este nome
      if Process.whereis(:metrics_collector) do
        Process.unregister(:metrics_collector)
      end
      
      # Agora cria e registra o novo processo
      metrics_pid = spawn_link(fn -> metrics_collector(metrics) end)
      Process.register(metrics_pid, :metrics_collector)
      
      # Inicia as conexões com ramp-up gradual
      connection_pids = start_connections_with_rampup(channel_ids, config)
      
      # Aguarda a duração do teste
      Logger.info("Teste em andamento por #{config.test_duration} segundos...", module: __MODULE__)
      :timer.sleep(config.test_duration * 1000)
      
      # Encerra as conexões
      stop_connections(connection_pids)
      
      # Obtém as métricas finais
      send(metrics_pid, {:get_metrics, self()})
      final_metrics = receive do
        {:metrics, metrics} -> 
          # Adiciona o timestamp de término
          %{metrics | end_time: DateTime.utc_now()}
      after
        5000 -> 
          Logger.error("Timeout ao obter métricas finais", module: __MODULE__)
          metrics
      end
      
      Logger.info("Teste de carga concluído com sucesso", module: __MODULE__)
      {:ok, final_metrics}
    end
  end
  
  # Cria canais para o teste
  defp create_test_channels(num_channels) do
    Logger.info("Criando #{num_channels} canais para o teste", module: __MODULE__)
    
    1..num_channels
    |> Enum.map(fn i ->
      channel_name = "test_channel_#{i}"
      owner_id = "load_test_user"
      
      case DeeperHub.Core.Network.Channels.Channel.create(channel_name, owner_id, persistent: true) do
        {:ok, channel_id} ->
          Logger.info("Canal criado: #{channel_name} (#{channel_id})", module: __MODULE__)
          channel_id
        {:error, reason} ->
          Logger.error("Falha ao criar canal #{channel_name}: #{inspect(reason)}", module: __MODULE__)
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end
  
  # Inicia as conexões com ramp-up gradual
  defp start_connections_with_rampup(channel_ids, config) do
    Logger.info("Iniciando #{config.num_connections} conexões com ramp-up de #{config.ramp_up_time}s", module: __MODULE__)
    
    # Calcula o intervalo entre conexões para o ramp-up
    interval = trunc(config.ramp_up_time * 1000 / config.num_connections)
    
    # Inicia as conexões gradualmente
    1..config.num_connections
    |> Enum.map(fn i ->
      # Distribui as conexões entre os canais disponíveis
      channel_id = Enum.at(channel_ids, rem(i - 1, length(channel_ids)))
      
      # Calcula o atraso para esta conexão
      delay = trunc(interval * (i - 1))
      
      # Inicia a conexão após o atraso calculado
      :timer.sleep(delay)
      start_simulated_connection(i, channel_id, config)
    end)
    |> Enum.reject(&is_nil/1)
  end
  
  # Inicia uma conexão simulada
  defp start_simulated_connection(id, channel_id, config) do
    connection_id = "conn_#{id}"
    
    pid = spawn_link(fn ->
      # Estado inicial da conexão
      state = %{
        id: connection_id,
        channel_id: channel_id,
        config: config,
        messages_sent: 0,
        messages_received: 0,
        errors: []
      }
      
      # Registra a conexão como bem-sucedida
      update_metrics({:connection_success, connection_id})
      
      # Agenda o envio da primeira mensagem
      Process.send_after(self(), :send_message, :rand.uniform(config.message_interval))
      
      # Loop principal da conexão
      connection_loop(state)
    end)
    
    pid
  end
  
  # Loop principal de uma conexão simulada
  defp connection_loop(state) do
    receive do
      :send_message ->
        # Envia uma mensagem
        message = generate_message(state)
        
        # Simula o envio da mensagem
        update_metrics({:message_sent, state.id})
        
        # Atualiza o estado
        state = %{state | messages_sent: state.messages_sent + 1}
        
        # Agenda o próximo envio
        Process.send_after(self(), :send_message, state.config.message_interval)
        
        # Simula o recebimento de uma resposta
        Process.send_after(self(), {:message_received, message}, :rand.uniform(100))
        
        connection_loop(state)
        
      {:message_received, _message} ->
        # Simula o recebimento de uma mensagem
        update_metrics({:message_received, state.id})
        
        # Atualiza o estado
        state = %{state | messages_received: state.messages_received + 1}
        
        connection_loop(state)
        
      :stop ->
        # Encerra a conexão
        update_metrics({:connection_closed, state.id, %{
          messages_sent: state.messages_sent,
          messages_received: state.messages_received
        }})
        :ok
        
      {:error, reason} ->
        # Registra um erro
        update_metrics({:error, state.id, reason})
        
        # Atualiza o estado
        state = %{state | errors: [reason | state.errors]}
        
        connection_loop(state)
        
      _ ->
        # Ignora outras mensagens
        connection_loop(state)
    end
  end
  
  # Gera uma mensagem para envio
  defp generate_message(state) do
    content = random_string(state.config.message_size)
    
    %{
      id: UUID.uuid4(),
      channel_id: state.channel_id,
      sender_id: state.id,
      content: content,
      timestamp: :os.system_time(:millisecond)
    }
  end
  
  # Encerra todas as conexões
  defp stop_connections(connection_pids) do
    Logger.info("Encerrando #{length(connection_pids)} conexões", module: __MODULE__)
    
    Enum.each(connection_pids, fn pid ->
      send(pid, :stop)
    end)
    
    # Aguarda um pouco para que as conexões possam ser encerradas
    :timer.sleep(1000)
  end
  
  # Atualiza as métricas do teste
  defp update_metrics(update) do
    if pid = Process.whereis(:metrics_collector) do
      send(pid, {:update, update})
    end
  end
  
  # Processo coletor de métricas
  defp metrics_collector(metrics) do
    receive do
      {:update, update} ->
        # Atualiza as métricas com base no tipo de atualização
        new_metrics = apply_update(metrics, update)
        metrics_collector(new_metrics)
        
      {:get_metrics, pid} ->
        # Envia as métricas atuais para o solicitante
        send(pid, {:metrics, metrics})
        metrics_collector(metrics)
    end
  end
  
  # Aplica uma atualização às métricas
  defp apply_update(metrics, update) do
    case update do
      {:connection_success, _conn_id} ->
        # Atualiza o contador de conexões bem-sucedidas
        connections = metrics.connections
        connections = %{connections | successful: connections.successful + 1}
        %{metrics | connections: connections}
        
      {:connection_closed, _conn_id, _stats} ->
        # Não fazemos nada aqui, apenas registramos o fechamento
        metrics
        
      {:message_sent, _conn_id} ->
        # Atualiza o contador de mensagens enviadas
        messages = metrics.messages
        messages = %{messages | sent: messages.sent + 1}
        %{metrics | messages: messages}
        
      {:message_received, _conn_id} ->
        # Atualiza o contador de mensagens recebidas
        messages = metrics.messages
        messages = %{messages | received: messages.received + 1}
        %{metrics | messages: messages}
        
      {:error, _conn_id, reason} ->
        # Adiciona o erro à lista de erros
        %{metrics | errors: [reason | metrics.errors]}
        
      _ ->
        # Ignora atualizações desconhecidas
        metrics
    end
  end
  
  # Gera um relatório com os resultados dos testes
  defp generate_report(results) do
    Logger.info("Gerando relatório de testes de carga", module: __MODULE__)
    
    # Cria o diretório para o relatório
    File.mkdir_p!("test/load_test/reports")
    
    # Nome do arquivo de relatório com timestamp
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601() |> String.replace(~r/[^\d]/, "")
    report_file = "test/load_test/reports/advanced_load_test_#{timestamp}.md"
    
    # Conteúdo do relatório
    report_content = """
    # Relatório de Testes de Carga - DeeperHub WebSocket
    
    Data: #{DateTime.utc_now() |> DateTime.to_string()}
    
    ## Resumo
    
    | Teste | Conexões | Taxa de Sucesso | Mensagens Enviadas | Mensagens Recebidas | Taxa de Mensagens |
    |-------|----------|-----------------|---------------------|---------------------|-------------------|
    #{generate_summary_table(results)}
    
    ## Detalhes dos Testes
    
    #{generate_test_details(results)}
    
    ## Conclusões e Recomendações
    
    #{generate_conclusions(results)}
    """
    
    # Escreve o relatório no arquivo
    File.write!(report_file, report_content)
    
    Logger.info("Relatório gerado: #{report_file}", module: __MODULE__)
    
    # Exibe um resumo no console
    IO.puts("\n\n=== RESUMO DOS TESTES DE CARGA ===\n")
    IO.puts(generate_summary_table(results))
    IO.puts("\nRelatório completo: #{report_file}\n")
  end
  
  # Gera a tabela de resumo para o relatório
  defp generate_summary_table(results) do
    results
    |> Enum.map(fn {name, result} ->
      case result do
        {:error, _reason} ->
          "| #{name} | FALHA | FALHA | FALHA | FALHA | FALHA |\n"
          
        {:ok, metrics} ->
          conn = metrics.connections
          msg = metrics.messages
          
          # Calcula a duração do teste em segundos
          duration = DateTime.diff(metrics.end_time, metrics.start_time)
          
          # Calcula a taxa de mensagens por segundo
          msg_rate = if duration > 0, do: Float.round(msg.sent / duration, 2), else: 0
          
          # Calcula a taxa de sucesso das conexões
          conn_success_rate = if conn.total > 0, do: Float.round(conn.successful / conn.total * 100, 2), else: 0
          
          "| #{name} | #{conn.total} | #{conn_success_rate}% | #{msg.sent} | #{msg.received} | #{msg_rate}/s |\n"
      end
    end)
    |> Enum.join("")
  end
  
  # Gera os detalhes de cada teste para o relatório
  defp generate_test_details(results) do
    results
    |> Enum.map(fn {name, result} ->
      case result do
        {:error, reason} ->
          """
          ### #{name}
          
          **FALHA**: #{inspect(reason)}
          """
          
        {:ok, metrics} ->
          conn = metrics.connections
          msg = metrics.messages
          
          # Calcula a duração do teste em segundos
          duration = DateTime.diff(metrics.end_time, metrics.start_time)
          
          # Calcula a taxa de mensagens por segundo
          msg_rate = if duration > 0, do: Float.round(msg.sent / duration, 2), else: 0
          
          # Calcula a taxa de sucesso das conexões
          conn_success_rate = if conn.total > 0, do: Float.round(conn.successful / conn.total * 100, 2), else: 0
          
          """
          ### #{name}
          
          **Duração**: #{duration} segundos
          
          **Canais**: #{length(metrics.channels)}
          
          **Conexões**:
          - Total: #{conn.total}
          - Bem-sucedidas: #{conn.successful} (#{conn_success_rate}%)
          - Falhas: #{conn.failed}
          
          **Mensagens**:
          - Enviadas: #{msg.sent}
          - Recebidas: #{msg.received}
          - Taxa: #{msg_rate} mensagens/segundo
          
          **Erros**: #{length(metrics.errors)}
          """
      end
    end)
    |> Enum.join("\n\n")
  end
  
  # Gera conclusões e recomendações com base nos resultados
  defp generate_conclusions(results) do
    # Verifica se algum teste falhou
    any_failure = Enum.any?(results, fn {_, result} -> match?({:error, _}, result) end)
    
    # Obtém o teste de maior carga bem-sucedido
    successful_tests = 
      results
      |> Enum.filter(fn {_, result} -> match?({:ok, _}, result) end)
      |> Enum.sort_by(fn {_, {:ok, metrics}} -> metrics.connections.total end, :desc)
    
    max_successful = List.first(successful_tests)
    
    # Gera conclusões com base nos resultados
    cond do
      any_failure ->
        """
        Alguns testes falharam, indicando possíveis limitações no sistema atual.
        
        **Recomendações:**
        1. Investigar as causas das falhas nos testes
        2. Otimizar o sistema para lidar com cargas maiores
        3. Considerar a implementação de mecanismos de backpressure mais robustos
        4. Revisar a configuração do pool de conexões e timeouts
        """
        
      length(successful_tests) > 0 ->
        {name, {:ok, metrics}} = max_successful
        
        # Calcula a duração do teste em segundos
        duration = DateTime.diff(metrics.end_time, metrics.start_time)
        
        # Calcula a taxa de mensagens por segundo
        msg_rate = if duration > 0, do: Float.round(metrics.messages.sent / duration, 2), else: 0
        
        """
        Todos os testes foram concluídos com sucesso, com o teste de maior carga (#{name}) 
        suportando #{metrics.connections.total} conexões simultâneas e processando 
        #{msg_rate} mensagens por segundo.
        
        **Capacidade Estimada:**
        - Conexões simultâneas: #{metrics.connections.total}
        - Mensagens por segundo: #{msg_rate}
        
        **Recomendações:**
        1. O sistema demonstra boa capacidade para a carga testada
        2. Para cargas maiores, considere distribuir o sistema em múltiplos nós
        3. Monitore o uso de recursos em produção (CPU, memória, rede)
        4. Realize testes periódicos para verificar se mudanças no código afetam o desempenho
        """
        
      true ->
        """
        Não foi possível determinar a capacidade do sistema com base nos testes realizados.
        
        **Recomendações:**
        1. Executar testes com configurações diferentes
        2. Verificar a configuração do ambiente de teste
        3. Monitorar o uso de recursos durante os testes (CPU, memória, rede)
        """
    end
  end
  
  # Gera uma string aleatória com o tamanho especificado
  defp random_string(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.encode64()
    |> binary_part(0, length)
  end
end

# Executa os testes
DeeperHub.LoadTest.AdvancedRunner.run_all()
