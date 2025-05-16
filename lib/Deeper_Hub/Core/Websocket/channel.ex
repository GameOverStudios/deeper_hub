defmodule Deeper_Hub.Core.Websocket.Channel do
  @moduledoc """
  Canal WebSocket para comunicação com o client C++.

  Este canal:
  - Gerencia a comunicação bidirecional
  - Implementa presence tracking
  - Gerencia estados de conexão
  - Processa operações de banco de dados
  """

  use Phoenix.Channel
  require Logger
  alias Deeper_Hub.Core.Websocket.Messages
  alias Deeper_Hub.Core.Websocket.DatabaseHandler
  alias Deeper_Hub.Core.EventBus.EventDefinitions
  alias Deeper_Hub.Core.Telemetry.TelemetryEvents

  @impl true
  def join("websocket", _params, socket) do
    # Sem autenticação temporariamente para testes
    {:ok, socket}
  end

  @impl true
  def handle_in("heartbeat", payload, socket) do
    # Responde ao heartbeat
    push(socket, "heartbeat", %{status: "ok", timestamp: payload["timestamp"]})
    {:noreply, socket}
  end

  @impl true
  def handle_in("message", payload, socket) do
    # Log da mensagem recebida para depuração
    Logger.debug("Mensagem recebida no canal: #{inspect(payload)}")

    # Processa mensagens recebidas
    try do
      # Verifica se o payload é uma string JSON
      case Jason.decode(payload) do
        {:ok, json_payload} ->
          # Processa diretamente a mensagem JSON
          process_json_message(json_payload, socket)

        {:error, _} ->
          # Se não for JSON, tenta decodificar como Protocol Buffers
          with {:ok, message} <- Messages.decode_client_message(payload) do
            # Log da mensagem decodificada
            Logger.debug("Mensagem decodificada: #{inspect(message)}")

            case message do
              %{message_type: {:database_operation, operation}} ->
                # Log da operação de banco de dados
                Logger.info("Operação de banco de dados recebida: #{inspect(operation)}")
                # Processa operação de banco de dados
                DatabaseHandler.process_operation(operation, socket)

              _ ->
                # Log do tipo de mensagem não suportada
                Logger.warning("Tipo de mensagem não suportada: #{inspect(message.message_type)}")
                # Mensagens não relacionadas a banco de dados
                # Responde com erro para manter compatibilidade
                {:reply, {:error, %{reason: "Tipo de mensagem não suportada"}}, socket}
            end
          else
            {:error, reason} ->
              Logger.warning("Erro ao decodificar mensagem", %{
                socket_id: socket.id,
                reason: reason,
                payload_size: byte_size(payload)
              })
              {:reply, {:error, %{reason: "Erro ao decodificar mensagem: #{inspect(reason)}"}}, socket}
          end
      end
    rescue
      e ->
        Logger.error("Erro inesperado ao processar mensagem: #{inspect(e)}\n#{Exception.format_stacktrace()}")
        {:reply, {:error, %{reason: "Erro interno do servidor"}}, socket}
    end
  end

  # Processa mensagens JSON recebidas diretamente
  defp process_json_message(%{"payload" => payload} = message, socket) when is_binary(payload) do
    # Tenta decodificar o payload JSON
    case Jason.decode(payload) do
      {:ok, decoded_payload} ->
        # Processa o payload decodificado
        process_json_payload(decoded_payload, message["ref"], socket)
      {:error, reason} ->
        Logger.warning("Erro ao decodificar payload JSON: #{inspect(reason)}")
        {:reply, {:error, %{reason: "Erro ao decodificar payload JSON"}}, socket}
    end
  end

  defp process_json_message(%{"payload" => payload} = message, socket) when is_map(payload) do
    # O payload já é um mapa, processa diretamente
    process_json_payload(payload, message["ref"], socket)
  end

  # Processa mensagens no formato que o cliente Python está enviando
  defp process_json_message(%{"database_operation" => _} = payload, socket) do
    # Mensagem de operação de banco de dados direta
    Logger.debug("Processando operação de banco de dados direta: #{inspect(payload)}")
    process_database_operation(payload, socket)
  end

  defp process_json_message(message, socket) do
    Logger.warning("Formato de mensagem JSON inválido: #{inspect(message)}")
    {:reply, {:error, %{reason: "Formato de mensagem JSON inválido"}}, socket}
  end

  # Processa o payload JSON decodificado
  defp process_json_payload(%{"database_operation" => db_op}, ref, socket) when is_map(db_op) do
    # Log para depurar o conteúdo da operação de banco de dados
    Logger.debug("Processando operação de banco de dados: #{inspect(db_op)}")

    # Converte a operação de banco de dados para o formato esperado
    operation = %Messages.DatabaseOperation{
      operation: Map.get(db_op, "operation"),
      schema: Map.get(db_op, "schema"),
      id: Map.get(db_op, "id"),
      data: Map.get(db_op, "data"),
      request_id: Map.get(db_op, "request_id", ref),
      timestamp: Map.get(db_op, "timestamp", System.system_time(:millisecond))
    }

    # Log da operação convertida
    Logger.debug("Operação convertida: #{inspect(operation)}")

    # Processa a operação de banco de dados
    DatabaseHandler.process_operation(operation, socket)
  end

  defp process_json_payload(payload, _ref, socket) do
    Logger.warning("Payload JSON não suportado: #{inspect(payload)}")
    {:reply, {:error, %{reason: "Tipo de mensagem não suportada"}}, socket}
  end

  # Processa operações de banco de dados diretas
  defp process_database_operation(%{"database_operation" => db_op} = message, socket) when is_map(db_op) do
    # Log para depurar o conteúdo da operação de banco de dados
    Logger.info("Processando operação de banco de dados direta: #{inspect(db_op)}")

    # Converte a operação de banco de dados para o formato esperado
    operation = %Messages.DatabaseOperation{
      operation: Map.get(db_op, "operation"),
      schema: Map.get(db_op, "schema"),
      id: Map.get(db_op, "id"),
      data: Map.get(db_op, "data"),
      request_id: Map.get(db_op, "request_id", message["ref"]),
      timestamp: Map.get(db_op, "timestamp", System.system_time(:millisecond))
    }

    # Log da operação convertida
    Logger.debug("Operação convertida: #{inspect(operation)}")

    # Processa a operação de banco de dados
    DatabaseHandler.process_operation(operation, socket)
  end

  @impl true
  def handle_out(event, payload, socket) do
    push(socket, event, payload)
    {:noreply, socket}
  end

  @impl true
  def terminate(reason, socket) do
    # Emite evento de desconexão
    EventDefinitions.emit(
      EventDefinitions.websocket_disconnection(),
      %{socket_id: socket.id, reason: reason},
      source: "#{__MODULE__}"
    )

    # Emite métrica de desconexão
    TelemetryEvents.execute_websocket_disconnection(
      %{count: 1},
      %{socket_id: socket.id, reason: reason, module: __MODULE__}
    )

    :ok
  end

  @doc """
  Encerra uma conexão WebSocket pelo ID do socket.

  ## Parâmetros

    - `socket_id`: ID do socket a ser terminado
    - `reason`: Razão do término (e.g., :zombie, :normal, etc.)

  ## Retorno

    - `:ok` se a operação for bem-sucedida
  """
  @spec terminate_by_id(String.t(), atom()) :: :ok
  def terminate_by_id(socket_id, reason) do
    # Emite evento de desconexão
    EventDefinitions.emit(
      EventDefinitions.websocket_disconnection(),
      %{socket_id: socket_id, reason: reason},
      source: "#{__MODULE__}"
    )

    # Emite métrica de desconexão
    TelemetryEvents.execute_websocket_disconnection(
      %{count: 1},
      %{socket_id: socket_id, reason: reason, module: __MODULE__}
    )

    :ok
  end
end
