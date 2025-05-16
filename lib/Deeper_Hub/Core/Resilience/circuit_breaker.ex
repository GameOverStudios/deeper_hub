defmodule Deeper_Hub.Core.Resilience.CircuitBreaker do
  @moduledoc """
  Implementação de Circuit Breaker para proteger o sistema contra falhas em serviços externos.
  
  Este módulo fornece uma interface para o padrão Circuit Breaker usando a biblioteca ExBreak,
  permitindo que operações potencialmente falhas sejam isoladas e monitoradas.
  
  ## Características
  
  - Proteção contra falhas em cascata
  - Monitoramento de falhas com integração com telemetria
  - Configuração flexível de limiares e timeouts
  - Integração com o sistema de eventos
  """

  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Telemetry.TelemetryEvents
  alias Deeper_Hub.Core.EventBus.EventDefinitions

  @doc """
  Executa uma função com proteção de circuit breaker.
  
  ## Parâmetros
  
  - `name`: Nome identificador do circuit breaker
  - `function`: Função a ser executada (anônima ou capturada)
  - `args`: Lista de argumentos para a função
  - `opts`: Opções para o circuit breaker
  
  ## Opções
  
  - `:threshold`: Número de falhas antes de abrir o circuit breaker (padrão: 5)
  - `:timeout_sec`: Tempo em segundos que o circuit breaker permanece aberto (padrão: 60)
  - `:match_error`: Função para determinar quais erros incrementam o contador (padrão: todos)
  - `:log_level`: Nível de log para mensagens do circuit breaker (padrão: :warn)
  
  ## Retorno
  
  - Retorna o resultado da função chamada
  - Em caso de circuit breaker aberto, retorna `{:error, :circuit_breaker_tripped}`
  
  ## Exemplo
  
  ```elixir
  CircuitBreaker.call(:api_service, &ApiClient.get_data/2, ["users", token], 
                      threshold: 3, timeout_sec: 30)
  ```
  """
  @spec call(atom(), function(), list(), keyword()) :: any()
  def call(name, function, args, opts \\ []) do
    threshold = Keyword.get(opts, :threshold, 5)
    timeout_sec = Keyword.get(opts, :timeout_sec, 60)
    log_level = Keyword.get(opts, :log_level, :warn)
    
    # Função para determinar quais erros incrementam o contador
    match_error = Keyword.get(opts, :match_error, fn
      {:error, _} -> true
      _ -> false
    end)
    
    # Função chamada quando o circuit breaker abre
    on_trip = fn breaker ->
      Logger.log(log_level, "Circuit breaker aberto", %{
        module: __MODULE__,
        name: name,
        threshold: threshold,
        timeout_sec: timeout_sec,
        break_count: breaker.break_count
      })
      
      # Emite evento de telemetria
      TelemetryEvents.execute_circuit_breaker_trip(
        %{count: 1},
        %{name: name, threshold: threshold, timeout_sec: timeout_sec}
      )
      
      # Emite evento para o EventBus
      EventDefinitions.emit(
        EventDefinitions.circuit_breaker_trip(),
        %{name: name, threshold: threshold, timeout_sec: timeout_sec},
        source: "#{__MODULE__}"
      )
    end
    
    # Configura o nome do breaker para incluir o namespace do aplicativo
    breaker_name = :"Deeper_Hub.CircuitBreaker.#{name}"
    
    # Executa a função com proteção de circuit breaker
    ExBreak.call(
      function,
      args,
      name: breaker_name,
      threshold: threshold,
      timeout_sec: timeout_sec,
      match_return: match_error,
      on_trip: on_trip
    )
  end
  
  # Nota: As funções status/1, reset/1 e list/0 foram removidas porque não estão disponíveis
  # na versão atual da biblioteca ExBreak. Apenas a função call/4 está implementada.
end
