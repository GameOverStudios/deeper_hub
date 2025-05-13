defmodule DeeperHub.Core.Logger.Example do
  @moduledoc """
  Módulo de exemplo para demonstrar o uso do DeeperHub.Core.Logger.

  Este módulo contém funções de exemplo que usam os diferentes níveis de log
  para mostrar como o Logger com cores funciona.
  """

  alias DeeperHub.Core.Logger, as: Logger

  @doc """
  Executa uma demonstração de todos os níveis de log.
  """
  def run_demo do
    Logger.info("===== Demonstração do Logger com Cores =====")

    # Exemplo de cada nível de log
    Logger.debug("Esta é uma mensagem de DEBUG")
    Logger.info("Esta é uma mensagem de INFO")
    Logger.warn("Esta é uma mensagem de WARN")
    Logger.error("Esta é uma mensagem de ERROR")
    Logger.critical("Esta é uma mensagem de CRITICAL")

    # Exemplo com metadados
    Logger.info("Mensagem com metadados", %{
      user_id: "user123",
      action: "login",
      ip: "192.168.1.1"
    })

    # Exemplo de diferentes tipos de dados
    Logger.debug("Valores de configuração", %{
      config: %{
        timeout: 5000,
        retry: true,
        hosts: ["server1", "server2"]
      }
    })

    Logger.info("===== Fim da Demonstração =====")
  end

  @doc """
  Executa uma operação simulada para demonstrar logs em contexto.
  """
  def simulate_operation do
    Logger.info("Iniciando operação simulada")

    # Simula processamento
    Process.sleep(500)
    Logger.debug("Processando passo 1", %{step: 1, status: "em andamento"})

    # Simula uma condição de aviso
    Process.sleep(300)
    Logger.warn("Recurso está com capacidade baixa", %{
      resource: "memoria",
      current: "75%",
      threshold: "70%"
    })

    # Simula mais processamento
    Process.sleep(700)
    Logger.debug("Processando passo 2", %{step: 2, status: "em andamento"})

    # Simula um erro recuperável
    Process.sleep(400)
    Logger.error("Falha ao conectar ao serviço externo", %{
      service: "api.exemplo.com",
      error: "timeout",
      retry_count: 1
    })

    # Simula recuperação e conclusão
    Process.sleep(600)
    Logger.info("Operação concluída com warnings", %{
      duration_ms: 2500,
      warnings: 1,
      errors: 1
    })
  end
end
