# Script para executar testes de carga no sistema WebSocket do DeeperHub
#
# Este script executa testes de carga com diferentes configurações e
# gera um relatório detalhado com os resultados.
#
# Para executar:
# mix run test/load_test/run_load_test.exs

# Certifica-se de que o código de teste foi compilado
Code.require_file("test/load_test/websocket_load_test.ex")

defmodule DeeperHub.LoadTest.Runner do
  @moduledoc """
  Executor de testes de carga para o sistema WebSocket do DeeperHub.
  """
  
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  alias DeeperHub.LoadTest.WebSocketLoadTest
  
  @doc """
  Executa uma série de testes de carga com diferentes configurações.
  """
  def run do
    Logger.info("Iniciando execução de testes de carga", module: __MODULE__)
    
    # Configurações de teste
    test_configs = [
      %{
        name: "Teste de Baixa Carga",
        config: %{
          num_connections: 100,
          ramp_up_time: 10,
          test_duration: 60,
          message_rate: 1
        }
      },
      %{
        name: "Teste de Média Carga",
        config: %{
          num_connections: 500,
          ramp_up_time: 30,
          test_duration: 120,
          message_rate: 2
        }
      },
      %{
        name: "Teste de Alta Carga",
        config: %{
          num_connections: 1000,
          ramp_up_time: 60,
          test_duration: 180,
          message_rate: 5
        }
      }
    ]
    
    # Executa cada teste e coleta os resultados
    results = 
      test_configs
      |> Enum.map(fn %{name: name, config: config} ->
        Logger.info("Executando teste: #{name}", module: __MODULE__)
        
        case WebSocketLoadTest.run(config) do
          {:ok, result} ->
            Logger.info("Teste concluído: #{name}", module: __MODULE__)
            {name, result}
            
          {:error, reason} ->
            Logger.error("Falha no teste #{name}: #{inspect(reason)}", module: __MODULE__)
            {name, {:error, reason}}
        end
      end)
    
    # Gera o relatório final
    generate_report(results)
  end
  
  @doc """
  Gera um relatório detalhado com os resultados dos testes.
  """
  def generate_report(results) do
    Logger.info("Gerando relatório de testes de carga", module: __MODULE__)
    
    # Cria o diretório para o relatório
    File.mkdir_p!("test/load_test/reports")
    
    # Nome do arquivo de relatório com timestamp
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601() |> String.replace(~r/[^\d]/, "")
    report_file = "test/load_test/reports/load_test_report_#{timestamp}.md"
    
    # Conteúdo do relatório
    report_content = """
    # Relatório de Testes de Carga - DeeperHub WebSocket
    
    Data: #{DateTime.utc_now() |> DateTime.to_string()}
    
    ## Resumo
    
    | Teste | Conexões | Taxa de Sucesso | Mensagens/s | Latência Média (ms) |
    |-------|----------|-----------------|-------------|---------------------|
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
          "| #{name} | FALHA | FALHA | FALHA | FALHA |\n"
          
        result ->
          conn = result.connections
          msg = result.messages
          latency = result.latency
          
          "| #{name} | #{conn.total} | #{Float.round(conn.success_rate, 2)}% | #{Float.round(msg.rate, 2)} | #{Float.round(latency.avg, 2)} |\n"
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
          
        result ->
          conn = result.connections
          msg = result.messages
          latency = result.latency
          config = result.config
          
          """
          ### #{name}
          
          **Configuração:**
          - Conexões: #{config.num_connections}
          - Tempo de ramp-up: #{config.ramp_up_time}s
          - Duração do teste: #{config.test_duration}s
          - Taxa de mensagens: #{config.message_rate}/s por conexão
          
          **Resultados:**
          - **Conexões:**
            - Total: #{conn.total}
            - Bem-sucedidas: #{conn.successful} (#{Float.round(conn.success_rate, 2)}%)
            - Falhas: #{conn.failed}
            - Taxa: #{Float.round(conn.rate, 2)} conexões/s
          
          - **Mensagens:**
            - Enviadas: #{msg.sent}
            - Recebidas: #{msg.received} (#{Float.round(msg.success_rate, 2)}%)
            - Falhas: #{msg.failed}
            - Taxa: #{Float.round(msg.rate, 2)} mensagens/s
          
          - **Latência (ms):**
            - Mínima: #{Float.round(latency.min, 2)}
            - Média: #{Float.round(latency.avg, 2)}
            - Máxima: #{Float.round(latency.max, 2)}
          
          - **Erros:**
            #{format_errors(result.errors)}
          """
      end
    end)
    |> Enum.join("\n\n")
  end
  
  # Formata a lista de erros para o relatório
  defp format_errors(errors) when map_size(errors) == 0 do
    "Nenhum erro registrado."
  end
  
  defp format_errors(errors) do
    errors
    |> Enum.map(fn {reason, count} ->
      "    - #{inspect(reason)}: #{count} ocorrências"
    end)
    |> Enum.join("\n")
  end
  
  # Gera conclusões e recomendações com base nos resultados
  defp generate_conclusions(results) do
    # Verifica se algum teste falhou
    any_failure = Enum.any?(results, fn {_, result} -> match?({:error, _}, result) end)
    
    # Obtém o teste de maior carga bem-sucedido
    successful_tests = 
      results
      |> Enum.filter(fn {_, result} -> not match?({:error, _}, result) end)
      |> Enum.sort_by(fn {_, result} -> result.connections.total end, :desc)
    
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
        {name, result} = max_successful
        
        """
        Todos os testes foram concluídos com sucesso, com o teste de maior carga (#{name}) 
        suportando #{result.connections.total} conexões simultâneas e processando 
        #{Float.round(result.messages.rate, 2)} mensagens por segundo.
        
        **Capacidade Estimada:**
        - Conexões simultâneas: #{result.connections.total}
        - Mensagens por segundo: #{Float.round(result.messages.rate, 2)}
        - Latência média: #{Float.round(result.latency.avg, 2)}ms
        
        **Recomendações:**
        1. O sistema demonstra boa capacidade para a carga testada
        2. Para cargas maiores, considere distribuir o sistema em múltiplos nós
        3. Monitore a latência em produção, que tende a aumentar com a carga real
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
end

# Executa os testes
DeeperHub.LoadTest.Runner.run()
