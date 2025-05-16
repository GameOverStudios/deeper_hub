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
  
  alias Deeper_Hub.Core.Metrics.MetricsFacade, as: Metrics
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Data.RepositoryConfig
  alias Deeper_Hub.Core.EventBus.EventBusFacade, as: EventBus
  
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
  def publish_insert_event(schema, id, record, result, duration) do
    # Verifica se a publicação de eventos de inserção está habilitada
    if RepositoryConfig.publish_insert_events?() do
      # Registra a duração da operação como uma métrica
      Metrics.histogram(
        "deeper_hub.core.data.repository.event.insert.duration",
        %{schema: inspect(schema)},
        duration
      )
      
      # Cria o payload do evento
      payload = %{
        id: id,
        schema: schema,
        record: record,
        result: result,
        timestamp: DateTime.utc_now(),
        duration_ms: duration
      }
      
      # Publica o evento no barramento
      EventBus.publish(
        :repository_insert,
        payload,
        %{source: "Deeper_Hub.Core.Data.RepositoryEventIntegration"}
      )
      
      # Registra o evento no log
      Logger.debug("Evento de inserção publicado", %{
        module: __MODULE__,
        schema: inspect(schema),
        id: id,
        duration_ms: duration
      })
    else
      Logger.debug("Publicação de eventos de inserção desabilitada", %{
        module: __MODULE__,
        schema: inspect(schema),
        id: id
      })
    end
    
    :ok
  end
  
  @doc """
  Publica um evento de atualização de registro.
  
  ## Parâmetros
  
  - `schema` - O schema Ecto do registro
  - `id` - O ID do registro atualizado
  - `changes` - As alterações realizadas (opcional)
  
  ## Retorno
  
  - `:ok` - Se o evento for publicado com sucesso
  - `{:error, reason}` - Se ocorrer um erro ao publicar o evento
  """
  def publish_update_event(schema, id, changes, result, duration) do
    # Verifica se a publicação de eventos de atualização está habilitada
    if RepositoryConfig.publish_update_events?() do
      # Registra a duração da operação como uma métrica
      Metrics.histogram(
        "deeper_hub.core.data.repository.event.update.duration",
        %{schema: inspect(schema)},
        duration
      )
      
      # Cria o payload do evento
      payload = %{
        id: id,
        schema: schema,
        changes: changes,
        result: result,
        timestamp: DateTime.utc_now(),
        duration_ms: duration
      }
      
      # Publica o evento no barramento
      EventBus.publish(
        :repository_update,
        payload,
        %{source: "Deeper_Hub.Core.Data.RepositoryEventIntegration"}
      )
      
      # Registra o evento no log
      Logger.debug("Evento de atualização publicado", %{
        module: __MODULE__,
        schema: inspect(schema),
        id: id,
        duration_ms: duration
      })
    else
      Logger.debug("Publicação de eventos de atualização desabilitada", %{
        module: __MODULE__,
        schema: inspect(schema),
        id: id
      })
    end
    
    :ok
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
  def publish_delete_event(schema, id, result, duration) do
    # Verifica se a publicação de eventos de exclusão está habilitada
    if RepositoryConfig.publish_delete_events?() do
      # Registra a duração da operação como uma métrica
      Metrics.histogram(
        "deeper_hub.core.data.repository.event.delete.duration",
        %{schema: inspect(schema)},
        duration
      )
      
      # Cria o payload do evento
      payload = %{
        id: id,
        schema: schema,
        result: result,
        timestamp: DateTime.utc_now(),
        duration_ms: duration
      }
      
      # Publica o evento no barramento
      EventBus.publish(
        :repository_delete,
        payload,
        %{source: "Deeper_Hub.Core.Data.RepositoryEventIntegration"}
      )
      
      # Registra o evento no log
      Logger.debug("Evento de exclusão publicado", %{
        module: __MODULE__,
        schema: inspect(schema),
        id: id,
        duration_ms: duration
      })
    else
      Logger.debug("Publicação de eventos de exclusão desabilitada", %{
        module: __MODULE__,
        schema: inspect(schema),
        id: id
      })
    end
    
    :ok
  end
  
  @doc """
  Publica um evento de consulta de registros.
  
  ## Parâmetros
  
  - `schema` - O schema Ecto da consulta
  - `query` - A consulta realizada
  
  ## Retorno
  
  - `:ok` - Se o evento for publicado com sucesso
  - `{:error, reason}` - Se ocorrer um erro ao publicar o evento
  """
  def publish_list_event(schema, query, result, duration) do
    # Verifica se a publicação de eventos de consulta está habilitada
    if RepositoryConfig.publish_query_events?() do
      # Registra a duração da operação como uma métrica
      Metrics.histogram(
        "deeper_hub.core.data.repository.event.list.duration",
        %{schema: inspect(schema)},
        duration
      )
      
      # Cria o payload do evento
      payload = %{
        schema: schema,
        query: inspect(query),
        result: result,
        count: case result do
          {:ok, records} when is_list(records) -> length(records)
          _ -> 0
        end,
        timestamp: DateTime.utc_now(),
        duration_ms: duration
      }
      
      # Publica o evento no barramento
      EventBus.publish(
        :repository_list,
        payload,
        %{source: "Deeper_Hub.Core.Data.RepositoryEventIntegration"}
      )
      
      # Registra o evento no log
      Logger.debug("Evento de listagem publicado", %{
        module: __MODULE__,
        schema: inspect(schema),
        count: payload.count,
        duration_ms: duration
      })
    else
      Logger.debug("Publicação de eventos de consulta desabilitada", %{
        module: __MODULE__,
        schema: inspect(schema)
      })
    end
    
    :ok
  end
  
  @doc """
  Publica um evento de consulta de registro específico.
  
  ## Parâmetros
  
  - `schema` - O schema Ecto do registro
  - `id` - O ID do registro consultado
  - `result` - O resultado da operação
  - `duration` - A duração da operação em milissegundos
  
  ## Retorno
  
  - `:ok` - Se o evento for publicado com sucesso
  - `{:error, reason}` - Se ocorrer um erro ao publicar o evento
  """
  def publish_get_event(schema, id, result, duration) do
    # Verifica se a publicação de eventos de consulta está habilitada
    if RepositoryConfig.publish_query_events?() do
      # Registra a duração da operação como uma métrica
      Metrics.histogram(
        "deeper_hub.core.data.repository.event.get.duration",
        %{schema: inspect(schema)},
        duration
      )
      
      # Cria o payload do evento
      payload = %{
        id: id,
        schema: schema,
        result: result,
        timestamp: DateTime.utc_now(),
        duration_ms: duration
      }
      
      # Publica o evento no barramento
      EventBus.publish(
        :repository_get,
        payload,
        %{source: "Deeper_Hub.Core.Data.RepositoryEventIntegration"}
      )
      
      # Registra o evento no log
      Logger.debug("Evento de consulta publicado", %{
        module: __MODULE__,
        schema: inspect(schema),
        id: id,
        duration_ms: duration
      })
    else
      Logger.debug("Publicação de eventos de consulta desabilitada", %{
        module: __MODULE__,
        schema: inspect(schema),
        id: id
      })
    end
    
    :ok
  end
  
  @doc """
  Publica um evento de busca de registros.
  
  ## Parâmetros
  
  - `schema` - O schema Ecto dos registros
  - `query` - A consulta realizada
  - `result` - O resultado da operação
  - `duration` - A duração da operação em milissegundos
  
  ## Retorno
  
  - `:ok` - Se o evento for publicado com sucesso
  - `{:error, reason}` - Se ocorrer um erro ao publicar o evento
  """
  def publish_find_event(schema, query, result, duration) do
    # Verifica se a publicação de eventos de consulta está habilitada
    if RepositoryConfig.publish_query_events?() do
      # Registra a duração da operação como uma métrica
      Metrics.histogram(
        "deeper_hub.core.data.repository.event.find.duration",
        %{schema: inspect(schema)},
        duration
      )
      
      # Cria o payload do evento
      payload = %{
        schema: schema,
        query: inspect(query),
        result: result,
        count: case result do
          {:ok, records} when is_list(records) -> length(records)
          _ -> 0
        end,
        timestamp: DateTime.utc_now(),
        duration_ms: duration
      }
      
      # Publica o evento no barramento
      EventBus.publish(
        :repository_find,
        payload,
        %{source: "Deeper_Hub.Core.Data.RepositoryEventIntegration"}
      )
      
      # Registra o evento no log
      Logger.debug("Evento de busca publicado", %{
        module: __MODULE__,
        schema: inspect(schema),
        count: payload.count,
        duration_ms: duration
      })
    else
      Logger.debug("Publicação de eventos de consulta desabilitada", %{
        module: __MODULE__,
        schema: inspect(schema)
      })
    end
    
    :ok
  end
  
  @doc """
  Publica um evento de transação concluída.
  
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
        Metrics.histogram("deeper_hub.core.data.repository.event.transaction_completed.duration_ms", duration_ms, %{
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
        Metrics.histogram("deeper_hub.core.data.repository.event.error.duration_ms", duration_ms, %{
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
