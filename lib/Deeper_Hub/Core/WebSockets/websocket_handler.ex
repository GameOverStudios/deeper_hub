defmodule Deeper_Hub.Core.WebSockets.WebSocketHandler do
  @moduledoc """
  Handler para conexões WebSocket.

  Este módulo gerencia conexões WebSocket, processa mensagens JSON
  e as encaminha para os handlers apropriados.
  """

  @behaviour :cowboy_websocket

  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.WebSockets.WebSocketRouter

  # Tempo limite de inatividade em milissegundos (5 minutos)
  @timeout 300_000

  @doc """
  Inicializa uma conexão HTTP que será atualizada para WebSocket.
  """
  @impl true
  def init(req, state) do
    # Extrai informações da requisição para logging
    peer = :cowboy_req.peer(req)
    path = :cowboy_req.path(req)
    _method = :cowboy_req.method(req)  # Prefixado com underscore para indicar que não é usado
    headers = :cowboy_req.headers(req)

    # Log simplificado para reduzir ruído no console
    Logger.info("Nova conexão WebSocket", %{
      module: __MODULE__,
      peer: peer,
      path: path
    })

    # Como não estamos mais logando esses valores, podemos removê-los
    # ou prefixar com underscore para indicar que não são usados
    _connection_header = Map.get(headers, "connection")
    _upgrade_header = Map.get(headers, "upgrade")
    _websocket_key = Map.get(headers, "sec-websocket-key")
    _websocket_version = Map.get(headers, "sec-websocket-version")

    # Atualiza para protocolo WebSocket
    {:cowboy_websocket, req, state, %{idle_timeout: @timeout}}
  end

  @doc """
  Manipula a inicialização da conexão WebSocket.
  """
  @impl true
  def websocket_init(state) do
    Logger.info("Conexão WebSocket inicializada", %{module: __MODULE__})

    # Armazena o estado da conexão no dicionário de processo
    # para que outros módulos possam acessá-lo
    Process.put(:websocket_state, state)

    # Publica evento de conexão estabelecida
    try do
      if Code.ensure_loaded?(Deeper_Hub.Core.EventBus) do
        Deeper_Hub.Core.EventBus.publish(:websocket_connected, %{
          timestamp: :os.system_time(:millisecond)
        })
      end
    rescue
      _ -> :ok
    end

    {:ok, state}
  end

  @doc """
  Manipula mensagens de texto recebidas pelo WebSocket.
  """
  @impl true
  def websocket_handle({:text, message}, state) do
    Logger.debug("Mensagem WebSocket recebida", %{
      module: __MODULE__,
      message: message
    })

    # Tenta decodificar a mensagem JSON
    case Jason.decode(message) do
      {:ok, decoded_message} ->
        # Processa a mensagem através do router
        handle_json_message(decoded_message, state)

      {:error, reason} ->
        Logger.error("Erro ao decodificar mensagem JSON", %{
          module: __MODULE__,
          message: message,
          error: reason
        })

        # Retorna mensagem de erro
        error_response = Jason.encode!(%{
          type: "error",
          payload: %{
            message: "Mensagem JSON inválida",
            details: inspect(reason)
          }
        })

        {:reply, {:text, error_response}, state}
    end
  end

  # Manipula mensagens binárias (não utilizadas nesta implementação)
  @impl true
  def websocket_handle({:binary, _data}, state) do
    error_response = Jason.encode!(%{
      type: "error",
      payload: %{
        message: "Mensagens binárias não são suportadas"
      }
    })

    {:reply, {:text, error_response}, state}
  end

  # Manipula outros tipos de mensagens
  @impl true
  def websocket_handle(_frame, state) do
    {:ok, state}
  end

  @doc """
  Manipula informações enviadas ao processo WebSocket.
  """
  @impl true
  def websocket_info({:send, message}, state) when is_binary(message) do
    {:reply, {:text, message}, state}
  end

  @impl true
  def websocket_info({:send, message}, state) do
    case Jason.encode(message) do
      {:ok, json} ->
        {:reply, {:text, json}, state}
      {:error, reason} ->
        Logger.error("Erro ao codificar mensagem para JSON", %{
          module: __MODULE__,
          message: message,
          error: reason
        })
        {:ok, state}
    end
  end

  @impl true
  def websocket_info(_info, state) do
    {:ok, state}
  end

  @doc """
  Manipula o encerramento da conexão WebSocket.
  """
  @impl true
  def terminate(reason, _req, _state) do
    Logger.info("Conexão WebSocket encerrada", %{
      module: __MODULE__,
      reason: reason
    })

    # Publica evento de conexão encerrada
    try do
      if Code.ensure_loaded?(Deeper_Hub.Core.EventBus) do
        Deeper_Hub.Core.EventBus.publish(:websocket_disconnected, %{
          reason: reason,
          timestamp: :os.system_time(:millisecond)
        })
      end
    rescue
      _ -> :ok
    end

    :ok
  end

  # Processa mensagens JSON e as encaminha para o router
  defp handle_json_message(%{"type" => type, "payload" => payload} = message, state) do
    # Atualiza o estado da conexão se a mensagem contiver um user_id
    state = if Map.has_key?(message, "user_id") do
      new_state = Map.put(state, :user_id, message["user_id"])
      Process.put(:websocket_state, new_state)
      new_state
    else
      state
    end
    Logger.debug("Processando mensagem JSON", %{
      module: __MODULE__,
      type: type,
      payload: payload
    })

    # Encaminha a mensagem para o router
    case WebSocketRouter.route(type, payload) do
      {:ok, response} ->
        # Codifica a resposta para JSON
        case Jason.encode(response) do
          {:ok, json_response} ->
            {:reply, {:text, json_response}, state}
          {:error, reason} ->
            Logger.error("Erro ao codificar resposta para JSON", %{
              module: __MODULE__,
              response: response,
              error: reason
            })

            error_response = Jason.encode!(%{
              type: "error",
              payload: %{
                message: "Erro ao processar resposta",
                details: "Erro de codificação"
              }
            })

            {:reply, {:text, error_response}, state}
        end

      {:error, reason} ->
        Logger.error("Erro ao processar mensagem", %{
          module: __MODULE__,
          type: type,
          payload: payload,
          error: reason
        })

        error_response = Jason.encode!(%{
          type: "error",
          payload: %{
            message: "Erro ao processar mensagem",
            details: inspect(reason)
          }
        })

        {:reply, {:text, error_response}, state}
    end
  end

  # Manipula mensagens de autenticação no formato antigo (legado)
  defp handle_json_message(%{"auth" => %{"user_id" => user_id}} = _message, state) do
    Logger.info("Autenticação de usuário (formato legado)", %{
      module: __MODULE__,
      user_id: user_id
    })

    # Atualiza o estado com o user_id
    new_state = Map.put(state, :user_id, user_id)
    Process.put(:websocket_state, new_state)

    # Retorna uma resposta de sucesso
    response = %{
      type: "auth_success",
      payload: %{user_id: user_id},
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    {:reply, {:text, Jason.encode!(response)}, new_state}

    # Registra a conexão no ConnectionManager se estiver disponível
    try do
      if Code.ensure_loaded?(Deeper_Hub.Core.Communications.ConnectionManager) do
        Deeper_Hub.Core.Communications.ConnectionManager.register(user_id, self())
      end
    rescue
      e ->
        Logger.error("Erro ao registrar conexão", %{
          module: __MODULE__,
          user_id: user_id,
          error: inspect(e)
        })
    end
  end

  # Manipula mensagens JSON que não seguem o formato padrão
  defp handle_json_message(message, state) when is_map(message) do
    Logger.warning("Mensagem JSON em formato não reconhecido", %{
      module: __MODULE__,
      message: inspect(message)
    })

    # Retorna uma mensagem de erro informando o formato esperado
    error_response = Jason.encode!(%{
      type: "error",
      payload: %{
        message: "Formato de mensagem inválido",
        details: "A mensagem deve conter 'type' e 'payload'"
      }
    })

    {:reply, {:text, error_response}, state}
  end

  # Manipula mensagens JSON sem tipo ou payload
  defp handle_json_message(_message, state) do
    error_response = Jason.encode!(%{
      type: "error",
      payload: %{
        message: "Formato de mensagem inválido",
        details: "A mensagem deve conter 'type' e 'payload'"
      }
    })

    {:reply, {:text, error_response}, state}
  end
end
