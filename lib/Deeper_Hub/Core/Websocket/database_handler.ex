defmodule DeeperHub.Core.Websocket.DatabaseHandler do
  @moduledoc """
  Handler para operações de banco de dados via WebSocket.

  Este módulo:
  - Processa operações CRUD recebidas via WebSocket
  - Integra com o repositório para acessar o banco de dados
  - Serializa/deserializa dados entre Protocol Buffers e Elixir
  - Implementa validações e controle de acesso
  """

  require Logger
  alias Deeper_Hub.Core.Data.Repository
  alias Deeper_Hub.Core.Schemas.User
  alias Deeper_Hub.Core.Schemas.Profile
  alias DeeperHub.Core.Websocket.Messages
  alias Deeper_Hub.Core.EventBus.EventDefinitions
  alias Deeper_Hub.Core.Telemetry.TelemetryEvents

  @doc """
  Processa uma operação de banco de dados recebida via WebSocket.

  ## Parâmetros

  - `operation`: A mensagem de operação de banco de dados
  - `socket`: O socket do Phoenix

  ## Retorno

  - `{:reply, {:ok, response}, socket}`: Resposta de sucesso
  - `{:reply, {:error, reason}, socket}`: Resposta de erro
  """
  @spec process_operation(Messages.DatabaseOperation.t(), Phoenix.Socket.t()) :: {:reply, {:ok, map()} | {:error, map()}, Phoenix.Socket.t()}
  def process_operation(%Messages.DatabaseOperation{} = operation, socket) do
    # Registra a operação recebida
    Logger.info("Operação de banco de dados recebida", %{
      operation: operation.operation,
      schema: operation.schema,
      id: operation.id,
      data_size: if(operation.data, do: byte_size(operation.data), else: 0),
      request_id: operation.request_id,
      socket_id: socket.id
    })

    # Emite evento de operação de banco de dados
    EventDefinitions.emit(
      EventDefinitions.websocket_db_operation(),
      %{
        socket_id: socket.id,
        operation: operation.operation,
        schema: operation.schema,
        request_id: operation.request_id
      },
      source: "#{__MODULE__}"
    )

    # Inicia a medição de tempo para telemetria
    start_time = System.monotonic_time()

    # Processa a operação com base no tipo
    result = case operation.operation do
      "create" -> create_record(operation)
      "read" -> read_record(operation)
      "update" -> update_record(operation)
      "delete" -> delete_record(operation)
      "find" -> find_records(operation)
      "list" -> list_records(operation)
      _ -> {:error, "Operação não suportada"}
    end

    # Calcula a duração para telemetria
    end_time = System.monotonic_time()
    duration = end_time - start_time

    # Emite métrica de operação de banco de dados
    TelemetryEvents.execute_websocket_db_operation(
      %{duration: duration, count: 1},
      %{
        socket_id: socket.id,
        operation: operation.operation,
        schema: operation.schema,
        status: if(elem(result, 0) == :ok, do: :success, else: :error),
        module: __MODULE__
      }
    )

    # Formata a resposta
    case result do
      {:ok, data} ->
        # Prepara os dados para resposta JSON
        sanitized_data = case data do
          data when is_list(data) -> 
            # Se for uma lista, sanitiza cada item
            Enum.map(data, &sanitize_record/1)
          data -> 
            # Se for um único registro, sanitiza-o
            sanitize_record(data)
        end
        
        # Cria uma resposta JSON diretamente
        response = %{
          "type" => "database_response",
          "schema" => operation.schema,
          "operation" => operation.operation,
          "request_id" => operation.request_id,
          "status" => "success",
          "data" => sanitized_data,
          "timestamp" => System.system_time(:millisecond)
        }

        {:reply, {:ok, response}, socket}

      {:error, reason} ->
        # Log de erro
        Logger.warning("Erro na operação de banco de dados", %{
          operation: operation.operation,
          schema: operation.schema,
          reason: inspect(reason),
          request_id: operation.request_id
        })

        # Emite evento de erro de banco de dados
        EventDefinitions.emit(
          EventDefinitions.db_error(),
          %{
            operation: operation.operation,
            schema: operation.schema,
            reason: inspect(reason),
            request_id: operation.request_id
          },
          source: "#{__MODULE__}"
        )

        # Formata a mensagem de erro
        error_message = case reason do
          %Ecto.Changeset{} = changeset ->
            Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
              Enum.reduce(opts, msg, fn {key, value}, acc ->
                String.replace(acc, "%{#{key}}", to_string(value))
              end)
            end)
          _ ->
            to_string(reason)
        end

        # Cria uma resposta JSON diretamente
        response = %{
          "type" => "database_response",
          "schema" => operation.schema,
          "operation" => operation.operation,
          "request_id" => operation.request_id,
          "status" => "error",
          "error" => error_message,
          "timestamp" => System.system_time(:millisecond)
        }

        {:reply, {:error, response}, socket}
    end
  end

  # Funções privadas para cada tipo de operação

  defp create_record(operation) do
    # Converte o schema de string para módulo
    schema_module = get_schema_module(operation.schema)
    
    # Deserializa os dados
    case Jason.decode(operation.data) do
      {:ok, data} ->
        # Cria o registro
        Repository.insert(schema_module, data)
      
      {:error, reason} ->
        {:error, "Erro ao deserializar dados: #{inspect(reason)}"}
    end
  end

  defp read_record(operation) do
    # Converte o schema de string para módulo
    schema_module = get_schema_module(operation.schema)
    
    # Busca o registro
    case Repository.get(schema_module, operation.id) do
      {:ok, record} ->
        # Sanitiza o registro antes de retornar
        {:ok, sanitize_record(record)}
      
      error ->
        error
    end
  end

  defp update_record(operation) do
    # Converte o schema de string para módulo
    schema_module = get_schema_module(operation.schema)
    
    # Deserializa os dados
    case Jason.decode(operation.data) do
      {:ok, data} ->
        # Busca o registro existente
        case Repository.get(schema_module, operation.id) do
          {:ok, record} ->
            # Atualiza o registro
            # Cria uma struct atualizada com os novos dados
            record_with_changes = Map.merge(record, data)
            
            # Chama update/2 com a struct atualizada
            Repository.update(record_with_changes, data)
            |> case do
              {:ok, updated} -> {:ok, sanitize_record(updated)}
              error -> error
            end
          
          error ->
            error
        end
      
      {:error, reason} ->
        {:error, "Erro ao deserializar dados: #{inspect(reason)}"}
    end
  end

  defp delete_record(operation) do
    # Converte o schema de string para módulo
    schema_module = get_schema_module(operation.schema)
    
    # Busca o registro existente
    case Repository.get(schema_module, operation.id) do
      {:ok, record} ->
        # Deleta o registro
        Repository.delete(record)
        |> case do
          {:ok, _} -> {:ok, %{id: operation.id, deleted: true}}
          error -> error
        end
      
      error ->
        error
    end
  end

  defp find_records(operation) do
    # Converte o schema de string para módulo
    schema_module = get_schema_module(operation.schema)
    
    # Deserializa as condições
    case Jason.decode(operation.conditions) do
      {:ok, conditions} when is_map(conditions) ->
        # Busca os registros
        Repository.find(schema_module, conditions)
        |> case do
          {:ok, records} -> {:ok, Enum.map(records, &sanitize_record/1)}
          error -> error
        end
      
      {:error, reason} ->
        {:error, "Erro ao deserializar condições: #{inspect(reason)}"}
    end
  end

  defp list_records(operation) do
    # Converte o schema de string para módulo
    schema_module = get_schema_module(operation.schema)
    
    # Lista os registros
    Repository.list(schema_module)
    |> case do
      {:ok, records} -> {:ok, Enum.map(records, &sanitize_record/1)}
      error -> error
    end
  end

  # Funções auxiliares

  defp get_schema_module(schema_name) do
    case schema_name do
      "user" -> User
      "profile" -> Profile
      _ -> nil
    end
  end

  defp sanitize_record(record) do
    # Converte o registro para um mapa seguro, removendo campos sensíveis
    # e garantindo que seja serializável para JSON
    record
    |> Map.from_struct()
    |> Map.drop([:__meta__, :password_hash, :password])
    |> sanitize_timestamps()
  end
  
  # Converte timestamps para formato ISO8601 para garantir serialização JSON
  defp sanitize_timestamps(map) do
    map
    |> Enum.map(fn
      {k, %NaiveDateTime{} = v} -> {k, NaiveDateTime.to_iso8601(v)}
      {k, %DateTime{} = v} -> {k, DateTime.to_iso8601(v)}
      {k, v} -> {k, v}
    end)
    |> Enum.into(%{})
  end
end
