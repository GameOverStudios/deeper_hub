defmodule DeeperHub.Core.Telemetry.Metrics do
  @moduledoc """
  Módulo para definição e coleta de métricas do sistema DeeperHub.
  
  Este módulo fornece funções para definir, coletar e visualizar
  métricas de desempenho do sistema, incluindo estatísticas
  de uso, tempo de resposta, e utilização de recursos.
  """
  
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  
  @doc """
  Retorna as definições de métricas para o sistema.
  
  Estas definições podem ser utilizadas com bibliotecas como
  :telemetry_metrics para visualização e monitoramento.
  
  ## Parâmetros
  
    * `prefix` - Prefixo para eventos de telemetria (padrão: "deeper_hub")
  
  ## Retorno
  
    * Lista de definições de métricas
  """
  @spec definitions(binary()) :: list()
  def definitions(prefix \\ "deeper_hub") do
    import Telemetry.Metrics
    
    [
      # Métricas de sistema
      last_value("#{prefix}.system.memory.total", unit: {:native, :byte}),
      last_value("#{prefix}.system.memory.process", unit: {:native, :byte}),
      last_value("#{prefix}.system.cpu.utilization", unit: {:native, :percent}),
      
      # Métricas de operações
      counter("#{prefix}.operation.count", 
              tags: [:component, :operation]),
      sum("#{prefix}.operation.duration",
          tags: [:component, :operation],
          unit: {:native, :millisecond}),
      
      # Métricas de recursos
      last_value("#{prefix}.resource.utilization", 
                 tags: [:resource_type, :resource_name],
                 unit: {:native, :percent})
    ]
  end
  
  @doc """
  Imprime um relatório com estatísticas do sistema no console.
  
  Coleta as métricas atuais e exibe um relatório formatado.
  
  ## Parâmetros
  
    * `component` - Nome do componente a ser analisado
  
  ## Retorno
  
    * `:ok` - Relatório exibido com sucesso
    * `{:error, reason}` - Erro durante a geração do relatório
  
  ## Exemplos
  
      iex> DeeperHub.Core.Telemetry.Metrics.print_report(:http_server)
      === Relatório de Estatísticas do Componente ===
      Componente: HTTP Server
      Memória: 1.24 MB
      CPU: 5.2%
      ...
      :ok
  """
  @spec print_report(atom()) :: :ok | {:error, term()}
  def print_report(component) do
    # A ser implementado por componentes específicos
    Logger.info("Relatório de estatísticas solicitado para o componente: #{inspect(component)}",
               module: __MODULE__)
    
    :ok
  end
  
  @doc """
  Registra um snapshot das métricas atuais do sistema em um arquivo.
  
  Útil para análises históricas de desempenho.
  
  ## Parâmetros
  
    * `component` - Nome do componente a ser analisado
    * `file_path` - Caminho do arquivo onde salvar (opcional)
  
  ## Retorno
  
    * `{:ok, file_path}` - Snapshot salvo com sucesso
    * `{:error, reason}` - Erro durante o salvamento
  """
  @spec save_snapshot(atom(), binary() | nil) :: {:ok, binary()} | {:error, term()}
  def save_snapshot(component, file_path \\ nil) do
    # Define caminho do arquivo se não fornecido
    _output_path = file_path || "metrics_#{component}_#{:os.system_time(:second)}.json"
    
    # A ser implementado por componentes específicos
    Logger.info("Snapshot de métricas solicitado para o componente: #{inspect(component)}",
               module: __MODULE__)
    
    {:error, :not_implemented}
  end
  
  @doc """
  Registra métricas do sistema no Prometheus, se disponível.
  
  ## Parâmetros
  
    * `component` - Nome do componente a ser monitorado
  
  ## Retorno
  
    * `:ok` - Métricas registradas com sucesso
    * `{:error, reason}` - Erro durante o registro
  """
  @spec register_prometheus_metrics(atom()) :: :ok | {:error, term()}
  def register_prometheus_metrics(component) do
    # TODO: Integração com Prometheus está desativada até que a biblioteca seja adicionada
    # Retorna erro informando que o Prometheus não está disponível
    Logger.info("Métricas Prometheus desativadas para componente: #{inspect(component)}", 
                module: __MODULE__)
    {:error, :prometheus_not_available}
  end
  
  # Funções privadas
  
  # Formata bytes para exibição amigável
  @spec format_bytes(integer()) :: binary()
  def format_bytes(bytes) when is_integer(bytes) do
    cond do
      bytes < 1024 -> "#{bytes} B"
      bytes < 1024 * 1024 -> "#{Float.round(bytes / 1024, 2)} KB"
      bytes < 1024 * 1024 * 1024 -> "#{Float.round(bytes / (1024 * 1024), 2)} MB"
      true -> "#{Float.round(bytes / (1024 * 1024 * 1024), 2)} GB"
    end
  end
  
  # Formata timestamp para exibição amigável
  @spec format_timestamp(integer() | DateTime.t()) :: binary()
  def format_timestamp(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S")
  end
  
  def format_timestamp(timestamp) when is_integer(timestamp) do
    timestamp
    |> DateTime.from_unix!(:second)
    |> format_timestamp()
  end
end
