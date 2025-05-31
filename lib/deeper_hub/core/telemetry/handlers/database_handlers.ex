defmodule DeeperHub.Core.Telemetry.Handlers.DatabaseHandlers do
  @moduledoc """
  Handlers específicos para eventos de telemetria do banco de dados.
  
  Este módulo contém funções nomeadas para processar eventos de telemetria
  relacionados ao banco de dados, evitando o uso de funções locais como
  handlers que podem causar penalidades de performance no sistema de telemetria.
  """
  
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  
  @doc """
  Handler para eventos de consulta ao banco de dados.
  
  Processa eventos relacionados a consultas de banco de dados, permitindo
  métricas e logs detalhados sobre o desempenho das operações de banco de dados.
  
  ## Parâmetros
    * `event` - O evento de telemetria (lista de atoms)
    * `measurements` - Medições associadas ao evento
    * `metadata` - Metadados associados ao evento
    * `config` - Configuração do handler
  """
  @spec handle_query_event(list(atom()), map(), map(), map()) :: :ok
  def handle_query_event([:deeper_hub, :database, :query, event_type] = _event, measurements, metadata, config) do
    case event_type do
      :start ->
        # Registro detalhado de início de consulta se o logging estiver habilitado
        if config[:enable_logging] do
          query = metadata[:query] || "Unknown query"
          params = metadata[:params] || []
          Logger.debug("Início de consulta DB: #{query} com params: #{inspect(params)}", 
            module: __MODULE__, 
            sql: query, 
            sql_params: params
          )
        end
        
      :stop ->
        # Registro de finalização de consulta e métricas de duração
        duration_ms = measurements[:duration_ms] || 0
        
        # Emite métricas para o sistema de telemetria
        :telemetry.execute(
          [:deeper_hub, :database, :metrics],
          %{
            duration_ms: duration_ms,
            count: 1
          },
          %{
            pool: config[:pool_name],
            operation_type: :query,
            result_type: get_result_type(metadata[:result_info])
          }
        )
        
        # Registro detalhado se o logging estiver habilitado
        if config[:enable_logging] do
          Logger.debug("Consulta DB concluída em #{duration_ms}ms", 
            module: __MODULE__, 
            duration_ms: duration_ms,
            result_type: get_result_type(metadata[:result_info])
          )
        end
        
      _ ->
        # Outros eventos do banco de dados podem ser tratados aqui
        :ok
    end
  end
  
  @doc """
  Handler para eventos de conexão com o banco de dados.
  
  Processa eventos relacionados à abertura e fechamento de conexões,
  útil para monitorar o pool de conexões.
  
  ## Parâmetros
    * `event` - O evento de telemetria (lista de atoms)
    * `measurements` - Medições associadas ao evento
    * `metadata` - Metadados associados ao evento
    * `config` - Configuração do handler
  """
  @spec handle_connection_event(list(atom()), map(), map(), map()) :: :ok
  def handle_connection_event([:deeper_hub, :database, :connection, event_type] = _event, _measurements, metadata, config) do
    case event_type do
      :connect ->
        # Registro de novas conexões
        if config[:enable_logging] do
          Logger.debug("Nova conexão DB estabelecida", 
            module: __MODULE__, 
            pool: config[:pool_name]
          )
        end
        
      :disconnect ->
        # Registro de desconexões
        if config[:enable_logging] do
          reason = metadata[:reason] || :unknown
          Logger.debug("Conexão DB encerrada: #{inspect(reason)}", 
            module: __MODULE__, 
            pool: config[:pool_name],
            reason: reason
          )
        end
        
      _ ->
        # Outros eventos de conexão podem ser tratados aqui
        :ok
    end
  end
  
  # Funções privadas auxiliares
  
  # Determina o tipo de resultado da operação
  defp get_result_type(result_info) do
    cond do
      is_nil(result_info) -> :unknown
      is_map(result_info) && Map.has_key?(result_info, :error) -> :error
      is_map(result_info) && Map.has_key?(result_info, :command) -> result_info.command
      is_map(result_info) && Map.has_key?(result_info, :type) -> result_info.type
      true -> :unknown
    end
  end
end
