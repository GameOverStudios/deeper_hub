defmodule DeeperHub.Core.Network.Socket.AuthSocket do
  @moduledoc """
  Socket WebSocket autenticado para o DeeperHub.

  Este módulo implementa um socket WebSocket que requer autenticação
  via token JWT antes de permitir a conexão.
  """

  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  alias DeeperHub.Accounts.Auth.Token

  @doc """
  Inicializa uma nova conexão WebSocket autenticada.

  ## Parâmetros
    * `req` - Requisição WebSocket
    * `state` - Estado inicial

  ## Retorno
    * `{:ok, req, state}` - Se a autenticação for bem-sucedida
    * `{:error, reason}` - Se a autenticação falhar
  """
  def init(req, state) do
    case authenticate_request(req) do
      {:ok, user_id} ->
        Logger.info("Conexão WebSocket autenticada para o usuário: #{user_id}", module: __MODULE__)

        # Inicializa o estado com o ID do usuário
        new_state = Map.put(state, :user_id, user_id)
        {:ok, req, new_state}

      {:error, reason} ->
        Logger.warn("Falha na autenticação WebSocket: #{inspect(reason)}", module: __MODULE__)
        {:error, {:unauthorized, reason}}
    end
  end

  @doc """
  Manipula mensagens WebSocket recebidas.

  ## Parâmetros
    * `frame_type` - Tipo do frame WebSocket
    * `data` - Dados recebidos
    * `req` - Requisição WebSocket
    * `state` - Estado atual

  ## Retorno
    * `{:ok, req, state}` - Resposta para a mensagem
  """
  def websocket_handle({:text, data}, req, state) do
    case Jason.decode(data) do
      {:ok, message} ->
        handle_message(message, req, state)

      {:error, _reason} ->
        Logger.warn("Mensagem WebSocket inválida recebida", module: __MODULE__)

        # Envia resposta de erro
        response = Jason.encode!(%{error: "Formato de mensagem inválido"})
        {:reply, {:text, response}, req, state}
    end
  end

  def websocket_handle(_frame, req, state) do
    # Ignora outros tipos de frames
    {:ok, req, state}
  end

  @doc """
  Manipula informações recebidas de outros processos.

  ## Parâmetros
    * `info` - Informação recebida
    * `req` - Requisição WebSocket
    * `state` - Estado atual

  ## Retorno
    * `{:ok, req, state}` - Resposta para a informação
  """
  def websocket_info({:send, data}, req, state) do
    # Envia dados para o cliente
    {:reply, {:text, Jason.encode!(data)}, req, state}
  end

  def websocket_info(_info, req, state) do
    # Ignora outras informações
    {:ok, req, state}
  end

  @doc """
  Manipula o encerramento da conexão WebSocket.

  ## Parâmetros
    * `reason` - Motivo do encerramento
    * `req` - Requisição WebSocket
    * `state` - Estado atual

  ## Retorno
    * `:ok` - Confirmação do encerramento
  """
  def terminate(reason, _req, state) do
    Logger.info("Conexão WebSocket encerrada para o usuário: #{state.user_id}, motivo: #{inspect(reason)}",
                module: __MODULE__)
    :ok
  end

  # Funções privadas

  # Autentica a requisição WebSocket usando o token JWT
  defp authenticate_request(req) do
    # Extrai o token do cabeçalho de autorização ou dos parâmetros da query
    case extract_token(req) do
      {:ok, token} -> validate_token(token)
      error -> error
    end
  end

  # Extrai o token JWT da requisição
  defp extract_token(req) do
    # Tenta extrair do cabeçalho de autorização
    case :cowboy_req.header("authorization", req) do
      :undefined ->
        # Se não encontrar no cabeçalho, tenta nos parâmetros da query
        qs_vals = :cowboy_req.parse_qs(req)
        case List.keyfind(qs_vals, "token", 0) do
          {"token", token} -> {:ok, token}
          nil -> {:error, :missing_token}
        end

      auth_header ->
        # Extrai o token do cabeçalho "Bearer <token>"
        case String.split(auth_header, " ", parts: 2) do
          ["Bearer", token] -> {:ok, token}
          _ -> {:error, :invalid_auth_header}
        end
    end
  end

  # Valida o token JWT e extrai o ID do usuário
  defp validate_token(token) do
    case Token.verify_access_token(token) do
      {:ok, claims} ->
        # Extrai o ID do usuário do token
        {:ok, claims["sub"]}

      {:error, :token_expired} ->
        {:error, :token_expired}

      {:error, _reason} ->
        {:error, :invalid_token}
    end
  end

  # Manipula diferentes tipos de mensagens
  defp handle_message(%{"type" => "ping"}, req, state) do
    # Responde com pong
    response = Jason.encode!(%{type: "pong", timestamp: :os.system_time(:millisecond)})
    {:reply, {:text, response}, req, state}
  end

  defp handle_message(%{"type" => "subscribe", "channel" => channel}, req, state) do
    # Inscreve o usuário no canal
    case DeeperHub.Core.Network.Channels.subscribe(channel, state.user_id) do
      :ok ->
        Logger.info("Usuário #{state.user_id} inscrito no canal: #{channel}", module: __MODULE__)
        response = Jason.encode!(%{type: "subscribed", channel: channel})
        {:reply, {:text, response}, req, state}

      {:error, reason} ->
        Logger.warn("Falha ao inscrever usuário #{state.user_id} no canal: #{channel}, motivo: #{inspect(reason)}",
                    module: __MODULE__)
        response = Jason.encode!(%{type: "error", error: "Falha ao inscrever no canal", reason: reason})
        {:reply, {:text, response}, req, state}
    end
  end

  defp handle_message(%{"type" => "unsubscribe", "channel" => channel}, req, state) do
    # Cancela a inscrição do usuário no canal
    case DeeperHub.Core.Network.Channels.unsubscribe(channel, state.user_id) do
      :ok ->
        Logger.info("Usuário #{state.user_id} desinscrito do canal: #{channel}", module: __MODULE__)
        response = Jason.encode!(%{type: "unsubscribed", channel: channel})
        {:reply, {:text, response}, req, state}

      {:error, reason} ->
        Logger.warn("Falha ao desinscrever usuário #{state.user_id} do canal: #{channel}, motivo: #{inspect(reason)}",
                    module: __MODULE__)
        response = Jason.encode!(%{type: "error", error: "Falha ao desinscrever do canal", reason: reason})
        {:reply, {:text, response}, req, state}
    end
  end

  defp handle_message(%{"type" => "message", "channel" => channel, "content" => content}, req, state) do
    # Envia mensagem para o canal
    message = %{
      sender_id: state.user_id,
      content: content,
      timestamp: :os.system_time(:millisecond)
    }

    case DeeperHub.Core.Network.Channels.broadcast(channel, message) do
      :ok ->
        Logger.debug("Mensagem enviada para o canal: #{channel} pelo usuário: #{state.user_id}",
                     module: __MODULE__)
        {:ok, req, state}

      {:error, reason} ->
        Logger.warn("Falha ao enviar mensagem para o canal: #{channel}, motivo: #{inspect(reason)}",
                    module: __MODULE__)
        response = Jason.encode!(%{type: "error", error: "Falha ao enviar mensagem", reason: reason})
        {:reply, {:text, response}, req, state}
    end
  end

  defp handle_message(message, req, state) do
    # Manipula mensagens desconhecidas
    Logger.warn("Mensagem WebSocket desconhecida: #{inspect(message)}", module: __MODULE__)
    response = Jason.encode!(%{type: "error", error: "Tipo de mensagem desconhecido"})
    {:reply, {:text, response}, req, state}
  end
end
