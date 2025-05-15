defmodule Deeper_Hub.Core.CircuitBreaker.Runner do
  @moduledoc """
  Responsável por executar operações protegidas pelo CircuitBreaker.
  
  Este módulo fornece a lógica para executar operações com proteção de circuit breaker,
  garantindo que o serviço seja chamado apenas quando o circuito estiver fechado ou
  em estado de teste (meio-aberto).
  """
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.CircuitBreaker.Registry
  alias Deeper_Hub.Core.CircuitBreaker.Instance
  alias Deeper_Hub.Core.Metrics.MetricsFacade, as: Metrics
  
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
  """
  @spec run(atom(), function(), function() | nil, Keyword.t()) :: any()
  def run(service_name, operation_fun, fallback_fun \\ nil, opts \\ []) do
    # Registra o início da operação
    start_time = System.monotonic_time(:millisecond)
    
    Logger.debug("Executando operação protegida", %{
      module: __MODULE__,
      service_name: service_name,
      opts: opts
    })
    
    # Verifica se o circuit breaker existe
    result = case ensure_circuit_breaker_exists(service_name, opts) do
      {:ok, _pid} ->
        # Circuit breaker existe, executa a operação
        try do
          Instance.run(service_name, operation_fun, fallback_fun, opts)
        rescue
          e ->
            Logger.error("Erro ao executar operação protegida", %{
              module: __MODULE__,
              service_name: service_name,
              error: e,
              stacktrace: __STACKTRACE__
            })
            
            # Registra métrica de erro
            Metrics.increment("deeper_hub.core.circuit_breaker.calls.total", %{
              service_name: service_name,
              status: "error"
            })
            
            # Executa fallback ou retorna erro
            if fallback_fun do
              fallback_fun.({:error, e})
            else
              {:error, e}
            end
        end
        
      {:error, reason} = error ->
        Logger.error("Circuit breaker não encontrado", %{
          module: __MODULE__,
          service_name: service_name,
          reason: reason
        })
        
        # Registra métrica de erro
        Metrics.increment("deeper_hub.core.circuit_breaker.calls.total", %{
          service_name: service_name,
          status: "error"
        })
        
        # Executa fallback ou retorna erro
        if fallback_fun do
          fallback_fun.(error)
        else
          error
        end
    end
    
    # Calcula a duração total da operação
    duration_ms = System.monotonic_time(:millisecond) - start_time
    
    # Registra métrica de duração total (incluindo overhead do circuit breaker)
    Metrics.histogram("deeper_hub.core.circuit_breaker.total_duration_ms", duration_ms, %{
      service_name: service_name
    })
    
    result
  end
  
  # Funções privadas
  
  # Garante que o circuit breaker existe, registrando-o se necessário
  defp ensure_circuit_breaker_exists(service_name, opts) do
    case Registry.state(service_name) do
      {:ok, _state} ->
        # Circuit breaker já existe
        {:ok, nil}
        
      {:error, :not_found} ->
        # Circuit breaker não existe
        if Keyword.get(opts, :auto_register, true) do
          # Registra automaticamente com as configurações fornecidas
          config = Keyword.get(opts, :config, %{})
          Registry.register(service_name, config)
        else
          # Não registra automaticamente
          {:error, :not_found}
        end
    end
  end
end
