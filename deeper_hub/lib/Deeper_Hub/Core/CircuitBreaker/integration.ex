defmodule Deeper_Hub.Core.CircuitBreaker.Integration do
  @moduledoc """
  Fornece funções de integração para outros módulos do Deeper_Hub utilizarem o CircuitBreaker.

  Este módulo simplifica a integração do CircuitBreaker com outros módulos do sistema,
  fornecendo funções de alto nível com logging e métricas aprimorados.

  ## Funcionalidades

  * 🔌 Configuração simplificada de circuit breakers
  * 🛡️ Proteção de chamadas com telemetria integrada
  * 📊 Métricas e logs padronizados
  * 🔄 Integração com o sistema de eventos
  """

  alias Deeper_Hub.Core.CircuitBreaker.CircuitBreakerFacade, as: CB
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Metrics.MetricsFacade, as: Metrics
  alias Deeper_Hub.Core.EventBus.EventBusFacade, as: EventBus

  @doc """
  Configura um circuit breaker para um serviço.

  ## Parâmetros

    - `service_name`: Nome do serviço protegido pelo circuit breaker
    - `config`: Configurações específicas para este circuit breaker

  ## Retorno

    - `{:ok, pid}` se o circuit breaker for configurado com sucesso
    - `{:error, reason}` em caso de falha

  ## Exemplo

  ```elixir
  Integration.setup_breaker(:external_api, %{
    failure_threshold: 5,
    reset_timeout_ms: 30_000
  })
  ```
  """
  @spec setup_breaker(atom(), map()) :: {:ok, pid()} | {:error, term()}
  def setup_breaker(service_name, config \\ %{}) do
    # Registra o início da operação
    Logger.info("Configurando circuit breaker", %{
      module: __MODULE__,
      service_name: service_name,
      config: config
    })

    # Registra o circuit breaker
    result = CB.register(service_name, config)

    # Registra métricas e eventos
    case result do
      {:ok, _pid} ->
        # Registra métrica de sucesso
        Metrics.increment("deeper_hub.core.circuit_breaker.setup.success", %{
          service_name: service_name
        })

        # Publica evento de circuit breaker configurado
        EventBus.publish("circuit_breaker.configured", %{
          service_name: service_name,
          config: config,
          timestamp: DateTime.utc_now()
        })

      {:error, reason} ->
        # Registra métrica de falha
        Metrics.increment("deeper_hub.core.circuit_breaker.setup.failed", %{
          service_name: service_name,
          reason: inspect(reason)
        })

        # Registra erro
        Logger.error("Falha ao configurar circuit breaker", %{
          module: __MODULE__,
          service_name: service_name,
          reason: reason
        })
    end

    result
  end

  @doc """
  Executa uma operação protegida pelo circuit breaker com telemetria aprimorada.

  ## Parâmetros

    - `service_name`: Nome do serviço protegido pelo circuit breaker
    - `operation_name`: Nome da operação (para logs e métricas)
    - `operation_fun`: Função que realiza a operação protegida
    - `fallback_fun`: Função de fallback a ser executada se o circuito estiver aberto ou a operação falhar (opcional)
    - `opts`: Opções adicionais

  ## Retorno

    - Resultado da função `operation_fun` ou `fallback_fun`
    - `{:error, :circuit_open}` se o circuito estiver aberto e nenhum fallback for fornecido

  ## Exemplo

  ```elixir
  Integration.protected_call(:external_api, "get_user_data",
    fn ->
      HTTPClient.get("https://api.example.com/users/123")
    end,
    fn error ->
      {:ok, %{id: 123, name: "Cached User", source: :fallback}}
    end
  )
  ```
  """
  @spec protected_call(atom(), String.t(), function(), function() | nil, Keyword.t()) :: any()
  def protected_call(service_name, operation_name, operation_fun, fallback_fun \\ nil, opts \\ []) do
    # Registra o início da operação
    start_time = System.monotonic_time(:millisecond)

    # Prepara o contexto de telemetria
    metadata = %{
      service_name: service_name,
      operation_name: operation_name
    }

    # Executa o span de telemetria
    :telemetry.span(
      [:deeper_hub, :core, :circuit_breaker, :operation],
      metadata,
      fn ->
        # Registra o início da operação
        Logger.debug("Iniciando operação protegida", Map.merge(metadata, %{
          module: __MODULE__,
          opts: opts
        }))

        # Executa a operação protegida
        result = CB.run(
          service_name,
          operation_fun,
          fallback_fun,
          opts
        )

        # Determina o status da operação
        status = case result do
          {:error, :circuit_open} -> :circuit_open
          {:error, _} -> :error
          _ -> :success
        end

        # Registra o fim da operação
        Logger.debug("Operação protegida concluída", Map.merge(metadata, %{
          module: __MODULE__,
          status: status,
          duration_ms: System.monotonic_time(:millisecond) - start_time
        }))

        # Retorna o resultado e as métricas
        {result, Map.merge(metadata, %{
          status: status,
          duration_ms: System.monotonic_time(:millisecond) - start_time
        })}
      end
    )
  end

  @doc """
  Verifica o estado de um circuit breaker e retorna informações detalhadas.

  ## Parâmetros

    - `service_name`: Nome do serviço protegido pelo circuit breaker

  ## Retorno

    - `{:ok, %{state: atom(), description: String.t()}}` se o circuit breaker existir
    - `{:error, :not_found}` se o circuit breaker não existir

  ## Exemplo

  ```elixir
  {:ok, info} = Integration.check_breaker_status(:external_api)
  # info = %{state: :open, description: "Circuito aberto - serviço indisponível"}
  ```
  """
  @spec check_breaker_status(atom()) :: {:ok, map()} | {:error, :not_found}
  def check_breaker_status(service_name) do
    case CB.state(service_name) do
      {:ok, state} ->
        description = case state do
          :closed -> "Circuito fechado - serviço operando normalmente"
          :open -> "Circuito aberto - serviço indisponível"
          :half_open -> "Circuito em teste - verificando disponibilidade do serviço"
        end

        # Registra a verificação
        Logger.debug("Verificação de status do circuit breaker", %{
          module: __MODULE__,
          service_name: service_name,
          state: state
        })

        {:ok, %{state: state, description: description}}

      error ->
        error
    end
  end

  @doc """
  Reseta um circuit breaker para o estado fechado e registra a operação.

  ## Parâmetros

    - `service_name`: Nome do serviço protegido pelo circuit breaker
    - `reason`: Motivo do reset (para logs)

  ## Retorno

    - `:ok` se o circuit breaker for resetado com sucesso
    - `{:error, :not_found}` se o circuit breaker não existir

  ## Exemplo

  ```elixir
  :ok = Integration.reset_breaker(:external_api, "Serviço restaurado manualmente")
  ```
  """
  @spec reset_breaker(atom(), String.t()) :: :ok | {:error, :not_found}
  def reset_breaker(service_name, reason) do
    # Registra a operação
    Logger.info("Resetando circuit breaker", %{
      module: __MODULE__,
      service_name: service_name,
      reason: reason
    })

    # Reseta o circuit breaker
    result = CB.reset(service_name)

    # Registra métricas e eventos
    case result do
      :ok ->
        # Registra métrica de reset
        Metrics.increment("deeper_hub.core.circuit_breaker.reset", %{
          service_name: service_name
        })

        # Publica evento de circuit breaker resetado
        EventBus.publish("circuit_breaker.reset", %{
          service_name: service_name,
          reason: reason,
          timestamp: DateTime.utc_now()
        })

      {:error, reason_error} ->
        # Registra erro
        Logger.error("Falha ao resetar circuit breaker", %{
          module: __MODULE__,
          service_name: service_name,
          reason: reason_error
        })
    end

    result
  end
end
