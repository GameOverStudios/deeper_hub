defmodule Deeper_Hub.Core.Telemetry do
  @moduledoc """
  Módulo central de telemetria para o DeeperHub. 🔍
  
  Este módulo fornece uma interface unificada para telemetria em todo o sistema,
  permitindo rastrear spans de execução, publicar eventos e coletar métricas.
  
  ## Eventos de Telemetria
  
  Os eventos de telemetria seguem uma convenção de nomenclatura padronizada:
  `domínio.entidade.ação` (ex: `auth.user.login`).
  
  Cada evento de telemetria pode emitir três tipos de sub-eventos:
  - `start` - Quando a operação inicia
  - `stop` - Quando a operação é concluída com sucesso
  - `exception` - Quando a operação falha com uma exceção
  
  ## Métricas Coletadas
  
  Para cada span de telemetria, as seguintes métricas são coletadas:
  - Duração da operação (em microssegundos)
  - Resultado (sucesso/erro)
  - Metadados contextuais
  
  ## Integração com Logging e Métricas
  
  Este módulo se integra automaticamente com:
  - `Deeper_Hub.Core.Logger` para registro de logs
  - `Deeper_Hub.Core.Metrics` para armazenamento de métricas
  """
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Metrics
  
  @type span_ref :: reference()
  @type event_name :: String.t()
  @type metadata :: map()
  
  @doc """
  Configura handlers de telemetria para eventos específicos.
  
  Esta função deve ser chamada durante a inicialização da aplicação para
  configurar os handlers que processarão os eventos de telemetria.
  
  ## Parâmetros
  
  - `handlers`: Lista de handlers a serem configurados (opcional)
  - `events`: Lista de eventos a serem monitorados (opcional)
  
  ## Retorno
  
  - `:ok` se a configuração for bem-sucedida
  
  ## Exemplo
  
  ```elixir
  Telemetry.setup([
    {MyApp.TelemetryHandler, :handle_event},
    {AnotherHandler, :process}
  ])
  ```
  """
  @spec setup(keyword(), list()) :: :ok
  def setup(handlers \\ [], events \\ []) do
    Logger.info("Configurando telemetria", %{module: __MODULE__})
    
    # Eventos padrão que serão monitorados se nenhum for especificado
    default_events = [
      [:deeper_hub, :auth, :start],
      [:deeper_hub, :auth, :stop],
      [:deeper_hub, :auth, :exception],
      [:deeper_hub, :data, :start],
      [:deeper_hub, :data, :stop],
      [:deeper_hub, :data, :exception],
      [:deeper_hub, :api, :start],
      [:deeper_hub, :api, :stop],
      [:deeper_hub, :api, :exception]
    ]
    
    # Combina eventos padrão com eventos personalizados
    all_events = if Enum.empty?(events), do: default_events, else: events
    
    # Handlers padrão para logging e métricas
    default_handlers = [
      {__MODULE__, :handle_event}
    ]
    
    # Combina handlers padrão com handlers personalizados
    all_handlers = default_handlers ++ handlers
    
    # Registra handlers para cada evento
    for event <- all_events do
      event_name = Enum.join(event, ".")
      
      for {module, function} <- all_handlers do
        handler_id = "#{inspect(module)}.#{function}.#{event_name}"
        
        # Registra o handler usando função de callback
        # A função attach/4 espera uma função que recebe 4 argumentos
        :telemetry.attach(
          handler_id,
          event,
          &apply(module, function, [&1, &2, &3, &4]),
          nil
        )
      end
    end
    
    Logger.info("Telemetria configurada com sucesso", %{
      module: __MODULE__,
      events: length(all_events),
      handlers: length(all_handlers)
    })
    
    :ok
  end
  
  @doc """
  Inicia um span de telemetria.
  
  Um span representa uma operação que tem um início e um fim. Esta função
  marca o início da operação e retorna uma referência que deve ser usada
  para finalizar o span.
  
  ## Parâmetros
  
  - `event_name`: Nome do evento (ex: "auth.user.login")
  - `metadata`: Metadados adicionais para o evento (opcional)
  
  ## Retorno
  
  - Uma referência ao span que deve ser passada para `stop_span/2`
  
  ## Exemplo
  
  ```elixir
  span = Telemetry.start_span("auth.user.login", %{user_id: user.id})
  # ... código da operação ...
  Telemetry.stop_span(span, %{result: result})
  ```
  """
  @spec start_span(event_name(), metadata()) :: span_ref()
  def start_span(event_name, metadata \\ %{}) do
    # Converte o nome do evento em uma lista de atoms
    event_parts = event_name |> String.split(".") |> Enum.map(&String.to_atom/1)
    start_event = [:deeper_hub | event_parts] ++ [:start]
    
    # Adiciona timestamp e informações do processo
    metadata = Map.merge(metadata, %{
      system_time: System.system_time(),
      monotonic_time: System.monotonic_time(),
      process_info: get_process_info()
    })
    
    # Emite evento de início
    :telemetry.execute(start_event, %{}, sanitize_metadata(metadata))
    
    # Cria e retorna uma referência ao span
    %{
      ref: make_ref(),
      name: event_name,
      start_time: System.monotonic_time(),
      metadata: metadata
    }
  end
  
  @doc """
  Finaliza um span de telemetria com sucesso.
  
  Esta função marca o fim de uma operação iniciada com `start_span/2`.
  
  ## Parâmetros
  
  - `span`: Referência ao span retornada por `start_span/2`
  - `result_metadata`: Metadados adicionais sobre o resultado (opcional)
  
  ## Retorno
  
  - `:ok`
  
  ## Exemplo
  
  ```elixir
  Telemetry.stop_span(span, %{result: {:ok, user}})
  ```
  """
  @spec stop_span(map(), metadata()) :: :ok
  def stop_span(span, result_metadata \\ %{}) do
    stop_time = System.monotonic_time()
    duration = stop_time - span.start_time
    
    # Converte o nome do evento em uma lista de atoms
    event_parts = span.name |> String.split(".") |> Enum.map(&String.to_atom/1)
    stop_event = [:deeper_hub | event_parts] ++ [:stop]
    
    # Combina metadados originais com metadados de resultado
    metadata = Map.merge(span.metadata, sanitize_metadata(result_metadata))
    
    # Emite evento de fim
    :telemetry.execute(
      stop_event,
      %{duration: duration},
      metadata
    )
    
    # Registra métricas
    register_metrics(span.name, duration, metadata)
    
    :ok
  end
  
  @doc """
  Executa uma função dentro de um span de telemetria.
  
  Esta função combina `start_span/2` e `stop_span/2` em uma única chamada,
  simplificando o uso de telemetria para funções síncronas.
  
  ## Parâmetros
  
  - `event_name`: Nome do evento (ex: "auth.user.login")
  - `metadata`: Metadados adicionais para o evento (opcional)
  - `fun`: Função a ser executada dentro do span
  
  ## Retorno
  
  - O resultado da função `fun`
  
  ## Exemplo
  
  ```elixir
  result = Telemetry.span "auth.user.login", %{user_id: user.id} do
    # ... código da operação ...
  end
  ```
  """
  @spec span(event_name(), metadata(), (-> any())) :: any()
  def span(event_name, metadata \\ %{}, fun) when is_function(fun, 0) do
    span_ref = start_span(event_name, metadata)
    
    try do
      result = fun.()
      
      # Extrai metadados do resultado para telemetria
      result_metadata = extract_result_metadata(result)
      stop_span(span_ref, result_metadata)
      
      result
    rescue
      exception ->
        # Captura exceção e registra como evento de exceção
        handle_exception(span_ref, exception, __STACKTRACE__)
        reraise exception, __STACKTRACE__
    catch
      kind, reason ->
        # Captura outros tipos de falhas
        handle_error(span_ref, kind, reason, __STACKTRACE__)
        :erlang.raise(kind, reason, __STACKTRACE__)
    end
  end
  
  @doc """
  Registra uma exceção ocorrida durante um span.
  
  Esta função deve ser chamada quando uma exceção ocorre durante um span,
  para registrar a falha na telemetria.
  
  ## Parâmetros
  
  - `span`: Referência ao span retornada por `start_span/2`
  - `exception`: A exceção que ocorreu
  - `stacktrace`: O stacktrace da exceção
  
  ## Retorno
  
  - `:ok`
  """
  @spec handle_exception(map(), Exception.t(), list()) :: :ok
  def handle_exception(span, exception, stacktrace) do
    stop_time = System.monotonic_time()
    duration = stop_time - span.start_time
    
    # Converte o nome do evento em uma lista de atoms
    event_parts = span.name |> String.split(".") |> Enum.map(&String.to_atom/1)
    exception_event = [:deeper_hub | event_parts] ++ [:exception]
    
    # Prepara metadados da exceção
    exception_metadata = %{
      kind: :error,
      error: Exception.message(exception),
      stacktrace: sanitize_stacktrace(stacktrace),
      exception: inspect(exception)
    }
    
    # Combina metadados originais com metadados da exceção
    metadata = Map.merge(span.metadata, exception_metadata)
    
    # Emite evento de exceção
    :telemetry.execute(
      exception_event,
      %{duration: duration},
      sanitize_metadata(metadata)
    )
    
    # Registra métricas de erro
    register_error_metrics(span.name, duration, metadata)
    
    # Registra log de erro
    Logger.error("Exceção em #{span.name}: #{Exception.message(exception)}", metadata)
    
    :ok
  end
  
  @doc """
  Registra um erro não-exceção ocorrido durante um span.
  
  Esta função deve ser chamada quando um erro (não uma exceção) ocorre durante um span,
  para registrar a falha na telemetria.
  
  ## Parâmetros
  
  - `span`: Referência ao span retornada por `start_span/2`
  - `kind`: O tipo de erro (:throw, :exit)
  - `reason`: A razão do erro
  - `stacktrace`: O stacktrace do erro
  
  ## Retorno
  
  - `:ok`
  """
  @spec handle_error(map(), atom(), any(), list()) :: :ok
  def handle_error(span, kind, reason, stacktrace) do
    stop_time = System.monotonic_time()
    duration = stop_time - span.start_time
    
    # Converte o nome do evento em uma lista de atoms
    event_parts = span.name |> String.split(".") |> Enum.map(&String.to_atom/1)
    exception_event = [:deeper_hub | event_parts] ++ [:exception]
    
    # Prepara metadados do erro
    error_metadata = %{
      kind: kind,
      error: inspect(reason),
      stacktrace: sanitize_stacktrace(stacktrace)
    }
    
    # Combina metadados originais com metadados do erro
    metadata = Map.merge(span.metadata, error_metadata)
    
    # Emite evento de exceção
    :telemetry.execute(
      exception_event,
      %{duration: duration},
      sanitize_metadata(metadata)
    )
    
    # Registra métricas de erro
    register_error_metrics(span.name, duration, metadata)
    
    # Registra log de erro
    Logger.error("Erro em #{span.name}: #{inspect(reason)}", metadata)
    
    :ok
  end
  
  @doc """
  Handler padrão para eventos de telemetria.
  
  Esta função é chamada automaticamente para cada evento de telemetria
  registrado com `setup/2`. Ela registra logs e métricas apropriados
  para cada tipo de evento.
  
  ## Parâmetros
  
  - `event`: Nome do evento
  - `measurements`: Medições associadas ao evento
  - `metadata`: Metadados do evento
  - `config`: Configuração do handler (não utilizada)
  """
  @spec handle_event(list(), map(), map(), any()) :: :ok
  def handle_event(event, measurements, metadata, _config) do
    # Extrai o tipo de evento (start, stop, exception)
    event_type = List.last(event)
    
    # Extrai o nome do evento sem o prefixo e o tipo
    event_name = event
                 |> Enum.slice(1..-2//-1)
                 |> Enum.map(&Atom.to_string/1)
                 |> Enum.join(".")
    
    case event_type do
      :start ->
        # Evento de início
        Logger.debug("Iniciando #{event_name}", metadata)
        
      :stop ->
        # Evento de fim
        duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)
        
        # Determina o nível de log com base na duração
        log_level = cond do
          duration_ms > 1000 -> :warning  # Operações que levam mais de 1 segundo
          duration_ms > 500 -> :info      # Operações que levam mais de 500ms
          true -> :debug                  # Operações normais
        end
        
        # Registra log com nível apropriado
        apply(Logger, log_level, [
          "Concluído #{event_name} em #{duration_ms}ms",
          Map.put(metadata, :duration_ms, duration_ms)
        ])
        
      :exception ->
        # Evento de exceção
        duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)
        
        Logger.error(
          "Falha em #{event_name} após #{duration_ms}ms: #{Map.get(metadata, :error, "Erro desconhecido")}",
          Map.put(metadata, :duration_ms, duration_ms)
        )
        
      _ ->
        # Outros tipos de eventos
        Logger.debug("Evento #{Enum.join(event, ".")} recebido", metadata)
    end
    
    :ok
  end
  
  # Funções privadas
  
  # Extrai metadados relevantes do resultado de uma operação
  @spec extract_result_metadata(any()) :: map()
  defp extract_result_metadata(result) do
    case result do
      {:ok, value} ->
        %{result: :success, value: sanitize_value(value)}
        
      {:error, reason} ->
        %{result: :error, reason: sanitize_value(reason)}
        
      {:error, reason, details} ->
        %{result: :error, reason: sanitize_value(reason), details: sanitize_value(details)}
        
      _ ->
        %{result: :unknown}
    end
  end
  
  # Sanitiza valores para evitar problemas com dados sensíveis ou muito grandes
  @spec sanitize_value(any()) :: any()
  defp sanitize_value(value) do
    cond do
      is_binary(value) && byte_size(value) > 1000 ->
        binary_part(value, 0, 1000) <> "... (truncado)"
        
      is_list(value) && length(value) > 50 ->
        Enum.take(value, 50) ++ ["... (truncado)"]
        
      is_map(value) && map_size(value) > 50 ->
        value
        |> Enum.take(50)
        |> Map.new()
        |> Map.put(:truncated, true)
        
      is_struct(value) ->
        # Para structs, retorna apenas o nome do módulo para evitar dados sensíveis
        %{__struct__: module} = value
        "#{inspect(module)}"
        
      true ->
        value
    end
  end
  
  # Sanitiza metadados para evitar problemas com dados sensíveis
  @spec sanitize_metadata(map()) :: map()
  defp sanitize_metadata(metadata) do
    metadata
    |> Enum.map(fn {key, value} -> {key, sanitize_value(value)} end)
    |> Map.new()
    |> sanitize_sensitive_fields()
  end
  
  # Remove ou mascara campos sensíveis nos metadados
  @spec sanitize_sensitive_fields(map()) :: map()
  defp sanitize_sensitive_fields(metadata) do
    sensitive_fields = [:password, :token, :secret, :api_key, :private_key, :credit_card]
    
    Enum.reduce(sensitive_fields, metadata, fn field, acc ->
      case Map.get(acc, field) do
        nil -> acc
        _value -> Map.put(acc, field, "[REDACTED]")
      end
    end)
  end
  
  # Sanitiza stacktrace para evitar excesso de informações
  @spec sanitize_stacktrace(list()) :: list()
  defp sanitize_stacktrace(stacktrace) do
    Enum.take(stacktrace, 10)
  end
  
  # Obtém informações básicas sobre o processo atual
  @spec get_process_info() :: map()
  defp get_process_info do
    %{
      pid: inspect(self()),
      registered_name: Process.info(self(), :registered_name),
      initial_call: Process.info(self(), :initial_call)
    }
  end
  
  # Registra métricas para um span concluído
  @spec register_metrics(String.t(), integer(), map()) :: :ok
  defp register_metrics(event_name, duration, metadata) do
    # Converte duração para milissegundos
    duration_ms = System.convert_time_unit(duration, :native, :millisecond)
    
    # Registra tempo de execução
    Metrics.record_execution_time(:telemetry, "#{event_name}.duration", duration_ms)
    
    # Incrementa contador de operações
    Metrics.increment_counter(:telemetry, "#{event_name}.count")
    
    # Registra resultado
    case Map.get(metadata, :result) do
      :success ->
        Metrics.increment_counter(:telemetry, "#{event_name}.success")
        
      :error ->
        Metrics.increment_counter(:telemetry, "#{event_name}.error")
        
      _ ->
        # Resultado desconhecido, não incrementa contadores específicos
        :ok
    end
    
    :ok
  end
  
  # Registra métricas para um span que falhou com erro
  @spec register_error_metrics(String.t(), integer(), map()) :: :ok
  defp register_error_metrics(event_name, duration, metadata) do
    # Converte duração para milissegundos
    duration_ms = System.convert_time_unit(duration, :native, :millisecond)
    
    # Registra tempo de execução até o erro
    Metrics.record_execution_time(:telemetry, "#{event_name}.error.duration", duration_ms)
    
    # Incrementa contador de erros
    Metrics.increment_counter(:telemetry, "#{event_name}.error")
    
    # Registra tipo de erro
    error_type = case Map.get(metadata, :kind) do
      :error -> "exception"
      kind -> Atom.to_string(kind)
    end
    
    Metrics.increment_counter(:telemetry, "#{event_name}.error.#{error_type}")
    
    :ok
  end
end
