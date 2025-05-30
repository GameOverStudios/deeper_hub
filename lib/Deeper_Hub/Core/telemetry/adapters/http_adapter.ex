defmodule DeeperHub.Core.Telemetry.Adapters.HttpAdapter do
  @moduledoc """
  Adaptador de telemetria para o subsistema HTTP do DeeperHub.
  
  Este adaptador é responsável por coletar e relatar métricas relacionadas a:
  - Requisições HTTP (tempo de resposta, status code, etc)
  - Conexões ativas
  - Taxa de erros
  - Latência das respostas
  """
  
  alias DeeperHub.Core.Telemetry.Reporter
  alias DeeperHub.Core.Telemetry.Metrics
  
  @doc """
  Inicializa o adaptador de telemetria para o subsistema HTTP.
  
  ## Parâmetros
  
  - `opts` - Opções adicionais de configuração.
  
  ## Retorno
  
  - `{:ok, pid}` - Se o adaptador for inicializado com sucesso.
  - `{:error, reason}` - Se ocorrer um erro durante a inicialização.
  
  ## Exemplos
  
      iex> DeeperHub.Core.Telemetry.Adapters.HttpAdapter.setup()
      {:ok, #PID<0.123.0>}
  """
  @spec setup(keyword()) :: {:ok, pid()} | {:error, term()}
  def setup(opts \\ []) do
    component = :http
    
    try do
      DeeperHub.Core.Telemetry.Configurator.setup(component, opts)
    rescue
      e -> {:error, e}
    end
  end
  
  @doc """
  Relata uma requisição HTTP recebida.
  
  ## Parâmetros
  
  - `method` - Método HTTP (GET, POST, etc)
  - `path` - Caminho da requisição
  - `opts` - Opções adicionais (headers, query params, etc)
  
  ## Retorno
  
  - `:ok` - Se o evento for relatado com sucesso.
  - `{:error, reason}` - Se ocorrer um erro durante o relato.
  """
  @spec report_request(atom(), String.t(), keyword()) :: :ok | {:error, term()}
  def report_request(method, path, opts \\ []) do
    Reporter.report_event([:deeper_hub, :http, :request], %{
      method: method,
      path: path,
      timestamp: DateTime.utc_now()
    }, opts)
  end
  
  @doc """
  Relata uma resposta HTTP enviada.
  
  ## Parâmetros
  
  - `status_code` - Código de status HTTP (200, 404, 500, etc)
  - `duration_ms` - Duração do processamento em milissegundos
  - `opts` - Opções adicionais (tamanho da resposta, etc)
  
  ## Retorno
  
  - `:ok` - Se o evento for relatado com sucesso.
  - `{:error, reason}` - Se ocorrer um erro durante o relato.
  """
  @spec report_response(integer(), float(), keyword()) :: :ok | {:error, term()}
  def report_response(status_code, duration_ms, opts \\ []) do
    Reporter.report_event([:deeper_hub, :http, :response], %{
      status_code: status_code,
      duration_ms: duration_ms,
      timestamp: DateTime.utc_now()
    }, opts)
  end
  
  @doc """
  Relata um erro no processamento de uma requisição HTTP.
  
  ## Parâmetros
  
  - `error_type` - Tipo do erro (timeout, connection_error, etc)
  - `error_details` - Detalhes adicionais sobre o erro
  - `opts` - Opções adicionais
  
  ## Retorno
  
  - `:ok` - Se o evento for relatado com sucesso.
  - `{:error, reason}` - Se ocorrer um erro durante o relato.
  """
  @spec report_error(atom(), map(), keyword()) :: :ok | {:error, term()}
  def report_error(error_type, error_details, opts \\ []) do
    Reporter.report_event([:deeper_hub, :http, :error], %{
      error_type: error_type,
      error_details: error_details,
      timestamp: DateTime.utc_now()
    }, opts)
  end
  
  @doc """
  Define as métricas específicas para o subsistema HTTP.
  
  ## Retorno
  
  - `list()` - Lista de métricas definidas.
  """
  @spec metrics() :: list()
  def metrics do
    Metrics.definitions("deeper_hub.http")
    |> Enum.concat([
      # Métricas específicas de HTTP
      Telemetry.Metrics.counter("deeper_hub.http.request.count", 
        tags: [:method, :path],
        description: "Contador de requisições HTTP recebidas"),
        
      Telemetry.Metrics.summary("deeper_hub.http.response.duration",
        unit: {:native, :millisecond},
        tags: [:status_code],
        description: "Tempo de processamento das requisições HTTP"),
        
      Telemetry.Metrics.counter("deeper_hub.http.error.count",
        tags: [:error_type],
        description: "Contador de erros HTTP por tipo")
    ])
  end
end
