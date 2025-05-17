defmodule Deeper_Hub.Core.Data.DBConnection.Telemetry do
  @moduledoc """
  Módulo de telemetria para o DBConnection.
  
  Este módulo fornece funções para monitorar o desempenho das operações
  de banco de dados usando o DBConnection, permitindo a coleta de métricas
  importantes para análise de performance.
  """
  
  alias Deeper_Hub.Core.Logger
  
  @doc """
  Inicializa a telemetria para o DBConnection.
  
  Esta função configura os handlers de telemetria para capturar eventos
  do DBConnection e registrar métricas importantes.
  
  ## Retorno
  
    - `:ok` se a inicialização for bem-sucedida
  """
  @spec initialize() :: :ok
  def initialize do
    Logger.info("Inicializando telemetria para DBConnection", %{module: __MODULE__})
    
    # Definimos uma função para anexar handlers de telemetria com módulo explícito
    # para evitar os avisos sobre funções locais
    attach_handler = fn event_name, event_prefix, handler_function ->
      :telemetry.attach(
        event_name,
        event_prefix,
        &__MODULE__.handle_event/4,
        %{handler: handler_function}
      )
    end
    
    # Configura os handlers de telemetria para o DBConnection usando o módulo explícito
    attach_handler.(
      "db-connection-query-handler",
      [:db_connection, :query],
      :handle_query_event
    )
    
    attach_handler.(
      "db-connection-queue-handler",
      [:db_connection, :queue_time],
      :handle_queue_event
    )
    
    attach_handler.(
      "db-connection-connect-handler",
      [:db_connection, :connect],
      :handle_connect_event
    )
    
    attach_handler.(
      "db-connection-checkout-handler",
      [:db_connection, :checkout],
      :handle_checkout_event
    )
    
    :ok
  end
  
  @doc """
  Função intermediária que recebe eventos de telemetria e os encaminha para o handler específico.
  
  ## Parâmetros
  
    - `event_name`: Nome do evento
    - `measurements`: Medições do evento
    - `metadata`: Metadados do evento
    - `config`: Configuração com o handler específico a ser chamado
  """
  def handle_event(event_name, measurements, metadata, %{handler: handler}) do
    # Chama a função handler específica para o evento
    case handler do
      :handle_query_event -> handle_query_event(event_name, measurements, metadata, nil)
      :handle_queue_event -> handle_queue_event(event_name, measurements, metadata, nil)
      :handle_connect_event -> handle_connect_event(event_name, measurements, metadata, nil)
      :handle_checkout_event -> handle_checkout_event(event_name, measurements, metadata, nil)
      _ -> :ok
    end
  end
  
  @doc """
  Handler para eventos de consulta.
  
  ## Parâmetros
  
    - `event`: O evento de telemetria
    - `measurements`: Medições do evento
    - `metadata`: Metadados do evento
    - `config`: Configuração do handler
  """
  def handle_query_event([:db_connection, :query], measurements, metadata, _config) do
    # Registra o tempo de execução da consulta
    Logger.debug("Consulta executada", %{
      module: __MODULE__,
      query: metadata[:query],
      params: metadata[:params],
      duration_ms: measurements.duration |> convert_time_unit(:native, :millisecond) |> Float.round(2),
      connection_pid: inspect(metadata[:connection_pid])
    })
  end
  
  @doc """
  Handler para eventos de tempo de fila.
  
  ## Parâmetros
  
    - `event`: O evento de telemetria
    - `measurements`: Medições do evento
    - `metadata`: Metadados do evento
    - `config`: Configuração do handler
  """
  def handle_queue_event([:db_connection, :queue_time], measurements, metadata, _config) do
    # Registra o tempo de espera na fila
    queue_time_ms = measurements.duration |> convert_time_unit(:native, :millisecond) |> Float.round(2)
    
    # Alerta se o tempo de fila for muito alto
    if queue_time_ms > 100 do
      Logger.warning("Tempo de fila alto para conexão", %{
        module: __MODULE__,
        queue_time_ms: queue_time_ms,
        connection_pid: inspect(metadata[:connection_pid])
      })
    else
      Logger.debug("Tempo de fila para conexão", %{
        module: __MODULE__,
        queue_time_ms: queue_time_ms,
        connection_pid: inspect(metadata[:connection_pid])
      })
    end
  end
  
  @doc """
  Handler para eventos de conexão.
  
  ## Parâmetros
  
    - `event`: O evento de telemetria
    - `measurements`: Medições do evento
    - `metadata`: Metadados do evento
    - `config`: Configuração do handler
  """
  def handle_connect_event([:db_connection, :connect], measurements, metadata, _config) do
    # Registra o tempo de conexão
    Logger.debug("Conexão estabelecida", %{
      module: __MODULE__,
      duration_ms: measurements.duration |> convert_time_unit(:native, :millisecond) |> Float.round(2),
      connection_pid: inspect(metadata[:connection_pid])
    })
  end
  
  @doc """
  Handler para eventos de checkout.
  
  ## Parâmetros
  
    - `event`: O evento de telemetria
    - `measurements`: Medições do evento
    - `metadata`: Metadados do evento
    - `config`: Configuração do handler
  """
  def handle_checkout_event([:db_connection, :checkout], measurements, metadata, _config) do
    # Registra o tempo de checkout
    checkout_time_ms = measurements.duration |> convert_time_unit(:native, :millisecond) |> Float.round(2)
    
    # Alerta se o tempo de checkout for muito alto
    if checkout_time_ms > 50 do
      Logger.warning("Tempo de checkout alto para conexão", %{
        module: __MODULE__,
        checkout_time_ms: checkout_time_ms,
        connection_pid: inspect(metadata[:connection_pid])
      })
    else
      Logger.debug("Tempo de checkout para conexão", %{
        module: __MODULE__,
        checkout_time_ms: checkout_time_ms,
        connection_pid: inspect(metadata[:connection_pid])
      })
    end
  end
  
  @doc """
  Coleta métricas de desempenho do pool de conexões.
  
  ## Parâmetros
  
    - `pool_name`: Nome do pool de conexões
  
  ## Retorno
  
    - Mapa com métricas de desempenho
  """
  @spec collect_metrics(atom()) :: map()
  def collect_metrics(pool_name) do
    # Obtém métricas do pool de conexões
    case DBConnection.get_connection_metrics(pool_name) do
      {:ok, metrics} ->
        # Formata as métricas para facilitar a leitura
        formatted_metrics = %{
          pool_size: metrics.pool_size,
          active_connections: metrics.active_connections,
          idle_connections: metrics.idle_connections,
          queued_requests: metrics.queued_requests,
          max_overflow: metrics.max_overflow,
          overflow: metrics.overflow
        }
        
        # Registra as métricas
        Logger.debug("Métricas do pool de conexões", %{
          module: __MODULE__,
          pool_name: pool_name,
          metrics: formatted_metrics
        })
        
        formatted_metrics
      {:error, reason} ->
        Logger.error("Falha ao obter métricas do pool de conexões", %{
          module: __MODULE__,
          pool_name: pool_name,
          error: reason
        })
        
        %{}
    end
  end
  
  # Função auxiliar para converter unidades de tempo
  defp convert_time_unit(time, from_unit, to_unit) do
    System.convert_time_unit(time, from_unit, to_unit)
  end
end
