defmodule Deeper_Hub.Core.Websocket.Messages do
  @moduledoc """
  Definições de mensagens Protocol Buffers para comunicação WebSocket.

  Este módulo:
  - Define as estruturas de mensagens
  - Implementa serialização/deserialização
  - Integra com Protocol Buffers
  """

  use Protobuf, syntax: :proto3
  alias Deeper_Hub.Core.Resilience.CircuitBreaker

  # Definições de mensagens do cliente
  defmodule ClientMessage do
    @moduledoc """
    Mensagem enviada pelo cliente para o servidor.
    """
    use Protobuf, syntax: :proto3

    oneof :message_type, 0
    field :ui_action, 1, type: UiAction, oneof: 0
    field :data_request, 2, type: DataRequest, oneof: 0
    field :event_ack, 3, type: EventAck, oneof: 0
    field :heartbeat, 4, type: Heartbeat, oneof: 0
    field :custom_message, 5, type: CustomMessage, oneof: 0
    field :database_operation, 6, type: DatabaseOperation, oneof: 0
  end

  defmodule UiAction do
    @moduledoc """
    Ação da UI enviada pelo cliente.
    """
    use Protobuf, syntax: :proto3

    field :action_type, 1, type: :string
    field :payload, 2, type: :bytes
    field :request_id, 3, type: :string
    field :timestamp, 4, type: :int64
  end

  defmodule DataRequest do
    @moduledoc """
    Requisição de dados enviada pelo cliente.
    """
    use Protobuf, syntax: :proto3

    field :resource_type, 1, type: :string
    field :resource_id, 2, type: :string
    field :filters, 3, repeated: true, type: Filter
    field :request_id, 4, type: :string
    field :timestamp, 5, type: :int64
  end

  defmodule Filter do
    @moduledoc """
    Filtro para requisição de dados.
    """
    use Protobuf, syntax: :proto3

    field :field, 1, type: :string
    field :operator, 2, type: :string
    field :value, 3, type: :string
  end

  defmodule EventAck do
    @moduledoc """
    Confirmação de evento enviada pelo cliente.
    """
    use Protobuf, syntax: :proto3

    field :event_id, 1, type: :string
    field :status, 2, type: :string
    field :timestamp, 3, type: :int64
  end

  defmodule Heartbeat do
    @moduledoc """
    Heartbeat enviado pelo cliente para manter a conexão ativa.
    """
    use Protobuf, syntax: :proto3

    field :client_timestamp, 1, type: :int64
    field :sequence, 2, type: :int32
  end

  defmodule CustomMessage do
    @moduledoc """
    Mensagem personalizada enviada pelo cliente.
    """
    use Protobuf, syntax: :proto3

    field :content, 1, type: :string
    field :message_type, 2, type: :string
    field :timestamp, 3, type: :int64
  end

  defmodule DatabaseOperation do
    @moduledoc """
    Operação de banco de dados enviada pelo cliente.
    """
    use Protobuf, syntax: :proto3

    field :operation, 1, type: :string # "create", "read", "update", "delete", "find", "list"
    field :schema, 2, type: :string # "user", "profile"
    field :id, 3, type: :string
    field :data, 4, type: :bytes # JSON serializado
    field :conditions, 5, type: :bytes # JSON serializado para operações de busca
    field :request_id, 6, type: :string
    field :timestamp, 7, type: :int64
  end

  # Definições de mensagens do servidor
  defmodule ServerMessage do
    @moduledoc """
    Mensagem enviada pelo servidor para o cliente.
    """
    use Protobuf, syntax: :proto3

    oneof :message_type, 0
    field :ui_update, 1, type: UiUpdate, oneof: 0
    field :data_response, 2, type: DataResponse, oneof: 0
    field :server_event, 3, type: ServerEvent, oneof: 0
    field :heartbeat_response, 4, type: HeartbeatResponse, oneof: 0
  end

  defmodule UiUpdate do
    @moduledoc """
    Atualização da UI enviada pelo servidor.
    """
    use Protobuf, syntax: :proto3

    field :update_type, 1, type: :string
    field :payload, 2, type: :bytes
    field :response_to, 3, type: :string
    field :timestamp, 4, type: :int64
  end

  defmodule DataResponse do
    @moduledoc """
    Resposta de dados enviada pelo servidor.
    """
    use Protobuf, syntax: :proto3

    field :resource_type, 1, type: :string
    field :resource_id, 2, type: :string
    field :data, 3, type: :bytes
    field :response_to, 4, type: :string
    field :timestamp, 5, type: :int64
    field :status, 6, type: :string
    field :error_message, 7, type: :string
  end

  defmodule ServerEvent do
    @moduledoc """
    Evento enviado pelo servidor para o cliente.
    """
    use Protobuf, syntax: :proto3

    field :event_type, 1, type: :string
    field :event_id, 2, type: :string
    field :payload, 3, type: :bytes
    field :timestamp, 4, type: :int64
    field :requires_ack, 5, type: :bool
  end

  defmodule HeartbeatResponse do
    @moduledoc """
    Resposta de heartbeat enviada pelo servidor.
    """
    use Protobuf, syntax: :proto3

    field :client_timestamp, 1, type: :int64
    field :server_timestamp, 2, type: :int64
    field :sequence, 3, type: :int32
  end

  # Funções auxiliares para serialização/deserialização protegidas por circuit breaker

  @doc """
  Serializa uma mensagem do servidor para envio ao cliente.
  """
  def encode_server_message(message) do
    CircuitBreaker.call(
      :protobuf_encode,
      fn -> ServerMessage.encode(message) end,
      [],
      threshold: 5,
      timeout_sec: 10
    )
  end

  @doc """
  Deserializa uma mensagem do cliente.
  Suporta tanto mensagens Protocol Buffers quanto JSON.
  """
  def decode_client_message(payload) when is_binary(payload) do
    # Tenta decodificar como JSON primeiro
    case Jason.decode(payload) do
      {:ok, json_data} ->
        # Se for JSON, converte para o formato ClientMessage
        decode_json_message(json_data)
      {:error, _} ->
        # Se não for JSON, tenta decodificar como Protocol Buffers
        CircuitBreaker.call(
          :protobuf_decode,
          fn -> ClientMessage.decode(payload) end,
          [],
          threshold: 5,
          timeout_sec: 10
        )
    end
  end

  # Decodifica uma mensagem JSON para o formato ClientMessage
  defp decode_json_message(%{"payload" => payload}) when is_binary(payload) do
    # Tenta decodificar o payload como JSON
    case Jason.decode(payload) do
      {:ok, decoded_payload} ->
        # Processa o payload decodificado
        process_json_payload(decoded_payload)
      {:error, reason} ->
        {:error, "Erro ao decodificar payload JSON: #{inspect(reason)}"}
    end
  end

  defp decode_json_message(%{"payload" => payload}) when is_map(payload) do
    # O payload já é um mapa, processa diretamente
    process_json_payload(payload)
  end

  defp decode_json_message(_) do
    {:error, "Formato de mensagem JSON inválido"}
  end

  # Processa o payload JSON e converte para o formato ClientMessage
  defp process_json_payload(%{"database_operation" => db_op}) when is_map(db_op) do
    # Log para depurar o conteúdo da operação de banco de dados
    require Logger
    Logger.debug("Processando operação de banco de dados: #{inspect(db_op)}")

    # Converte a operação de banco de dados para o formato esperado
    operation = %DatabaseOperation{
      operation: Map.get(db_op, "operation"),
      schema: Map.get(db_op, "schema"),
      id: Map.get(db_op, "id"),
      data: Map.get(db_op, "data"),
      request_id: Map.get(db_op, "request_id"),
      timestamp: Map.get(db_op, "timestamp", System.system_time(:millisecond))
    }

    # Log da operação convertida
    Logger.debug("Operação convertida: #{inspect(operation)}")

    # Cria uma mensagem do cliente com a operação de banco de dados
    {:ok, %ClientMessage{message_type: {:database_operation, operation}}}
  end

  defp process_json_payload(_) do
    {:error, "Tipo de mensagem JSON não suportado"}
  end

  @doc """
  Cria uma mensagem de atualização da UI.
  """
  def create_ui_update(update_type, payload, response_to \\ nil) do
    ui_update = %UiUpdate{
      update_type: update_type,
      payload: payload,
      response_to: response_to || "",
      timestamp: DateTime.to_unix(DateTime.utc_now(), :millisecond)
    }

    %ServerMessage{message_type: {:ui_update, ui_update}}
  end

  @doc """
  Cria uma mensagem de resposta de dados.
  """
  def create_data_response(resource_type, resource_id, data, response_to, status \\ "success", error_message \\ "") do
    data_response = %DataResponse{
      resource_type: resource_type,
      resource_id: resource_id,
      data: data,
      response_to: response_to,
      timestamp: DateTime.to_unix(DateTime.utc_now(), :millisecond),
      status: status,
      error_message: error_message
    }

    %ServerMessage{message_type: {:data_response, data_response}}
  end

  @doc """
  Cria uma mensagem de evento do servidor.
  """
  def create_server_event(event_type, payload, requires_ack \\ false) do
    event_id = UUID.uuid4()

    server_event = %ServerEvent{
      event_type: event_type,
      event_id: event_id,
      payload: payload,
      timestamp: DateTime.to_unix(DateTime.utc_now(), :millisecond),
      requires_ack: requires_ack
    }

    %ServerMessage{message_type: {:server_event, server_event}}
  end

  @doc """
  Cria uma resposta de heartbeat.
  """
  def create_heartbeat_response(client_timestamp, sequence) do
    heartbeat_response = %HeartbeatResponse{
      client_timestamp: client_timestamp,
      server_timestamp: DateTime.to_unix(DateTime.utc_now(), :millisecond),
      sequence: sequence
    }

    %ServerMessage{message_type: {:heartbeat_response, heartbeat_response}}
  end
end
