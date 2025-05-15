defmodule Deeper_Hub.Core.Data.RepositoryEventIntegration do
  @moduledoc """
  Módulo de integração com o EventBus para operações de repositório.
  
  Este módulo centraliza a publicação de eventos relacionados às operações
  de banco de dados, garantindo consistência e padronização.
  
  ## Eventos Publicados
  
  - `:repository_record_inserted` - Quando um registro é inserido com sucesso
  - `:repository_record_updated` - Quando um registro é atualizado com sucesso
  - `:repository_record_deleted` - Quando um registro é excluído com sucesso
  - `:repository_query_executed` - Quando uma consulta é executada com sucesso
  - `:repository_transaction_completed` - Quando uma transação é concluída com sucesso
  - `:repository_error` - Quando ocorre um erro em qualquer operação de repositório
  
  ## Metadados dos Eventos
  
  Os metadados incluem informações como:
  
  - `schema` - O schema Ecto envolvido na operação
  - `id` - O ID do registro (quando aplicável)
  - `timestamp` - O timestamp da operação
  - `operation` - A operação realizada
  - `error` - Detalhes do erro (quando aplicável)
  """
  
  alias Deeper_Hub.Core.EventBus.EventBusFacade, as: EventBus
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Metrics.MetricsFacade, as: Metrics
  
  @doc """
  Publica um evento de inserção de registro.
  
  ## Parâmetros
  
  - `schema` - O schema Ecto do registro
  - `id` - O ID do registro inserido
  - `record` - O registro inserido (opcional)
  
  ## Retorno
  
  - `:ok` - Se o evento for publicado com sucesso
  - `{:error, reason}` - Se ocorrer um erro ao publicar o evento
  """
  def publish_record_inserted(schema, id, record \\ nil) do
    # Registra métrica de início da operação
    start_time = System.monotonic_time()
    Metrics.increment("deeper_hub.core.data.repository.event.record_inserted.started", %{
      schema: inspect(schema)
    })
    
    # Prepara os metadados do evento
    event_data = %{
      schema: schema,
      id: id,
      timestamp: DateTime.utc_now(),
      operation: :insert
    }
    
    # Adiciona o registro se fornecido
    event_data = if record do
      Map.put(event_data, :record, record)
    else
      event_data
    end
    
    # Publica o evento
    result = EventBus.publish(:repository_record_inserted, event_data)
    
    # Registra métrica de conclusão da operação
    duration = System.monotonic_time() - start_time
    duration_ms = System.convert_time_unit(duration, :native, :millisecond)
    
    case result do
      :ok ->
        # Registra métrica de sucesso
        Metrics.increment("deeper_hub.core.data.repository.event.record_inserted.success", %{
          schema: inspect(schema)
        })
        
        # Registra métrica de duração
        Metrics.observe("deeper_hub.core.data.repository.event.record_inserted.duration_ms", duration_ms, %{
          schema: inspect(schema)
        })
        
        Logger.debug("Evento de inserção de registro publicado com sucesso", %{
          module: __MODULE__,
          schema: schema,
          id: id,
          duration_ms: duration_ms
        })
        
        :ok
        
      {:error, reason} ->
        # Registra métrica de falha
        Metrics.increment("deeper_hub.core.data.repository.event.record_inserted.failed", %{
          schema: inspect(schema),
          reason: inspect(reason)
        })
        
        Logger.error("Falha ao publicar evento de inserção de registro", %{
          module: __MODULE__,
          schema: schema,
          id: id,
          reason: reason,
          duration_ms: duration_ms
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Publica um evento de atualização de registro.
  
  ## Parâmetros
  
  - `schema` - O schema Ecto do registro
  - `id` - O ID do registro atualizado
  - `record` - O registro atualizado (opcional)
  - `changes` - As alterações realizadas (opcional)
  
  ## Retorno
  
  - `:ok` - Se o evento for publicado com sucesso
  - `{:error, reason}` - Se ocorrer um erro ao publicar o evento
  """
  def publish_record_updated(schema, id, record \\ nil, changes \\ nil) do
    # Registra métrica de início da operação
    start_time = System.monotonic_time()
    Metrics.increment("deeper_hub.core.data.repository.event.record_updated.started", %{
      schema: inspect(schema)
    })
    
    # Prepara os metadados do evento
    event_data = %{
      schema: schema,
      id: id,
      timestamp: DateTime.utc_now(),
      operation: :update
    }
    
    # Adiciona o registro se fornecido
    event_data = if record do
      Map.put(event_data, :record, record)
    else
      event_data
    end
    
    # Adiciona as alterações se fornecidas
    event_data = if changes do
      Map.put(event_data, :changes, changes)
    else
      event_data
    end
    
    # Publica o evento
    result = EventBus.publish(:repository_record_updated, event_data)
    
    # Registra métrica de conclusão da operação
    duration = System.monotonic_time() - start_time
    duration_ms = System.convert_time_unit(duration, :native, :millisecond)
    
    case result do
      :ok ->
        # Registra métrica de sucesso
        Metrics.increment("deeper_hub.core.data.repository.event.record_updated.success", %{
          schema: inspect(schema)
        })
        
        # Registra métrica de duração
        Metrics.observe("deeper_hub.core.data.repository.event.record_updated.duration_ms", duration_ms, %{
          schema: inspect(schema)
        })
        
        Logger.debug("Evento de atualização de registro publicado com sucesso", %{
          module: __MODULE__,
          schema: schema,
          id: id,
          duration_ms: duration_ms
        })
        
        :ok
        
      {:error, reason} ->
        # Registra métrica de falha
        Metrics.increment("deeper_hub.core.data.repository.event.record_updated.failed", %{
          schema: inspect(schema),
          reason: inspect(reason)
        })
        
        Logger.error("Falha ao publicar evento de atualização de registro", %{
          module: __MODULE__,
          schema: schema,
          id: id,
          reason: reason,
          duration_ms: duration_ms
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Publica um evento de exclusão de registro.
  
  ## Parâmetros
  
  - `schema` - O schema Ecto do registro
  - `id` - O ID do registro excluído
  
  ## Retorno
  
  - `:ok` - Se o evento for publicado com sucesso
  - `{:error, reason}` - Se ocorrer um erro ao publicar o evento
  """
  def publish_record_deleted(schema, id) do
    # Registra métrica de início da operação
    start_time = System.monotonic_time()
    Metrics.increment("deeper_hub.core.data.repository.event.record_deleted.started", %{
      schema: inspect(schema)
    })
    
    # Prepara os metadados do evento
    event_data = %{
      schema: schema,
      id: id,
      timestamp: DateTime.utc_now(),
      operation: :delete
    }
    
    # Publica o evento
    result = EventBus.publish(:repository_record_deleted, event_data)
    
    # Registra métrica de conclusão da operação
    duration = System.monotonic_time() - start_time
    duration_ms = System.convert_time_unit(duration, :native, :millisecond)
    
    case result do
      :ok ->
        # Registra métrica de sucesso
        Metrics.increment("deeper_hub.core.data.repository.event.record_deleted.success", %{
          schema: inspect(schema)
        })
        
        # Registra métrica de duração
        Metrics.observe("deeper_hub.core.data.repository.event.record_deleted.duration_ms", duration_ms, %{
          schema: inspect(schema)
        })
        
        Logger.debug("Evento de exclusão de registro publicado com sucesso", %{
          module: __MODULE__,
          schema: schema,
          id: id,
          duration_ms: duration_ms
        })
        
        :ok
        
      {:error, reason} ->
        # Registra métrica de falha
        Metrics.increment("deeper_hub.core.data.repository.event.record_deleted.failed", %{
          schema: inspect(schema),
          reason: inspect(reason)
        })
        
        Logger.error("Falha ao publicar evento de exclusão de registro", %{
          module: __MODULE__,
          schema: schema,
          id: id,
          reason: reason,
          duration_ms: duration_ms
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Publica um evento de execução de consulta.
  
  ## Parâmetros
  
  - `schema` - O schema Ecto da consulta
  - `operation` - A operação realizada (:list, :find, etc.)
  - `params` - Os parâmetros da consulta (opcional)
  - `result_count` - O número de registros retornados (opcional)
  
  ## Retorno
  
  - `:ok` - Se o evento for publicado com sucesso
  - `{:error, reason}` - Se ocorrer um erro ao publicar o evento
  """
  def publish_query_executed(schema, operation, params \\ nil, result_count \\ nil) do
    # Registra métrica de início da operação
    start_time = System.monotonic_time()
    Metrics.increment("deeper_hub.core.data.repository.event.query_executed.started", %{
      schema: inspect(schema),
      operation: operation
    })
    
    # Prepara os metadados do evento
    event_data = %{
      schema: schema,
      operation: operation,
      timestamp: DateTime.utc_now()
    }
    
    # Adiciona os parâmetros se fornecidos
    event_data = if params do
      Map.put(event_data, :params, params)
    else
      event_data
    end
    
    # Adiciona o número de registros se fornecido
    event_data = if result_count do
      Map.put(event_data, :result_count, result_count)
    else
      event_data
    end
    
    # Publica o evento
    result = EventBus.publish(:repository_query_executed, event_data)
    
    # Registra métrica de conclusão da operação
    duration = System.monotonic_time() - start_time
    duration_ms = System.convert_time_unit(duration, :native, :millisecond)
    
    case result do
      :ok ->
        # Registra métrica de sucesso
        Metrics.increment("deeper_hub.core.data.repository.event.query_executed.success", %{
          schema: inspect(schema),
          operation: operation
        })
        
        # Registra métrica de duração
        Metrics.observe("deeper_hub.core.data.repository.event.query_executed.duration_ms", duration_ms, %{
          schema: inspect(schema),
          operation: operation
        })
        
        Logger.debug("Evento de execução de consulta publicado com sucesso", %{
          module: __MODULE__,
          schema: schema,
          operation: operation,
          duration_ms: duration_ms
        })
        
        :ok
        
      {:error, reason} ->
        # Registra métrica de falha
        Metrics.increment("deeper_hub.core.data.repository.event.query_executed.failed", %{
          schema: inspect(schema),
          operation: operation,
          reason: inspect(reason)
        })
        
        Logger.error("Falha ao publicar evento de execução de consulta", %{
          module: __MODULE__,
          schema: schema,
          operation: operation,
          reason: reason,
          duration_ms: duration_ms
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Publica um evento de conclusão de transação.
  
  ## Parâmetros
  
  - `transaction_id` - O ID da transação
  - `schemas` - Os schemas Ecto envolvidos na transação
  - `operations` - As operações realizadas na transação
  
  ## Retorno
  
  - `:ok` - Se o evento for publicado com sucesso
  - `{:error, reason}` - Se ocorrer um erro ao publicar o evento
  """
  def publish_transaction_completed(transaction_id, schemas, operations) do
    # Registra métrica de início da operação
    start_time = System.monotonic_time()
    Metrics.increment("deeper_hub.core.data.repository.event.transaction_completed.started", %{
      transaction_id: transaction_id
    })
    
    # Prepara os metadados do evento
    event_data = %{
      transaction_id: transaction_id,
      schemas: schemas,
      operations: operations,
      timestamp: DateTime.utc_now()
    }
    
    # Publica o evento
    result = EventBus.publish(:repository_transaction_completed, event_data)
    
    # Registra métrica de conclusão da operação
    duration = System.monotonic_time() - start_time
    duration_ms = System.convert_time_unit(duration, :native, :millisecond)
    
    case result do
      :ok ->
        # Registra métrica de sucesso
        Metrics.increment("deeper_hub.core.data.repository.event.transaction_completed.success", %{
          transaction_id: transaction_id
        })
        
        # Registra métrica de duração
        Metrics.observe("deeper_hub.core.data.repository.event.transaction_completed.duration_ms", duration_ms, %{
          transaction_id: transaction_id
        })
        
        Logger.debug("Evento de conclusão de transação publicado com sucesso", %{
          module: __MODULE__,
          transaction_id: transaction_id,
          duration_ms: duration_ms
        })
        
        :ok
        
      {:error, reason} ->
        # Registra métrica de falha
        Metrics.increment("deeper_hub.core.data.repository.event.transaction_completed.failed", %{
          transaction_id: transaction_id,
          reason: inspect(reason)
        })
        
        Logger.error("Falha ao publicar evento de conclusão de transação", %{
          module: __MODULE__,
          transaction_id: transaction_id,
          reason: reason,
          duration_ms: duration_ms
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Publica um evento de erro em operação de repositório.
  
  ## Parâmetros
  
  - `schema` - O schema Ecto envolvido na operação
  - `operation` - A operação que falhou
  - `error` - O erro ocorrido
  - `details` - Detalhes adicionais sobre o erro (opcional)
  
  ## Retorno
  
  - `:ok` - Se o evento for publicado com sucesso
  - `{:error, reason}` - Se ocorrer um erro ao publicar o evento
  """
  def publish_repository_error(schema, operation, error, details \\ nil) do
    # Registra métrica de início da operação
    start_time = System.monotonic_time()
    Metrics.increment("deeper_hub.core.data.repository.event.error.started", %{
      schema: inspect(schema),
      operation: operation
    })
    
    # Prepara os metadados do evento
    event_data = %{
      schema: schema,
      operation: operation,
      error: error,
      timestamp: DateTime.utc_now()
    }
    
    # Adiciona os detalhes se fornecidos
    event_data = if details do
      Map.put(event_data, :details, details)
    else
      event_data
    end
    
    # Publica o evento
    result = EventBus.publish(:repository_error, event_data)
    
    # Registra métrica de conclusão da operação
    duration = System.monotonic_time() - start_time
    duration_ms = System.convert_time_unit(duration, :native, :millisecond)
    
    case result do
      :ok ->
        # Registra métrica de sucesso
        Metrics.increment("deeper_hub.core.data.repository.event.error.success", %{
          schema: inspect(schema),
          operation: operation
        })
        
        # Registra métrica de duração
        Metrics.observe("deeper_hub.core.data.repository.event.error.duration_ms", duration_ms, %{
          schema: inspect(schema),
          operation: operation
        })
        
        Logger.debug("Evento de erro em operação de repositório publicado com sucesso", %{
          module: __MODULE__,
          schema: schema,
          operation: operation,
          duration_ms: duration_ms
        })
        
        :ok
        
      {:error, reason} ->
        # Registra métrica de falha
        Metrics.increment("deeper_hub.core.data.repository.event.error.failed", %{
          schema: inspect(schema),
          operation: operation,
          reason: inspect(reason)
        })
        
        Logger.error("Falha ao publicar evento de erro em operação de repositório", %{
          module: __MODULE__,
          schema: schema,
          operation: operation,
          reason: reason,
          duration_ms: duration_ms
        })
        
        {:error, reason}
    end
  end
end
