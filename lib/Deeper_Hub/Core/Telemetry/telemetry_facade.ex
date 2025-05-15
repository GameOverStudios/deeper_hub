defmodule Deeper_Hub.Core.Telemetry.TelemetryFacade do
  @moduledoc """
  Fachada para operações de telemetria no sistema DeeperHub.
  
  Este módulo fornece uma interface simplificada para todas as operações de telemetria,
  permitindo que outros módulos do sistema emitam eventos e gerenciem handlers sem
  conhecer os detalhes de implementação.
  
  A fachada delega as chamadas para o adaptador de telemetria configurado, permitindo
  trocar a implementação subjacente sem afetar os consumidores do serviço.
  
  ## Exemplo de Uso
  
  ```elixir
  alias Deeper_Hub.Core.Telemetry.TelemetryFacade
  
  # Emitir um evento simples
  TelemetryFacade.execute([:deeper_hub, :cache, :hit], %{count: 1}, %{key: "user_123"})
  
  # Medir o tempo de uma operação
  TelemetryFacade.span(
    [:deeper_hub, :repository, :query],
    %{query: "SELECT * FROM users"},
    fn ->
      result = perform_query()
      {result, %{rows: length(result)}}
    end
  )
  ```
  """
  
  # Alias removido pois não é utilizado neste módulo
  
  @doc """
  Executa um evento de telemetria.
  
  ## Parâmetros
  
    * `event_name` - Nome do evento, como uma lista de átomos (ex: [:deeper_hub, :cache, :put])
    * `measurements` - Mapa com medições numéricas associadas ao evento
    * `metadata` - Mapa com metadados contextuais do evento
    
  ## Retorno
  
    * `:ok` - O evento foi emitido com sucesso
  """
  @spec execute([atom()], map(), map()) :: :ok
  def execute(event_name, measurements, metadata) do
    telemetry_adapter().execute(event_name, measurements, metadata)
  end
  
  @doc """
  Anexa um handler a um evento específico de telemetria.
  
  ## Parâmetros
  
    * `handler_id` - Identificador único para o handler
    * `event_name` - Nome do evento ao qual o handler será anexado
    * `handler_function` - Função a ser chamada quando o evento ocorrer
    * `config` - Configuração opcional para o handler
    
  ## Retorno
  
    * `:ok` - O handler foi anexado com sucesso
    * `{:error, reason}` - Falha ao anexar o handler
  """
  @spec attach(term(), [atom()], function(), term()) :: :ok | {:error, term()}
  def attach(handler_id, event_name, handler_function, config) do
    telemetry_adapter().attach(handler_id, event_name, handler_function, config)
  end
  
  @doc """
  Anexa um handler a múltiplos eventos de telemetria.
  
  ## Parâmetros
  
    * `handler_id` - Identificador único para o handler
    * `event_names` - Lista de nomes de eventos aos quais o handler será anexado
    * `handler_function` - Função a ser chamada quando qualquer dos eventos ocorrer
    * `config` - Configuração opcional para o handler
    
  ## Retorno
  
    * `:ok` - O handler foi anexado com sucesso a todos os eventos
    * `{:error, reason}` - Falha ao anexar o handler
  """
  @spec attach_many(term(), [[atom()]], function(), term()) :: :ok | {:error, term()}
  def attach_many(handler_id, event_names, handler_function, config) do
    telemetry_adapter().attach_many(handler_id, event_names, handler_function, config)
  end
  
  @doc """
  Remove um handler previamente anexado.
  
  ## Parâmetros
  
    * `handler_id` - Identificador do handler a ser removido
    
  ## Retorno
  
    * `:ok` - O handler foi removido com sucesso
    * `{:error, :not_found}` - O handler não foi encontrado
  """
  @spec detach(term()) :: :ok | {:error, :not_found}
  def detach(handler_id) do
    telemetry_adapter().detach(handler_id)
  end
  
  @doc """
  Lista todos os handlers atualmente anexados.
  
  ## Retorno
  
    * `[{handler_id, event_name, handler_function, config}]` - Lista de handlers
  """
  @spec list_handlers() :: [{term(), [atom()], function(), term()}]
  def list_handlers do
    telemetry_adapter().list_handlers()
  end
  
  @doc """
  Executa uma operação medindo seu tempo de execução e emitindo eventos de início e fim.
  
  ## Parâmetros
  
    * `event_prefix` - Prefixo do nome do evento (ex: [:deeper_hub, :cache])
    * `start_metadata` - Metadados a serem incluídos no evento de início
    * `function` - Função a ser executada e medida
    
  ## Retorno
  
    * O valor retornado pela função executada
    
  ## Eventos Emitidos
  
    * `event_prefix ++ [:start]` - No início da execução
    * `event_prefix ++ [:stop]` - No fim da execução bem-sucedida
    * `event_prefix ++ [:exception]` - Em caso de exceção
  """
  @spec span([atom()], map(), (-> {term(), map()} | term())) :: term()
  def span(event_prefix, start_metadata, function) do
    telemetry_adapter().span(event_prefix, start_metadata, function)
  end
  
  # Função privada para obter o adaptador de telemetria configurado
  defp telemetry_adapter do
    # Por enquanto, retornamos diretamente o adaptador padrão
    # No futuro, isso pode ser alterado para usar um módulo de configuração
    Deeper_Hub.Core.Telemetry.TelemetryAdapter
  end
end
