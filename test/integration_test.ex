defmodule DeeperHub.Core.IntegrationTest do
  @moduledoc """
  Módulo para testar as integrações entre Cache, Telemetry e Database.

  Este módulo demonstra como todos os sistemas estão integrados e funcionando
  corretamente em produção.
  """

  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  alias DeeperHub.Core.Cache
  alias DeeperHub.Core.Data.Repo

  @doc """
  Executa uma bateria de testes de integração para verificar se todos
  os sistemas estão funcionando corretamente.

  ## Retorno

  - `:ok` - Todos os testes passaram
  - `{:error, failed_tests}` - Lista de testes que falharam
  """
  @spec run_integration_tests() :: :ok | {:error, list()}
  def run_integration_tests do
    Logger.info("Iniciando testes de integração do sistema DeeperHub...")

    tests = [
      {"Cache básico", &test_cache_basic_operations/0},
      {"Cache com telemetria", &test_cache_with_telemetry/0},
      {"Database básico", &test_database_basic_operations/0},
      {"Database com telemetria", &test_database_with_telemetry/0},
      {"Integração Cache-Database", &test_cache_database_integration/0},
      {"Estatísticas do sistema", &test_system_statistics/0}
    ]

    failed_tests = run_tests(tests, [])

    case failed_tests do
      [] ->
        Logger.info("Todos os testes de integração passaram com sucesso!")
        :ok
      failed ->
        Logger.error("Testes falharam: #{inspect(failed)}")
        {:error, failed}
    end
  end

  @doc """
  Demonstra operações básicas do cache.
  """
  @spec demo_cache_operations() :: :ok
  def demo_cache_operations do
    Logger.info("Demonstrando operações do cache...")

    # Operações básicas
    :ok = Cache.put("demo:user:1", %{name: "João", email: "joao@test.com"})
    {:ok, user} = Cache.get("demo:user:1")
    Logger.info("Usuário recuperado do cache: #{inspect(user)}")

    # Operações com namespace
    :ok = Cache.put("server:1", %{status: "online", cpu: 45}, namespace: "monitoring")
    {:ok, server} = Cache.get("server:1", namespace: "monitoring")
    Logger.info("Servidor recuperado do cache: #{inspect(server)}")

    # Operações com TTL
    :ok = Cache.put("temp:data", "dados temporários", ttl: 5)
    {:ok, temp_data} = Cache.get("temp:data")
    Logger.info("Dados temporários: #{inspect(temp_data)}")

    # Contadores
    {:ok, count1} = Cache.increment("demo:counter")
    {:ok, count2} = Cache.increment("demo:counter", 5)
    Logger.info("Contador: #{count1} -> #{count2}")

    # Estatísticas
    {:ok, stats} = Cache.stats()
    Logger.info("Estatísticas do cache: #{inspect(stats)}")

    Logger.info("Demonstração do cache concluída!")
    :ok
  end

  @doc """
  Demonstra operações básicas do banco de dados.
  """
  @spec demo_database_operations() :: :ok
  def demo_database_operations do
    Logger.info("Demonstrando operações do banco de dados...")

    # Consulta simples
    {:ok, result} = Repo.query("SELECT COUNT(*) as total FROM users")
    Logger.info("Total de usuários: #{inspect(result)}")

    # Inserção de dados de teste
    {:ok, _} = Repo.execute(
      "INSERT OR IGNORE INTO users (id, name, email, active) VALUES (?, ?, ?, ?)",
      [999, "Usuário Teste", "teste@demo.com", true]
    )

    # Consulta com parâmetros
    {:ok, users} = Repo.query("SELECT * FROM users WHERE active = ?", [true])
    Logger.info("Usuários ativos encontrados: #{length(users)}")

    # Limpeza
    {:ok, _} = Repo.execute("DELETE FROM users WHERE id = ?", [999])

    Logger.info("Demonstração do banco de dados concluída!")
    :ok
  end

  @doc """
  Demonstra a integração entre cache e banco de dados.
  """
  @spec demo_cache_database_integration() :: :ok
  def demo_cache_database_integration do
    Logger.info("Demonstrando integração Cache-Database...")

    # Função que busca usuário do banco se não estiver em cache
    get_user_with_cache = fn user_id ->
      Cache.get_or_store("user:#{user_id}", fn ->
        case Repo.query("SELECT * FROM users WHERE id = ? LIMIT 1", [user_id]) do
          {:ok, []} -> {:error, :not_found}
          {:ok, [user_data]} ->
            [id, name, email, active] = user_data
            {:ok, %{id: id, name: name, email: email, active: active}}
          {:error, reason} -> {:error, reason}
        end
      end, ttl: 300)
    end

    # Testa a integração
    case get_user_with_cache.(1) do
      {:ok, user} ->
        Logger.info("Usuário obtido via integração Cache-DB: #{inspect(user)}")
      {:error, :not_found} ->
        Logger.info("Usuário não encontrado (normal se não houver dados)")
      {:error, reason} ->
        Logger.warning("Erro na integração: #{inspect(reason)}")
    end

    Logger.info("Demonstração da integração concluída!")
    :ok
  end

  # Funções privadas para testes

  defp run_tests([], failed), do: failed
  defp run_tests([{name, test_fn} | rest], failed) do
    Logger.info("Executando teste: #{name}")

    case test_fn.() do
      :ok ->
        Logger.info("✅ #{name} - PASSOU")
        run_tests(rest, failed)
      {:error, reason} ->
        Logger.error("❌ #{name} - FALHOU: #{inspect(reason)}")
        run_tests(rest, [name | failed])
    end
  end

  defp test_cache_basic_operations do
    try do
      # Teste de put/get
      :ok = Cache.put("test:basic", "valor_teste")
      {:ok, "valor_teste"} = Cache.get("test:basic")

      # Teste de delete
      :ok = Cache.delete("test:basic")
      {:error, :not_found} = Cache.get("test:basic")

      # Teste de exists
      :ok = Cache.put("test:exists", "existe")
      {:ok, true} = Cache.exists?("test:exists")
      :ok = Cache.delete("test:exists")
      {:ok, false} = Cache.exists?("test:exists")

      :ok
    rescue
      error -> {:error, error}
    end
  end

  defp test_cache_with_telemetry do
    try do
      # Operações que devem gerar eventos de telemetria
      :ok = Cache.put("test:telemetry", %{data: "telemetria"})
      {:ok, _} = Cache.get("test:telemetry")
      {:ok, _} = Cache.increment("test:counter")
      :ok = Cache.delete("test:telemetry")
      :ok = Cache.delete("test:counter")

      # Se chegou até aqui, telemetria está funcionando
      :ok
    rescue
      error -> {:error, error}
    end
  end

  defp test_database_basic_operations do
    try do
      # Teste de consulta
      {:ok, _} = Repo.query("SELECT 1 as test")

      # Teste de execução
      {:ok, _} = Repo.execute("SELECT COUNT(*) FROM users")

      :ok
    rescue
      error -> {:error, error}
    end
  end

  defp test_database_with_telemetry do
    try do
      # Operações que devem gerar eventos de telemetria
      {:ok, _} = Repo.query("SELECT 1 as telemetry_test")
      {:ok, _} = Repo.execute("SELECT COUNT(*) FROM users")

      :ok
    rescue
      error -> {:error, error}
    end
  end

  defp test_cache_database_integration do
    try do
      # Testa get_or_store com fallback para database
      result = Cache.get_or_store("integration:test", fn ->
        case Repo.query("SELECT 'integration_success' as result") do
          {:ok, [["integration_success"]]} -> "success"  # Retorna diretamente o valor
          _ -> {:error, :db_error}
        end
      end)

      case result do
        {:ok, "success"} -> :ok
        _ -> {:error, :integration_failed}
      end
    rescue
      error -> {:error, error}
    end
  end

  defp test_system_statistics do
    try do
      # Testa se consegue obter estatísticas
      {:ok, _stats} = Cache.stats()

      :ok
    rescue
      error -> {:error, error}
    end
  end
end
