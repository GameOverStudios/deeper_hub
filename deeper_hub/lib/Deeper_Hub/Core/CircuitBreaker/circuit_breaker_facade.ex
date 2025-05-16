defmodule Deeper_Hub.Core.CircuitBreaker.CircuitBreakerFacade do
  @moduledoc """
  Fachada para o sistema de Circuit Breaker.

  Este módulo fornece uma interface simplificada para os outros módulos do Deeper_Hub
  utilizarem o sistema de Circuit Breaker, abstraindo a complexidade interna.

  ## Funcionalidades

  * 🔄 Proteção de chamadas a serviços externos ou internos
  * 🚦 Gerenciamento de estados do circuito (fechado, aberto, meio-aberto)
  * ⚙️ Configuração flexível de limiares e timeouts
  * 🔄 Suporte a funções de fallback
  * 📊 Integração com métricas e telemetria

  ## Exemplos

  ```elixir
  alias Deeper_Hub.Core.CircuitBreaker.CircuitBreakerFacade, as: CB

  # Registrar um circuit breaker para um serviço
  CB.register(:my_api_service, %{
    failure_threshold: 5,
    reset_timeout_ms: 30_000,
    success_threshold: 2,
    call_timeout_ms: 5_000
  })

  # Executar uma operação protegida pelo circuit breaker
  result = CB.run(:my_api_service,
    fn ->
      # Operação principal
      HTTPClient.get("https://api.example.com/data")
    end,
    fn error ->
      # Função de fallback
      {:ok, %{data: "fallback_data", source: :fallback}}
    end
  )
  ```
  """

  alias Deeper_Hub.Core.CircuitBreaker.Registry
  alias Deeper_Hub.Core.CircuitBreaker.Runner

  @doc """
  Executa uma operação protegida pelo circuit breaker.

  ## Parâmetros

    - `service_name`: Nome do serviço protegido pelo circuit breaker
    - `operation_fun`: Função que realiza a operação protegida
    - `fallback_fun`: Função de fallback a ser executada se o circuito estiver aberto ou a operação falhar (opcional)
    - `opts`: Opções adicionais

  ## Opções

    - `:call_timeout_ms`: Timeout para a chamada ao serviço protegido (ms)
    - `:auto_register`: Se `true`, registra automaticamente o circuit breaker se não existir
    - `:config`: Configurações para o circuit breaker (usado apenas se `auto_register` for `true`)

  ## Retorno

    - Resultado da função `operation_fun` ou `fallback_fun`
    - `{:error, :circuit_open}` se o circuito estiver aberto e nenhum fallback for fornecido
    - `{:error, :not_found}` se o circuit breaker não existir e `auto_register` for `false`

  ## Exemplo

  ```elixir
  result = CircuitBreakerFacade.run(:my_api_service,
    fn ->
      HTTPClient.get("https://api.example.com/data")
    end,
    fn error ->
      {:ok, %{data: "fallback_data", source: :fallback}}
    end
  )
  ```
  """
  @spec run(atom(), function(), function() | nil, Keyword.t()) :: any()
  defdelegate run(service_name, operation_fun, fallback_fun \\ nil, opts \\ []), to: Runner

  @doc """
  Registra um novo circuit breaker.

  ## Parâmetros

    - `service_name`: Nome do serviço protegido pelo circuit breaker
    - `config`: Configurações específicas para este circuit breaker

  ## Configurações

    - `failure_threshold`: Número de falhas para abrir o circuito (padrão: 5)
    - `success_threshold`: Número de sucessos em estado meio-aberto para fechar o circuito (padrão: 2)
    - `reset_timeout_ms`: Tempo que o circuito permanece aberto antes de tentar o estado meio-aberto (padrão: 60_000)
    - `call_timeout_ms`: Timeout para a chamada ao serviço protegido (padrão: 5_000)

  ## Retorno

    - `{:ok, pid}` se o circuit breaker for registrado com sucesso
    - `{:error, reason}` em caso de falha

  ## Exemplo

  ```elixir
  CircuitBreakerFacade.register(:my_api_service, %{
    failure_threshold: 5,
    reset_timeout_ms: 30_000
  })
  ```
  """
  @spec register(atom(), map()) :: {:ok, pid()} | {:error, term()}
  defdelegate register(service_name, config \\ %{}), to: Registry

  @doc """
  Retorna o estado atual de um circuit breaker.

  ## Parâmetros

    - `service_name`: Nome do serviço protegido pelo circuit breaker

  ## Retorno

    - `{:ok, state}` onde `state` é `:closed`, `:open` ou `:half_open`
    - `{:error, :not_found}` se o circuit breaker não existir

  ## Exemplo

  ```elixir
  {:ok, state} = CircuitBreakerFacade.state(:my_api_service)
  ```
  """
  @spec state(atom()) :: {:ok, atom()} | {:error, :not_found}
  defdelegate state(service_name), to: Registry

  @doc """
  Reseta um circuit breaker para o estado fechado.

  ## Parâmetros

    - `service_name`: Nome do serviço protegido pelo circuit breaker

  ## Retorno

    - `:ok` se o circuit breaker for resetado com sucesso
    - `{:error, :not_found}` se o circuit breaker não existir

  ## Exemplo

  ```elixir
  :ok = CircuitBreakerFacade.reset(:my_api_service)
  ```
  """
  @spec reset(atom()) :: :ok | {:error, :not_found}
  defdelegate reset(service_name), to: Registry

  @doc """
  Atualiza a configuração de um circuit breaker.

  ## Parâmetros

    - `service_name`: Nome do serviço protegido pelo circuit breaker
    - `config`: Novas configurações

  ## Retorno

    - `:ok` se a configuração for atualizada com sucesso
    - `{:error, :not_found}` se o circuit breaker não existir

  ## Exemplo

  ```elixir
  :ok = CircuitBreakerFacade.update_config(:my_api_service, %{
    failure_threshold: 10
  })
  ```
  """
  @spec update_config(atom(), map()) :: :ok | {:error, :not_found}
  defdelegate update_config(service_name, config), to: Registry

  @doc """
  Lista todos os circuit breakers registrados.

  ## Retorno

    - `{:ok, list}` com a lista de nomes de serviços e seus estados

  ## Exemplo

  ```elixir
  {:ok, breakers} = CircuitBreakerFacade.list_all()
  # breakers = [{:my_api_service, :closed}, {:other_service, :open}]
  ```
  """
  @spec list_all() :: {:ok, list({atom(), atom()})}
  defdelegate list_all(), to: Registry
end
