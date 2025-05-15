defmodule Deeper_Hub.Core.Data.RepositoryTelemetry do
  @moduledoc """
  Módulo de telemetria para operações de repositório.
  
  Este módulo centraliza todos os eventos de telemetria relacionados às operações
  de banco de dados, facilitando o monitoramento e a observabilidade do sistema.
  
  ## Eventos Padrão
  
  Os eventos seguem o formato `[:deeper_hub, :core, :data, :repository, :operation]`.
  
  ### Operações CRUD
  
  - `[:deeper_hub, :core, :data, :repository, :get]` - Busca de registro por ID
  - `[:deeper_hub, :core, :data, :repository, :insert]` - Inserção de registro
  - `[:deeper_hub, :core, :data, :repository, :update]` - Atualização de registro
  - `[:deeper_hub, :core, :data, :repository, :delete]` - Exclusão de registro
  - `[:deeper_hub, :core, :data, :repository, :list]` - Listagem de registros
  - `[:deeper_hub, :core, :data, :repository, :find]` - Busca de registros por condições
  
  ### Operações de Junção
  
  - `[:deeper_hub, :core, :data, :repository, :join_inner]` - Junção interna
  - `[:deeper_hub, :core, :data, :repository, :join_left]` - Junção à esquerda
  - `[:deeper_hub, :core, :data, :repository, :join_right]` - Junção à direita
  
  ### Operações de Transação
  
  - `[:deeper_hub, :core, :data, :repository, :transaction]` - Transação
  
  ## Medições
  
  Para cada evento, as seguintes medições são registradas:
  
  - `duration` - Duração da operação em milissegundos
  - `result` - Resultado da operação (`:success`, `:not_found`, `:error`)
  
  ## Metadados
  
  Os metadados incluem informações como:
  
  - `schema` - O schema Ecto envolvido na operação
  - `id` - O ID do registro (quando aplicável)
  - `conditions` - As condições de busca (quando aplicável)
  - `opts` - Opções adicionais (quando aplicável)
  - `error` - Detalhes do erro (quando aplicável)
  """
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Metrics.MetricsFacade, as: Metrics
  
  @doc """
  Configura os handlers de telemetria para operações de repositório.
  
  Este função deve ser chamada durante a inicialização da aplicação para
  garantir que todos os eventos de telemetria sejam capturados.
  """
  def setup do
    # Lista de eventos a serem monitorados
    events = [
      [:deeper_hub, :core, :data, :repository, :get],
      [:deeper_hub, :core, :data, :repository, :insert],
      [:deeper_hub, :core, :data, :repository, :update],
      [:deeper_hub, :core, :data, :repository, :delete],
      [:deeper_hub, :core, :data, :repository, :list],
      [:deeper_hub, :core, :data, :repository, :find],
      [:deeper_hub, :core, :data, :repository, :join_inner],
      [:deeper_hub, :core, :data, :repository, :join_left],
      [:deeper_hub, :core, :data, :repository, :join_right],
      [:deeper_hub, :core, :data, :repository, :transaction]
    ]
    
    # Remove handlers existentes para evitar duplicação
    :telemetry.detach({__MODULE__, :repository_handler})
    
    # Configura o handler para os eventos
    :telemetry.attach_many(
      {__MODULE__, :repository_handler},
      events,
      &__MODULE__.handle_event/4,
      nil
    )
  end
  
  @doc """
  Handler para eventos de telemetria de repositório.
  
  Este handler é chamado automaticamente pelo sistema de telemetria quando
  um evento ocorre. Ele registra logs e métricas para o evento.
  
  ## Parâmetros
  
  - `event` - O evento de telemetria
  - `measurements` - Medições do evento
  - `metadata` - Metadados do evento
  - `config` - Configuração do handler
  """
  def handle_event(event, measurements, metadata, _config) do
    # Extrai informações do evento
    [_, _, _, _, operation] = event
    
    # Registra métricas
    register_metrics(operation, measurements, metadata)
    
    # Registra logs
    log_event(operation, measurements, metadata)
  end
  
  @doc """
  Registra métricas para um evento de telemetria.
  
  ## Parâmetros
  
  - `operation` - A operação realizada
  - `measurements` - Medições do evento
  - `metadata` - Metadados do evento
  """
  def register_metrics(operation, measurements, metadata) do
    # Extrai o schema e o resultado
    schema = get_schema_name(metadata)
    result = get_result_status(metadata)
    
    # Registra a duração da operação
    if Map.has_key?(measurements, :duration) do
      duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)
      
      Metrics.observe("deeper_hub.core.data.repository.#{operation}.duration_ms", duration_ms, %{
        schema: schema,
        result: result
      })
    end
    
    # Registra o contador de operações
    Metrics.increment("deeper_hub.core.data.repository.#{operation}.count", %{
      schema: schema,
      result: result
    })
  end
  
  @doc """
  Registra logs para um evento de telemetria.
  
  ## Parâmetros
  
  - `operation` - A operação realizada
  - `measurements` - Medições do evento
  - `metadata` - Metadados do evento
  """
  def log_event(operation, measurements, metadata) do
    # Extrai o schema e o resultado
    schema = get_schema_name(metadata)
    result = get_result_status(metadata)
    
    # Calcula a duração em milissegundos
    duration_ms = if Map.has_key?(measurements, :duration) do
      System.convert_time_unit(measurements.duration, :native, :millisecond)
    else
      0
    end
    
    # Determina o nível de log com base no resultado
    {level, message} = case result do
      :success ->
        {:debug, "Operação #{operation} concluída com sucesso"}
        
      :not_found ->
        {:debug, "Operação #{operation} não encontrou resultados"}
        
      :error ->
        {:error, "Operação #{operation} falhou"}
    end
    
    # Prepara os metadados para o log
    log_metadata = %{
      module: __MODULE__,
      operation: operation,
      schema: schema,
      duration_ms: duration_ms
    }
    
    # Adiciona o ID se presente
    log_metadata = if Map.has_key?(metadata, :id) do
      Map.put(log_metadata, :id, metadata.id)
    else
      log_metadata
    end
    
    # Adiciona o erro se presente
    log_metadata = if Map.has_key?(metadata, :error) do
      Map.put(log_metadata, :error, metadata.error)
    else
      log_metadata
    end
    
    # Registra o log
    case level do
      :debug -> Logger.debug(message, log_metadata)
      :info -> Logger.info(message, log_metadata)
      :warning -> Logger.warning(message, log_metadata)
      :error -> Logger.error(message, log_metadata)
    end
  end
  
  @doc """
  Executa uma função dentro de um span de telemetria.
  
  Esta função é uma abstração sobre `:telemetry.span/3` que adiciona
  tratamento de erros e sanitização de dados.
  
  ## Parâmetros
  
  - `event` - O evento de telemetria
  - `metadata` - Metadados do evento
  - `fun` - A função a ser executada
  
  ## Retorno
  
  Retorna o resultado da função.
  """
  def span(event, metadata, fun) do
    sanitized_metadata = sanitize_metadata(metadata)
    
    :telemetry.span(event, sanitized_metadata, fn ->
      try do
        result = fun.()
        {result, Map.put(sanitized_metadata, :result, get_result_type(result))}
      catch
        kind, reason ->
          # Captura exceções não tratadas
          stacktrace = __STACKTRACE__
          
          Logger.error("Exceção não tratada em operação de repositório", %{
            module: __MODULE__,
            event: event,
            kind: kind,
            reason: reason,
            stacktrace: stacktrace
          })
          
          # Re-lança a exceção após o log
          :erlang.raise(kind, reason, stacktrace)
      end
    end)
  end
  
  # Funções privadas auxiliares
  
  # Extrai o nome do schema dos metadados
  defp get_schema_name(metadata) do
    case metadata do
      %{schema: schema} when is_atom(schema) -> inspect(schema)
      %{schema: schema} -> inspect(schema)
      _ -> "unknown"
    end
  end
  
  # Determina o status do resultado com base nos metadados
  defp get_result_status(metadata) do
    case metadata do
      %{result: :success} -> :success
      %{result: :not_found} -> :not_found
      %{result: %{success: true}} -> :success
      %{result: %{success: false}} -> :error
      _ -> :unknown
    end
  end
  
  # Determina o tipo de resultado com base no valor retornado
  defp get_result_type(result) do
    case result do
      {:ok, _} -> :success
      {:error, :not_found} -> :not_found
      {:error, _} -> :error
      _ -> :unknown
    end
  end
  
  # Sanitiza os metadados para remover dados sensíveis
  defp sanitize_metadata(metadata) do
    metadata
    |> Map.drop([:password, :secret, :token, :api_key])
    |> Map.new(fn
      # Limita o tamanho de listas grandes
      {k, v} when is_list(v) and length(v) > 10 ->
        {k, Enum.take(v, 10) ++ ["... (#{length(v) - 10} more items)"]}
        
      # Limita o tamanho de strings grandes
      {k, v} when is_binary(v) and byte_size(v) > 1000 ->
        {k, binary_part(v, 0, 1000) <> "... (#{byte_size(v) - 1000} more bytes)"}
        
      # Mantém outros valores inalterados
      pair -> pair
    end)
  end
end
