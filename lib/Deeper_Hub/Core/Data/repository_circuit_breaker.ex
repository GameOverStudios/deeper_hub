defmodule Deeper_Hub.Core.Data.RepositoryCircuitBreaker do
  @moduledoc """
  Módulo de integração com o CircuitBreaker para operações de repositório.
  
  Este módulo centraliza a proteção de operações de banco de dados contra falhas
  em cascata, utilizando o padrão Circuit Breaker.
  
  ## Configuração
  
  O circuit breaker é configurado com os seguintes parâmetros padrão:
  
  - `max_failures`: 5 - Número máximo de falhas antes de abrir o circuito
  - `reset_timeout`: 30_000 - Tempo em milissegundos para resetar o circuito
  - `half_open_threshold`: 2 - Número de sucessos necessários para fechar o circuito
  
  Estes parâmetros podem ser sobrescritos na configuração da aplicação:
  
  ```elixir
  config :deeper_hub, Deeper_Hub.Core.Data.RepositoryCircuitBreaker,
    max_failures: 10,
    reset_timeout: 60_000,
    half_open_threshold: 3
  ```
  
  ## Uso
  
  Este módulo é utilizado internamente pelo `RepositoryCrud` para proteger
  operações de banco de dados. Não é necessário utilizá-lo diretamente.
  """
  
  alias Deeper_Hub.Core.CircuitBreaker.CircuitBreakerFacade, as: CircuitBreaker
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Data.RepositoryMetrics
  
  @doc """
  Inicializa os circuit breakers para os schemas fornecidos.
  
  Esta função deve ser chamada durante a inicialização da aplicação para
  garantir que todos os circuit breakers estejam registrados.
  
  ## Parâmetros
  
  - `schemas` - Lista de schemas Ecto para os quais criar circuit breakers
  """
  def setup(schemas) when is_list(schemas) do
    # Obtém configuração
    config = Application.get_env(:deeper_hub, __MODULE__, [])
    max_failures = Keyword.get(config, :max_failures, 5)
    reset_timeout = Keyword.get(config, :reset_timeout, 30_000)
    half_open_threshold = Keyword.get(config, :half_open_threshold, 2)
    
    # Inicializa circuit breakers para cada schema
    Enum.each(schemas, fn schema ->
      schema_name = get_schema_name(schema)
      
      # Circuit breaker para operações de leitura
      CircuitBreaker.register(
        get_read_circuit_name(schema),
        max_failures: max_failures,
        reset_timeout: reset_timeout,
        half_open_threshold: half_open_threshold,
        callback: &__MODULE__.circuit_state_change_callback/2
      )
      
      # Circuit breaker para operações de escrita
      CircuitBreaker.register(
        get_write_circuit_name(schema),
        max_failures: max_failures,
        reset_timeout: reset_timeout,
        half_open_threshold: half_open_threshold,
        callback: &__MODULE__.circuit_state_change_callback/2
      )
      
      Logger.info("Circuit breakers inicializados para schema", %{
        module: __MODULE__,
        schema: schema_name
      })
    end)
    
    :ok
  end
  
  @doc """
  Executa uma função protegida por um circuit breaker para operações de leitura.
  
  ## Parâmetros
  
  - `schema` - O schema Ecto envolvido na operação
  - `fun` - A função a ser executada
  - `fallback` - Função de fallback a ser executada se o circuito estiver aberto
  
  ## Retorno
  
  - `{:ok, result}` - Se a função for executada com sucesso
  - `{:error, reason}` - Se ocorrer um erro ao executar a função
  """
  def run_read_protected(schema, fun, fallback \\ nil) do
    circuit_name = get_read_circuit_name(schema)
    schema_name = get_schema_name(schema)
    
    # Executa a função protegida
    result = CircuitBreaker.run(circuit_name, fun, fallback)
    
    # Atualiza métricas com o estado atual do circuit breaker
    update_circuit_breaker_metrics(circuit_name, schema)
    
    # Registra log com base no resultado
    case result do
      {:ok, _} = success ->
        Logger.debug("Operação de leitura executada com sucesso", %{
          module: __MODULE__,
          schema: schema_name,
          circuit: circuit_name
        })
        
        success
        
      {:error, :circuit_open} ->
        Logger.warning("Circuit breaker aberto para operação de leitura", %{
          module: __MODULE__,
          schema: schema_name,
          circuit: circuit_name
        })
        
        {:error, :circuit_open}
        
      {:error, reason} = error ->
        Logger.error("Erro em operação de leitura protegida", %{
          module: __MODULE__,
          schema: schema_name,
          circuit: circuit_name,
          reason: reason
        })
        
        error
    end
  end
  
  @doc """
  Executa uma função protegida por um circuit breaker para operações de escrita.
  
  ## Parâmetros
  
  - `schema` - O schema Ecto envolvido na operação
  - `fun` - A função a ser executada
  - `fallback` - Função de fallback a ser executada se o circuito estiver aberto
  
  ## Retorno
  
  - `{:ok, result}` - Se a função for executada com sucesso
  - `{:error, reason}` - Se ocorrer um erro ao executar a função
  """
  def run_write_protected(schema, fun, fallback \\ nil) do
    circuit_name = get_write_circuit_name(schema)
    schema_name = get_schema_name(schema)
    
    # Executa a função protegida
    result = CircuitBreaker.run(circuit_name, fun, fallback)
    
    # Atualiza métricas com o estado atual do circuit breaker
    update_circuit_breaker_metrics(circuit_name, schema)
    
    # Registra log com base no resultado
    case result do
      {:ok, _} = success ->
        Logger.debug("Operação de escrita executada com sucesso", %{
          module: __MODULE__,
          schema: schema_name,
          circuit: circuit_name
        })
        
        success
        
      {:error, :circuit_open} ->
        Logger.warning("Circuit breaker aberto para operação de escrita", %{
          module: __MODULE__,
          schema: schema_name,
          circuit: circuit_name
        })
        
        {:error, :circuit_open}
        
      {:error, reason} = error ->
        Logger.error("Erro em operação de escrita protegida", %{
          module: __MODULE__,
          schema: schema_name,
          circuit: circuit_name,
          reason: reason
        })
        
        error
    end
  end
  
  @doc """
  Callback chamado quando o estado de um circuit breaker muda.
  
  ## Parâmetros
  
  - `circuit_name` - O nome do circuit breaker
  - `state` - O novo estado do circuit breaker
  """
  def circuit_state_change_callback(circuit_name, state) do
    # Extrai o schema do nome do circuit breaker
    schema = extract_schema_from_circuit_name(circuit_name)
    
    # Determina o tipo de operação
    operation_type = if String.ends_with?(circuit_name, ":read") do
      "leitura"
    else
      "escrita"
    end
    
    # Registra log com base no novo estado
    case state do
      :open ->
        Logger.warning("Circuit breaker aberto para operações de #{operation_type}", %{
          module: __MODULE__,
          schema: schema,
          circuit: circuit_name
        })
        
      :half_open ->
        Logger.info("Circuit breaker meio-aberto para operações de #{operation_type}", %{
          module: __MODULE__,
          schema: schema,
          circuit: circuit_name
        })
        
      :closed ->
        Logger.info("Circuit breaker fechado para operações de #{operation_type}", %{
          module: __MODULE__,
          schema: schema,
          circuit: circuit_name
        })
    end
    
    # Atualiza métricas
    schema_atom = String.to_atom(schema)
    RepositoryMetrics.set_circuit_breaker_state(state, schema_atom)
    
    :ok
  end
  
  @doc """
  Reseta o circuit breaker para um schema específico.
  
  ## Parâmetros
  
  - `schema` - O schema Ecto para o qual resetar os circuit breakers
  
  ## Retorno
  
  - `:ok` - Se os circuit breakers forem resetados com sucesso
  """
  def reset(schema) do
    # Reseta circuit breaker de leitura
    CircuitBreaker.reset(get_read_circuit_name(schema))
    
    # Reseta circuit breaker de escrita
    CircuitBreaker.reset(get_write_circuit_name(schema))
    
    Logger.info("Circuit breakers resetados para schema", %{
      module: __MODULE__,
      schema: get_schema_name(schema)
    })
    
    :ok
  end
  
  @doc """
  Obtém o estado atual do circuit breaker de leitura para um schema específico.
  
  ## Parâmetros
  
  - `schema` - O schema Ecto para o qual obter o estado
  
  ## Retorno
  
  - `:open` - Se o circuito estiver aberto
  - `:half_open` - Se o circuito estiver meio-aberto
  - `:closed` - Se o circuito estiver fechado
  """
  def get_read_state(schema) do
    case CircuitBreaker.state(get_read_circuit_name(schema)) do
      {:ok, state} -> state
      {:error, _} -> :closed  # Valor padrão se o circuit breaker não existir
    end
  end
  
  @doc """
  Obtém o estado atual do circuit breaker de escrita para um schema específico.
  
  ## Parâmetros
  
  - `schema` - O schema Ecto para o qual obter o estado
  
  ## Retorno
  
  - `:open` - Se o circuito estiver aberto
  - `:half_open` - Se o circuito estiver meio-aberto
  - `:closed` - Se o circuito estiver fechado
  """
  def get_write_state(schema) do
    case CircuitBreaker.state(get_write_circuit_name(schema)) do
      {:ok, state} -> state
      {:error, _} -> :closed  # Valor padrão se o circuit breaker não existir
    end
  end
  
  # Funções privadas auxiliares
  
  # Obtém o nome do circuit breaker para operações de leitura
  defp get_read_circuit_name(schema) do
    "repository:#{get_schema_name(schema)}:read"
  end
  
  # Obtém o nome do circuit breaker para operações de escrita
  defp get_write_circuit_name(schema) do
    "repository:#{get_schema_name(schema)}:write"
  end
  
  # Extrai o nome do schema de um módulo ou string
  defp get_schema_name(schema) when is_atom(schema) do
    schema
    |> Atom.to_string()
    |> String.split(".")
    |> List.last()
  end
  
  defp get_schema_name(schema) when is_binary(schema) do
    schema
  end
  
  # Extrai o nome do schema do nome do circuit breaker
  defp extract_schema_from_circuit_name(circuit_name) do
    circuit_name
    |> String.replace_prefix("repository:", "")
    |> String.replace_suffix(":read", "")
    |> String.replace_suffix(":write", "")
  end
  
  # Atualiza métricas com o estado atual do circuit breaker
  defp update_circuit_breaker_metrics(circuit_name, schema) do
    state = case CircuitBreaker.state(circuit_name) do
      {:ok, current_state} -> current_state
      {:error, _} -> :closed  # Valor padrão se o circuit breaker não existir
    end
    schema_atom = if is_atom(schema), do: schema, else: String.to_atom(schema)
    RepositoryMetrics.set_circuit_breaker_state(state, schema_atom)
  end
end
