defmodule DeeperHub.Core.Cache.Telemetry.Handlers do
  @moduledoc """
  Handlers específicos para eventos de telemetria do cache.
  
  Este módulo contém funções nomeadas para processar eventos de telemetria
  relacionados ao subsistema de cache, evitando o uso de funções locais como
  handlers que podem causar penalidades de performance no sistema de telemetria.
  """
  
  require DeeperHub.Core.Logger
  
  @doc """
  Handler para eventos de telemetria do Cachex.
  
  Processa eventos [:cachex, :action], [:cachex, :action, :start] e 
  [:cachex, :action, :stop], convertendo-os em métricas no formato padrão
  do DeeperHub.
  
  ## Parâmetros
    * `event` - O evento de telemetria (lista de atoms)
    * `measurements` - Medições associadas ao evento
    * `metadata` - Metadados associados ao evento
    * `config` - Configuração do handler
  """
  @spec handle_event(list(atom()), map(), map(), map()) :: :ok
  def handle_event(event, measurements, metadata, config) do
    case event do
      [:cachex, :action, :stop] ->
        # Emite métricas para operações concluídas
        :telemetry.execute(
          [:deeper_hub, :cache, :operation],
          %{
            duration: measurements[:duration] || 0,
            count: 1
          },
          %{
            cache_name: config.cache_name,
            action: metadata[:action] || :unknown,
            result: metadata[:result] || :unknown
          }
        )

      [:cachex, :action] ->
        # Emite métricas para ações do cache
        :telemetry.execute(
          [:deeper_hub, :cache, :action],
          %{count: 1},
          %{
            cache_name: config.cache_name,
            action: metadata[:action] || :unknown
          }
        )

      _ ->
        # Outros eventos podem ser tratados aqui no futuro
        :ok
    end
  end
end
