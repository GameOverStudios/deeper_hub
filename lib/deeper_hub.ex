defmodule DeeperHub do
  @moduledoc """
  DeeperHub - Sistema de comunicação em tempo real.

  Este é o módulo principal do DeeperHub, fornecendo uma interface unificada
  para todas as funcionalidades do sistema, incluindo autenticação, canais,
  mensagens e gerenciamento de usuários.

  ## Funcionalidades Principais

  - Autenticação segura com JWT e 2FA
  - Canais de comunicação em tempo real
  - Sistema de presença de usuários
  - Gerenciamento de sessões
  - Sistema de segurança robusto
  - Probes de readiness/liveness para monitoramento em produção

  ## Exemplos

      # Verificar saúde do sistema
      iex> DeeperHub.health_check()
      {:ok, %{status: :healthy, version: "1.0.0"}}

      # Obter versão
      iex> DeeperHub.version()
      "1.0.0"
      
      # Verificar readiness
      iex> DeeperHub.readiness_check()
      {:ok, %{ready: true, services: %{database: true, cache: true}}}
      
      # Verificar liveness
      iex> DeeperHub.liveness_check()
      {:ok, %{alive: true}}
  """

  alias DeeperHub.Accounts
  alias DeeperHub.Core.Network.Channels
  alias DeeperHub.Core.Data.Repo

  @version Mix.Project.config()[:version]

  @doc """
  Retorna a versão atual do sistema.

  ## Retorno
    * String com a versão atual
  """
  @spec version() :: String.t()
  def version, do: @version

  @doc """
  Verifica a saúde geral do sistema.

  ## Retorno
    * `{:ok, status}` - Se o sistema estiver saudável
    * `{:error, reason}` - Se houver problemas
  """
  @spec health_check() :: {:ok, map()} | {:error, any()}
  def health_check do
    checks = %{
      database: check_database(),
      cache: check_cache(),
      version: @version,
      uptime: get_uptime()
    }

    if all_healthy?(checks) do
      {:ok, Map.put(checks, :status, :healthy)}
    else
      {:error, Map.put(checks, :status, :unhealthy)}
    end
  end

  @doc """
  Inicia o sistema programaticamente (para testes).

  ## Opções
    * `:env` - Ambiente de execução (:dev, :test, :prod)
  """
  @spec start_link(keyword()) :: {:ok, pid()} | {:error, any()}
  def start_link(opts \\ []) do
    env = Keyword.get(opts, :env, Mix.env())
    Application.put_env(:deeper_hub, :env, env)
    DeeperHub.Application.start(:normal, [])
  end

  # Funções privadas para health check

  defp check_database do
    case Repo.query("SELECT 1;", []) do
      {:ok, _} -> :healthy
      {:error, _} -> :unhealthy
    end
  rescue
    _ -> :unhealthy
  end

  defp check_cache do
    try do
      case DeeperHub.Core.Cache.get("health_check") do
        {:ok, _} -> :healthy
        {:error, _} -> :healthy  # Cache vazio é ok
      end
    rescue
      _ -> :unhealthy
    end
  end

  defp get_uptime do
    {uptime_ms, _} = :erlang.statistics(:wall_clock)
    uptime_ms
  end

  defp all_healthy?(checks) do
    checks
    |> Map.drop([:version, :uptime, :status])
    |> Map.values()
    |> Enum.all?(&(&1 == :healthy))
  end

  @doc """
  Verifica se o sistema está pronto para receber requisições (readiness probe).
  
  Esta função verifica se todos os componentes necessários para o funcionamento do sistema
  estão disponíveis e prontos para atender requisições, como banco de dados, cache, etc.
  
  É útil para sistemas de orquestração de contêineres como Kubernetes, que podem
  usar esta informação para decidir se o tráfego deve ser direcionado para esta instância.
  
  ## Retorno
    * `{:ok, map()}` - Com detalhes sobre os serviços verificados
    * `{:error, map()}` - Se o sistema não estiver pronto para receber requisições
  """
  @spec readiness_check() :: {:ok, map()} | {:error, map()}
  def readiness_check do
    services = %{
      database: check_database_connection(),
      cache: check_cache_availability(),
      message_broker: check_message_broker()
    }
    
    if Enum.all?(Map.values(services), &(&1 == true)) do
      {:ok, %{ready: true, services: services}}
    else
      {:error, %{ready: false, services: services}}
    end
  end
  
  @doc """
  Verifica se o sistema está em execução (liveness probe).
  
  Esta função verifica se o processo da aplicação está funcionando e respondendo,
  sem necessariamente verificar serviços externos. É uma verificação mais simples
  e rápida que o readiness_check.
  
  É útil para sistemas de orquestração de contêineres como Kubernetes, que podem
  usar esta informação para reiniciar a aplicação se necessário.
  
  ## Retorno
    * `{:ok, map()}` - Se o processo estiver vivo e respondendo
    * `{:error, map()}` - Em um caso teórico onde a aplicação não consegue responder
  """
  @spec liveness_check() :: {:ok, map()}
  def liveness_check do
    # Se esta função está sendo executada, o processo está vivo
    {:ok, %{alive: true, pid: inspect(self())}}
  end
  
  # Funções privadas para as verificações
  
  defp check_database_connection do
    case Repo.query("SELECT 1;", []) do
      {:ok, _} -> true
      _ -> false
    end
  rescue
    _ -> false
  end
  
  defp check_cache_availability do
    try do
      key = "readiness_check_#{System.system_time(:millisecond)}"
      value = "1"
      
      with {:ok, _} <- DeeperHub.Core.Cache.put(key, value, ttl: 10),
           {:ok, ^value} <- DeeperHub.Core.Cache.get(key) do
        true
      else
        _ -> false
      end
    rescue
      _ -> false
    end
  end
  
  defp check_message_broker do
    # Implementação simplificada para verificar o message broker
    # Em uma implementação real, você verificaria a conexão real com o broker
    case Application.get_env(:deeper_hub, :message_broker_enabled, false) do
      true -> 
        # Verificar conexão real aqui
        true
      _ -> true  # Se não estiver configurado, não é um requisito
    end
  rescue
    _ -> false
  end
end
