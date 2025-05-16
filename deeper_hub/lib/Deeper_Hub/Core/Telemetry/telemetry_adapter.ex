defmodule Deeper_Hub.Core.Telemetry.TelemetryAdapter do
  @moduledoc """
  Adaptador para a biblioteca Telemetry que implementa o comportamento TelemetryBehaviour.
  
  Este módulo fornece uma implementação completa das operações de telemetria usando
  a biblioteca `:telemetry`, permitindo a emissão de eventos e gerenciamento de handlers
  para monitoramento e observabilidade do sistema.
  
  ## Funcionalidades
  
  * 📊 Emissão de eventos de telemetria
  * 🔄 Gerenciamento do ciclo de vida de handlers
  * ⏱️ Medição de spans (operações com início e fim)
  * 🔍 Integração com sistemas de observabilidade
  
  ## Exemplos
  
      # Emitir um evento simples
      TelemetryAdapter.execute([:deeper_hub, :cache, :hit], %{count: 1}, %{key: "user_123"})
      
      # Medir o tempo de uma operação
      TelemetryAdapter.span(
        [:deeper_hub, :repository, :query],
        %{query: "SELECT * FROM users"},
        fn ->
          result = perform_query()
          {result, %{rows: length(result)}}
        end
      )
  """
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Telemetry.TelemetryBehaviour
  
  @behaviour TelemetryBehaviour
  
  @doc """
  Executa um evento de telemetria.
  
  ## Parâmetros
  
    * `event_name` - Nome do evento, como uma lista de átomos (ex: [:deeper_hub, :cache, :put])
    * `measurements` - Mapa com medições numéricas associadas ao evento
    * `metadata` - Mapa com metadados contextuais do evento
    
  ## Retorno
  
    * `:ok` - O evento foi emitido com sucesso
    
  ## Exemplos
  
      TelemetryAdapter.execute(
        [:deeper_hub, :cache, :hit],
        %{count: 1},
        %{key: "user_123", cache: :user_cache}
      )
  """
  @impl TelemetryBehaviour
  @spec execute([atom()], map(), map()) :: :ok
  def execute(event_name, measurements, metadata) do
    # Log de início da operação
    Logger.debug("Emitindo evento de telemetria", %{
      module: __MODULE__,
      event: event_name,
      measurements: sanitize_measurements(measurements),
      metadata: sanitize_metadata(metadata)
    })
    
    # Executa o evento usando a biblioteca :telemetry
    :telemetry.execute(event_name, measurements, metadata)
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
    
  ## Exemplos
  
      TelemetryAdapter.attach(
        "log-cache-hits",
        [:deeper_hub, :cache, :hit],
        &MyApp.TelemetryHandlers.handle_cache_hit/4,
        %{threshold: 100}
      )
  """
  @impl TelemetryBehaviour
  @spec attach(term(), [atom()], function(), term()) :: :ok | {:error, term()}
  def attach(handler_id, event_name, handler_function, config) do
    # Log de início da operação
    Logger.debug("Anexando handler de telemetria", %{
      module: __MODULE__,
      handler_id: handler_id,
      event: event_name
    })
    
    try do
      # Anexa o handler usando a biblioteca :telemetry
      :telemetry.attach(handler_id, event_name, handler_function, config)
    rescue
      e ->
        Logger.error("Falha ao anexar handler de telemetria", %{
          module: __MODULE__,
          handler_id: handler_id,
          event: event_name,
          error: inspect(e)
        })
        
        {:error, e}
    end
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
    
  ## Exemplos
  
      TelemetryAdapter.attach_many(
        "log-cache-operations",
        [
          [:deeper_hub, :cache, :hit],
          [:deeper_hub, :cache, :miss],
          [:deeper_hub, :cache, :update]
        ],
        &MyApp.TelemetryHandlers.handle_cache_operation/4,
        nil
      )
  """
  @impl TelemetryBehaviour
  @spec attach_many(term(), [[atom()]], function(), term()) :: :ok | {:error, term()}
  def attach_many(handler_id, event_names, handler_function, config) do
    # Log de início da operação
    Logger.debug("Anexando handler a múltiplos eventos de telemetria", %{
      module: __MODULE__,
      handler_id: handler_id,
      events: event_names
    })
    
    try do
      # Anexa o handler a múltiplos eventos usando a biblioteca :telemetry
      :telemetry.attach_many(handler_id, event_names, handler_function, config)
    rescue
      e ->
        Logger.error("Falha ao anexar handler a múltiplos eventos de telemetria", %{
          module: __MODULE__,
          handler_id: handler_id,
          events: event_names,
          error: inspect(e)
        })
        
        {:error, e}
    end
  end
  
  @doc """
  Remove um handler previamente anexado.
  
  ## Parâmetros
  
    * `handler_id` - Identificador do handler a ser removido
    
  ## Retorno
  
    * `:ok` - O handler foi removido com sucesso
    * `{:error, :not_found}` - O handler não foi encontrado
    
  ## Exemplos
  
      TelemetryAdapter.detach("log-cache-hits")
  """
  @impl TelemetryBehaviour
  @spec detach(term()) :: :ok | {:error, :not_found}
  def detach(handler_id) do
    # Log de início da operação
    Logger.debug("Removendo handler de telemetria", %{
      module: __MODULE__,
      handler_id: handler_id
    })
    
    # Remove o handler usando a biblioteca :telemetry
    :telemetry.detach(handler_id)
  end
  
  @doc """
  Lista todos os handlers atualmente anexados.
  
  ## Retorno
  
    * `[{handler_id, event_name, handler_function, config}]` - Lista de handlers
    
  ## Exemplos
  
  ```elixir
  # Listar todos os handlers registrados
  handlers = TelemetryAdapter.list_handlers()
  ```
  """
  @impl TelemetryBehaviour
  @spec list_handlers() :: [{term(), [atom()], function(), term()}]
  def list_handlers do
    # Log de início da operação
    Logger.debug("Listando handlers de telemetria", %{
      module: __MODULE__
    })
    
    # Lista os handlers usando a biblioteca :telemetry
    :telemetry.list_handlers([])
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
    
  ## Exemplos
  
      result = TelemetryAdapter.span(
        [:deeper_hub, :repository, :query],
        %{query: "SELECT * FROM users"},
        fn ->
          result = perform_query()
          {result, %{rows: length(result)}}
        end
      )
  """
  @impl TelemetryBehaviour
  @spec span([atom()], map(), (-> {term(), map()} | term())) :: term()
  def span(event_prefix, start_metadata, function) do
    # Log de início da operação
    Logger.debug("Iniciando span de telemetria", %{
      module: __MODULE__,
      event_prefix: event_prefix,
      metadata: sanitize_metadata(start_metadata)
    })
    
    # Executa a operação dentro de um span usando a biblioteca :telemetry
    :telemetry.span(event_prefix, start_metadata, function)
  end
  
  # Funções privadas para sanitização de dados
  
  # Sanitiza medições para evitar exposição de dados sensíveis nos logs
  @spec sanitize_measurements(map()) :: map()
  defp sanitize_measurements(measurements) do
    # Por padrão, as medições são valores numéricos e podem ser logados diretamente
    # Se houver medições sensíveis, elas podem ser filtradas aqui
    measurements
  end
  
  # Sanitiza metadados para evitar exposição de dados sensíveis nos logs
  @spec sanitize_metadata(map()) :: map()
  defp sanitize_metadata(metadata) do
    # Filtra campos potencialmente sensíveis dos metadados
    sensitive_keys = [:password, :token, :api_key, :secret, :credentials]
    
    metadata
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      if key in sensitive_keys do
        Map.put(acc, key, "[REDACTED]")
      else
        Map.put(acc, key, value)
      end
    end)
  end
end
