defmodule Deeper_Hub.Core.WebSockets.WebSocketHandler do
  @moduledoc """
  Handler para conexões WebSocket.

  Este módulo gerencia conexões WebSocket, processa mensagens JSON
  e as encaminha para os handlers apropriados.
  """

  @behaviour :cowboy_websocket

  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.WebSockets.WebSocketRouter
  alias Deeper_Hub.Core.WebSockets.Security.SecuritySupervisor

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
    _headers = :cowboy_req.headers(req)

    # Log simplificado para reduzir ruído no console
    Logger.info("Nova conexão WebSocket", %{
      module: __MODULE__,
      peer: peer,
      path: path
    })

    # Verifica segurança da requisição
    case SecuritySupervisor.check_request(req, state) do
      {:ok, secured_state} ->
        # Atualiza para protocolo WebSocket
        {:cowboy_websocket, req, secured_state, %{idle_timeout: @timeout}}

      {:error, reason} ->
        # Rejeita a conexão por motivos de segurança
        Logger.warn("Conexão WebSocket rejeitada por motivos de segurança", %{
          module: __MODULE__,
          reason: reason,
          peer: peer
        })

        # Publica evento de segurança
        if Code.ensure_loaded?(Deeper_Hub.Core.EventBus) do
          Deeper_Hub.Core.EventBus.publish(:security_violation, %{
            type: :connection_rejected,
            reason: reason,
            peer: peer,
            path: path,
            timestamp: :os.system_time(:millisecond)
          })
        end

        {:ok, req2} = :cowboy_req.reply(403, %{}, "Acesso negado: #{reason}", req)
        {:ok, req2, state}
    end
  end

  @doc """
  Coordena a inicialização da conexão WebSocket.
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
  Coordena mensagens de texto recebidas pelo WebSocket.
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
        # Verifica segurança da mensagem
        case SecuritySupervisor.check_message(decoded_message, state) do
          {:ok, sanitized_message} ->
            # Processa a mensagem sanitizada através do router
            handle_json_message(sanitized_message, state)

          {:error, reason} ->
            # Mensagem bloqueada por motivos de segurança
            Logger.warn("Mensagem WebSocket bloqueada por motivos de segurança", %{
              module: __MODULE__,
              reason: reason,
              user_id: state[:user_id]
            })

            # Publica evento de segurança
            if Code.ensure_loaded?(Deeper_Hub.Core.EventBus) do
              Deeper_Hub.Core.EventBus.publish(:security_violation, %{
                type: :message_blocked,
                reason: reason,
                user_id: state[:user_id],
                timestamp: :os.system_time(:millisecond)
              })
            end

            # Retorna mensagem de erro
            error_response = Jason.encode!(%{
              type: "error",
              payload: %{
                message: "Mensagem bloqueada por motivos de segurança",
                details: reason
              }
            })

            {:reply, {:text, error_response}, state}
        end

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

  # Coordena mensagens binárias (não utilizadas nesta implementação)
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

  # Coordena outros tipos de mensagens
  @impl true
  def websocket_handle(_frame, state) do
    {:ok, state}
  end

  @doc """
  Coordena informações enviadas ao processo WebSocket.
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
  Coordena o encerramento da conexão WebSocket.
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
  defp handle_json_message(%{"type" => type, "payload" => payload} = _message, state) do
    # Não atualizamos mais o estado diretamente a partir do payload da mensagem
    # A autenticação agora é feita exclusivamente pelo AuthHandler
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

      {:error, %{message: _message, type: error_type, payload: error_payload}} when is_map(error_payload) ->
        Logger.error("Erro ao processar mensagem", %{
          module: __MODULE__,
          type: type,
          payload: payload,
          error_type: error_type
        })

        error_response = Jason.encode!(%{
          type: error_type,
          payload: error_payload
        })

        {:reply, {:text, error_response}, state}

      {:error, reason} ->
        Logger.error("Erro ao processar mensagem", %{
          module: __MODULE__,
          type: type,
          payload: payload,
          error: reason
        })

        # Extraímos a mensagem de erro de forma segura
        error_message = cond do
          is_map(reason) && Map.has_key?(reason, :message) -> reason.message
          is_binary(reason) -> reason
          true -> inspect(reason)
        end

        error_response = Jason.encode!(%{
          type: "error",
          payload: %{
            message: "Erro ao processar mensagem",
            details: error_message
          }
        })

        {:reply, {:text, error_response}, state}
    end
  end

  # Código de autenticação legado removido

  # Coordena mensagens JSON que não seguem o formato padrão
  defp handle_json_message(message, state) when is_map(message) do
    Logger.warn("Mensagem JSON em formato não reconhecido", %{
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

  # Coordena mensagens JSON sem tipo ou payload
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
