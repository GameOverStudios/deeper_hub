defmodule Deeper_Hub.Core.Metrics.MetricsApplication do
  @moduledoc """
  Módulo responsável pela integração do sistema de métricas com a aplicação principal.
  
  Este módulo fornece funções para adicionar o supervisor de métricas à árvore de supervisão
  da aplicação principal e garantir que o sistema de métricas seja inicializado corretamente.
  """
  
  alias Deeper_Hub.Core.Metrics.MetricsSupervisor
  alias Deeper_Hub.Core.Metrics.MetricsConfig
  alias Deeper_Hub.Core.Metrics.MetricsIntegration
  alias Deeper_Hub.Core.Logger
  
  @doc """
  Retorna a lista de processos filhos para adicionar à árvore de supervisão da aplicação.
  
  ## Retorno
  
    - Lista de especificações de processos filhos
  """
  @spec child_specs() :: list()
  def child_specs do
    [
      {MetricsSupervisor, []}
    ]
  end
  
  @doc """
  Inicializa o sistema de métricas com base nas configurações carregadas.
  
  ## Retorno
  
    - `:ok` se a inicialização for bem-sucedida
    - `{:error, reason}` em caso de falha
  """
  @spec initialize() :: :ok | {:error, term()}
  def initialize do
    try do
      # Carrega as configurações
      config = MetricsConfig.load_config()
      
      # Verifica se o sistema de métricas está habilitado
      if config.enabled do
        # Inicializa o sistema de métricas com as configurações carregadas
        MetricsIntegration.initialize(
          config.export_interval,
          config.export_format,
          config.export_path
        )
      else
        Logger.info("Sistema de métricas desabilitado por configuração", %{
          module: __MODULE__
        })
        
        :ok
      end
    rescue
      e ->
        Logger.error("Falha ao inicializar o sistema de métricas", %{
          module: __MODULE__,
          error: e,
          stacktrace: __STACKTRACE__
        })
        
        {:error, e}
    end
  end
  
  @doc """
  Finaliza o sistema de métricas, salvando as métricas coletadas.
  
  ## Parâmetros
  
    - `format`: Formato para salvar as métricas (:json, :csv, :prometheus)
    - `path`: Caminho para salvar as métricas
  
  ## Retorno
  
    - `{:ok, filepath}` se o salvamento for bem-sucedido
    - `{:error, reason}` em caso de falha
  """
  @spec finalize(atom(), String.t()) :: {:ok, String.t()} | {:error, term()}
  def finalize(format \\ :json, path \\ "logs/metrics") do
    try do
      # Gera um relatório final
      report = MetricsIntegration.generate_report(format)
      
      # Salva o relatório
      MetricsIntegration.save_report(report, format, path)
    rescue
      e ->
        Logger.error("Falha ao finalizar o sistema de métricas", %{
          module: __MODULE__,
          error: e,
          stacktrace: __STACKTRACE__
        })
        
        {:error, e}
    end
  end
end
