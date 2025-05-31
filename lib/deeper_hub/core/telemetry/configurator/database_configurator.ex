defmodule DeeperHub.Core.Telemetry.Configurator.DatabaseConfigurator do
  @moduledoc """
  Configurador específico para a telemetria do banco de dados.
  
  Este módulo é responsável por configurar todos os eventos e handlers
  de telemetria relacionados ao banco de dados, utilizando funções nomeadas
  para evitar penalidades de performance.
  """
  
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  alias DeeperHub.Core.Telemetry.Handlers.DatabaseHandlers
  
  @doc """
  Configura os eventos de telemetria para o banco de dados.
  
  Registra handlers nomeados para processar eventos de consulta e conexão
  do banco de dados, assegurando que não sejam utilizadas funções anônimas
  ou locais como handlers.
  
  ## Parâmetros
    * `opts` - Opções de configuração
    
  ## Retorno
    * `:ok` - Se os handlers forem configurados com sucesso
    * `{:error, term()}` - Se ocorrer um erro durante a configuração
  """
  @spec setup(keyword()) :: :ok | {:error, term()}
  def setup(opts \\ []) do
    try do
      Logger.debug("Configurando handlers de telemetria para o banco de dados", module: __MODULE__)
      
      # Configura handlers para eventos de consulta
      configure_query_handlers(opts)
      
      # Configura handlers para eventos de conexão
      configure_connection_handlers(opts)
      
      Logger.info("Handlers de telemetria do banco de dados configurados com sucesso", module: __MODULE__)
      :ok
    rescue
      e ->
        Logger.error("Erro ao configurar handlers de telemetria do banco de dados: #{inspect(e)}", 
                    module: __MODULE__)
        {:error, e}
    end
  end
  
  # Configura handlers para eventos de consulta do banco de dados
  defp configure_query_handlers(opts) do
    # Eventos relacionados a consultas
    query_events = [
      [:deeper_hub, :database, :query, :start],
      [:deeper_hub, :database, :query, :stop]
    ]
    
    # Registra os handlers para cada evento
    Enum.each(query_events, fn event ->
      handler_id = "deeper_hub_database_#{Enum.join(event, "_")}"
      
      :telemetry.attach(
        handler_id,
        event,
        &DatabaseHandlers.handle_query_event/4,
        %{
          pool_name: Keyword.get(opts, :pool_name, DeeperHub.DBConnectionPool),
          enable_logging: Keyword.get(opts, :enable_logging, false)
        }
      )
      
      Logger.debug("Handler de telemetria registrado: #{handler_id}", module: __MODULE__)
    end)
  end
  
  # Configura handlers para eventos de conexão do banco de dados
  defp configure_connection_handlers(opts) do
    # Eventos relacionados a conexões
    connection_events = [
      [:deeper_hub, :database, :connection, :connect],
      [:deeper_hub, :database, :connection, :disconnect]
    ]
    
    # Registra os handlers para cada evento
    Enum.each(connection_events, fn event ->
      handler_id = "deeper_hub_database_#{Enum.join(event, "_")}"
      
      :telemetry.attach(
        handler_id,
        event,
        &DatabaseHandlers.handle_connection_event/4,
        %{
          pool_name: Keyword.get(opts, :pool_name, DeeperHub.DBConnectionPool),
          enable_logging: Keyword.get(opts, :enable_logging, false)
        }
      )
      
      Logger.debug("Handler de telemetria registrado: #{handler_id}", module: __MODULE__)
    end)
  end
end
