defmodule DeeperHub.Core.Telemetry.Adapters.DatabaseAdapter do
  @moduledoc """
  Adaptador de telemetria para o subsistema de banco de dados do DeeperHub.
  
  Este adaptador é responsável por coletar e relatar métricas relacionadas a:
  - Consultas SQL
  - Performance do banco de dados
  - Pool de conexões
  - Migrações
  """
  
  alias DeeperHub.Core.Telemetry.Reporter
  alias DeeperHub.Core.Telemetry.Metrics
  
  @doc """
  Inicializa o adaptador de telemetria para o subsistema de banco de dados.
  
  ## Parâmetros
  
  - `opts` - Opções adicionais de configuração.
  
  ## Retorno
  
  - `{:ok, pid}` - Se o adaptador for inicializado com sucesso.
  - `{:error, reason}` - Se ocorrer um erro durante a inicialização.
  
  ## Exemplos
  
      iex> DeeperHub.Core.Telemetry.Adapters.DatabaseAdapter.setup()
      {:ok, #PID<0.123.0>}
  """
  @spec setup(keyword()) :: {:ok, pid()} | {:error, term()}
  def setup(opts \\ []) do
    component = :database
    
    try do
      DeeperHub.Core.Telemetry.Configurator.setup(component, opts)
    rescue
      e -> {:error, e}
    end
  end
  
  @doc """
  Relata o início de uma consulta SQL.
  
  ## Parâmetros
  
  - `query` - A consulta SQL
  - `params` - Parâmetros da consulta
  - `opts` - Opções adicionais
  
  ## Retorno
  
  - `{:ok, reference}` - Uma referência para ser usada ao finalizar a consulta.
  - `{:error, reason}` - Se ocorrer um erro durante o relato.
  """
  @spec start_query(String.t(), list(), keyword()) :: {:ok, reference()} | {:error, term()}
  def start_query(query, params, opts \\ []) do
    reference = make_ref()
    
    case Reporter.report_event([:deeper_hub, :database, :query, :start], %{
      query: query,
      params: params,
      reference: reference,
      timestamp: DateTime.utc_now()
    }, opts) do
      :ok -> {:ok, reference}
      error -> error
    end
  end
  
  @doc """
  Relata o fim de uma consulta SQL.
  
  ## Parâmetros
  
  - `reference` - A referência retornada por `start_query/3`
  - `result` - O resultado da consulta
  - `duration_ms` - Duração da consulta em milissegundos
  - `opts` - Opções adicionais
  
  ## Retorno
  
  - `:ok` - Se o evento for relatado com sucesso.
  - `{:error, reason}` - Se ocorrer um erro durante o relato.
  """
  @spec stop_query(reference(), term(), float(), keyword()) :: :ok | {:error, term()}
  def stop_query(reference, result, duration_ms, opts \\ []) do
    # Extrair informações básicas do resultado para evitar dados sensíveis ou muito grandes
    result_info = extract_result_info(result)
    
    Reporter.report_event([:deeper_hub, :database, :query, :stop], %{
      reference: reference,
      result_info: result_info,
      duration_ms: duration_ms,
      timestamp: DateTime.utc_now()
    }, opts)
  end
  
  @doc """
  Relata um erro em uma consulta SQL.
  
  ## Parâmetros
  
  - `query` - A consulta SQL
  - `params` - Parâmetros da consulta
  - `error` - O erro ocorrido
  - `opts` - Opções adicionais
  
  ## Retorno
  
  - `:ok` - Se o evento for relatado com sucesso.
  - `{:error, reason}` - Se ocorrer um erro durante o relato.
  """
  @spec report_query_error(String.t(), list(), term(), keyword()) :: :ok | {:error, term()}
  def report_query_error(query, params, error, opts \\ []) do
    Reporter.report_event([:deeper_hub, :database, :query, :error], %{
      query: query,
      params: params,
      error: sanitize_error(error),
      timestamp: DateTime.utc_now()
    }, opts)
  end
  
  @doc """
  Relata o estado atual do pool de conexões.
  
  ## Parâmetros
  
  - `pool_name` - Nome do pool de conexões
  - `size` - Tamanho atual do pool
  - `available` - Número de conexões disponíveis
  - `opts` - Opções adicionais
  
  ## Retorno
  
  - `:ok` - Se o evento for relatado com sucesso.
  - `{:error, reason}` - Se ocorrer um erro durante o relato.
  """
  @spec report_pool_status(atom(), integer(), integer(), keyword()) :: :ok | {:error, term()}
  def report_pool_status(pool_name, size, available, opts \\ []) do
    Reporter.report_event([:deeper_hub, :database, :pool, :status], %{
      pool_name: pool_name,
      size: size,
      available: available,
      utilization: (size - available) / max(size, 1),
      timestamp: DateTime.utc_now()
    }, opts)
  end
  
  @doc """
  Define as métricas específicas para o subsistema de banco de dados.
  
  ## Retorno
  
  - `list()` - Lista de métricas definidas.
  """
  @spec metrics() :: list()
  def metrics do
    Metrics.definitions("deeper_hub.database")
    |> Enum.concat([
      # Métricas específicas de banco de dados
      Telemetry.Metrics.counter("deeper_hub.database.query.count",
        description: "Contador de consultas SQL executadas"),
        
      Telemetry.Metrics.summary("deeper_hub.database.query.duration",
        unit: {:native, :millisecond},
        description: "Duração das consultas SQL"),
        
      Telemetry.Metrics.counter("deeper_hub.database.query.error.count",
        description: "Contador de erros em consultas SQL"),
        
      Telemetry.Metrics.last_value("deeper_hub.database.pool.utilization",
        tags: [:pool_name],
        description: "Taxa de utilização do pool de conexões"),
        
      Telemetry.Metrics.last_value("deeper_hub.database.pool.size",
        tags: [:pool_name],
        description: "Tamanho atual do pool de conexões"),
        
      Telemetry.Metrics.last_value("deeper_hub.database.pool.available",
        tags: [:pool_name],
        description: "Número de conexões disponíveis no pool")
    ])
  end
  
  # Funções privadas auxiliares
  
  @spec extract_result_info(term()) :: map()
  defp extract_result_info(result) do
    try do
      case result do
        %{command: command, columns: columns, rows: _rows, num_rows: num_rows} ->
          %{
            command: command,
            columns_count: length(columns),
            rows_count: num_rows
          }
        {:ok, result} when is_map(result) ->
          extract_result_info(result)
        _ ->
          %{type: "other"}
      end
    rescue
      _ -> %{type: "unknown"}
    end
  end
  
  @spec sanitize_error(term()) :: map()
  defp sanitize_error(error) do
    try do
      # Converter o erro para uma representação segura sem dados sensíveis
      %{
        type: get_error_type(error),
        message: get_error_message(error)
      }
    rescue
      _ -> %{type: "unknown_error", message: "Erro não identificado"}
    end
  end
  
  @spec get_error_type(term()) :: String.t()
  defp get_error_type(error) do
    cond do
      is_exception(error) -> error.__struct__ |> to_string()
      is_atom(error) -> to_string(error)
      true -> "unknown_error_type"
    end
  end
  
  @spec get_error_message(term()) :: String.t()
  defp get_error_message(error) do
    cond do
      is_exception(error) && Map.has_key?(error, :message) -> error.message
      is_binary(error) -> error
      is_atom(error) -> to_string(error)
      true -> inspect(error, safe: true, limit: 50)
    end
  end
end
