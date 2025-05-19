defmodule DeeperHub.Core.Network.Socket.AuthSocket do
  @moduledoc """
  Socket WebSocket autenticado para o DeeperHub.

  Este módulo implementa um socket WebSocket que requer autenticação
  via token JWT antes de permitir a conexão.
  
  Recursos de segurança implementados:
  - Autenticação via JWT
  - Limites de taxa para evitar abuso
  - Validação rigorosa de mensagens
  - Tratamento adequado de erros
  - Logs detalhados para auditoria
  """

  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  alias DeeperHub.Accounts.Auth.Guardian
  
  # Configurações de limites de taxa
  @max_messages_per_minute 120 # 2 mensagens por segundo em média
  @max_message_size 16_384 # 16KB
  @max_subscriptions 50 # Número máximo de canais que um usuário pode se inscrever

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
    # Verifica se o número máximo de conexões foi atingido
    max_connections = Application.get_env(:deeper_hub, :network, [])[:max_connections] || 10_000
    current_connections = :ets.info(:socket_connections, :size) || 0
    
    if current_connections >= max_connections do
      Logger.warn("Limite de conexões WebSocket atingido: #{current_connections}/#{max_connections}", module: __MODULE__)
      {:error, {:service_unavailable, "Limite de conexões atingido"}}
    else
      case authenticate_request(req) do
        {:ok, user_id} ->
          # Verifica se o usuário já tem muitas conexões ativas
          user_connections = count_user_connections(user_id)
          max_user_connections = Application.get_env(:deeper_hub, :network, [])[:max_user_connections] || 5
          
          if user_connections >= max_user_connections do
            Logger.warn("Limite de conexões por usuário atingido para #{user_id}: #{user_connections}/#{max_user_connections}", module: __MODULE__)
            {:error, {:too_many_connections, "Limite de conexões por usuário atingido"}}
          else
            Logger.info("Conexão WebSocket autenticada para o usuário: #{user_id}", module: __MODULE__)
            
            # Inicializa o estado com o ID do usuário e contadores para limites de taxa
            new_state = state
              |> Map.put(:user_id, user_id)
              |> Map.put(:message_count, 0)
              |> Map.put(:last_reset, :os.system_time(:millisecond))
              |> Map.put(:subscriptions, [])
            
            # Registra a conexão na tabela ETS para rastreamento
            register_connection(user_id)
            
            {:ok, req, new_state}
          end

        {:error, reason} ->
          Logger.warn("Falha na autenticação WebSocket: #{inspect(reason)}", module: __MODULE__)
          {:error, {:unauthorized, reason}}
      end
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
    # Verifica o tamanho da mensagem
    if byte_size(data) > @max_message_size do
      Logger.warn("Mensagem WebSocket excede o tamanho máximo permitido: #{byte_size(data)} bytes", 
                 module: __MODULE__, user_id: state.user_id)
      
      response = Jason.encode!(%{type: "error", error: "Mensagem muito grande", code: "message_too_large"})
      {:reply, {:text, response}, req, state}
    else
      # Verifica o limite de taxa
      case check_rate_limit(state) do
        {:ok, new_state} ->
          # Processa a mensagem
          case Jason.decode(data) do
            {:ok, message} ->
              # Valida a estrutura da mensagem
              if is_valid_message?(message) do
                handle_message(message, req, new_state)
              else
                Logger.warn("Estrutura de mensagem WebSocket inválida: #{inspect(message)}", 
                           module: __MODULE__, user_id: state.user_id)
                
                response = Jason.encode!(%{type: "error", error: "Estrutura de mensagem inválida", code: "invalid_message_structure"})
                {:reply, {:text, response}, req, new_state}
              end

            {:error, reason} ->
              Logger.warn("Falha ao decodificar mensagem WebSocket: #{inspect(reason)}", 
                         module: __MODULE__, user_id: state.user_id)

              # Envia resposta de erro
              response = Jason.encode!(%{type: "error", error: "Formato de mensagem inválido", code: "invalid_json"})
              {:reply, {:text, response}, req, new_state}
          end
          
        {:error, :rate_limit_exceeded, new_state} ->
          # Retorna erro de limite de taxa
          response = Jason.encode!(%{
            type: "error", 
            error: "Limite de mensagens excedido", 
            code: "rate_limit_exceeded",
            retry_after: trunc((60_000 - (:os.system_time(:millisecond) - new_state.last_reset)) / 1000)
          })
          {:reply, {:text, response}, req, new_state}
      end
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
    user_id = Map.get(state, :user_id)
    
    if user_id do
      Logger.info("Conexão WebSocket encerrada para o usuário: #{user_id}, motivo: #{inspect(reason)}",
                  module: __MODULE__)
      
      # Remove a conexão da tabela ETS
      table = :ets.whereis(:socket_connections)
      if table != :undefined do
        :ets.delete(:socket_connections, {user_id, self()})
      end
      
      # Cancela inscrições em canais ativos
      subscriptions = Map.get(state, :subscriptions, [])
      Enum.each(subscriptions, fn channel ->
        # Tenta cancelar a inscrição, mas ignora erros
        try do
          DeeperHub.Core.Network.Channels.unsubscribe(channel, user_id)
        catch
          _, _ -> :ok
        end
      end)
    end
    
    :ok
  end
  
  # Valida a estrutura da mensagem
  defp is_valid_message?(message) do
    cond do
      # Verifica se a mensagem é um mapa
      !is_map(message) ->
        false
        
      # Verifica se tem o campo 'type'
      !Map.has_key?(message, "type") ->
        false
        
      # Validações específicas por tipo de mensagem
      message["type"] == "ping" ->
        true
        
      message["type"] == "subscribe" ->
        is_binary(message["channel"]) && String.length(message["channel"]) <= 100
        
      message["type"] == "unsubscribe" ->
        is_binary(message["channel"]) && String.length(message["channel"]) <= 100
        
      message["type"] == "message" ->
        is_binary(message["channel"]) && 
        String.length(message["channel"]) <= 100 &&
        is_binary(message["content"]) && 
        String.length(message["content"]) <= 8192
        
      # Tipo de mensagem desconhecido
      true ->
        false
    end
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
    case Guardian.decode_and_verify(token) do
      {:ok, claims} ->
        # Verifica se é um token de acesso
        if claims["typ"] == "access" do
          # Extrai o ID do usuário do token
          {:ok, claims["sub"]}
        else
          Logger.warn("Tentativa de conexão WebSocket com token de tipo inválido: #{claims["typ"]}", module: __MODULE__)
          {:error, :invalid_token_type}
        end

      {:error, :token_expired} ->
        Logger.warn("Tentativa de conexão WebSocket com token expirado", module: __MODULE__)
        {:error, :token_expired}

      {:error, reason} ->
        Logger.warn("Falha na validação do token: #{inspect(reason)}", module: __MODULE__)
        {:error, :invalid_token}
    end
  end
  
  # Registra uma conexão na tabela ETS para rastreamento
  defp register_connection(user_id) do
    # Garante que a tabela ETS existe
    :ets.whereis(:socket_connections) || 
      :ets.new(:socket_connections, [:named_table, :set, :public])
      
    # Registra a conexão com timestamp
    connection_id = {user_id, self()}
    :ets.insert(:socket_connections, {connection_id, :os.system_time(:millisecond)})
  end
  
  # Conta o número de conexões ativas para um usuário
  defp count_user_connections(user_id) do
    table = :ets.whereis(:socket_connections)
    
    if table == :undefined do
      0
    else
      # Conta conexões com o pattern matching no ID do usuário
      :ets.select_count(table, [{{{user_id, :_}, :_}, [], [true]}])
    end
  end
  
  # Verifica e atualiza os limites de taxa para mensagens
  defp check_rate_limit(state) do
    current_time = :os.system_time(:millisecond)
    elapsed_ms = current_time - state.last_reset
    
    # Reseta o contador a cada minuto
    if elapsed_ms >= 60_000 do
      # Reseta o contador
      {:ok, %{state | message_count: 1, last_reset: current_time}}
    else
      # Incrementa o contador
      new_count = state.message_count + 1
      
      if new_count > @max_messages_per_minute do
        Logger.warn("Limite de taxa excedido para o usuário: #{state.user_id}", module: __MODULE__)
        {:error, :rate_limit_exceeded, %{state | message_count: new_count}}
      else
        {:ok, %{state | message_count: new_count}}
      end
    end
  end

  # Manipula diferentes tipos de mensagens
  defp handle_message(%{"type" => "ping"}, req, state) do
    # Responde com pong
    response = Jason.encode!(%{type: "pong", timestamp: :os.system_time(:millisecond)})
    {:reply, {:text, response}, req, state}
  end

  defp handle_message(%{"type" => "subscribe", "channel" => channel}, req, state) do
    # Verifica se o usuário já atingiu o limite de subscrições
    subscriptions = Map.get(state, :subscriptions, [])
    
    if length(subscriptions) >= @max_subscriptions do
      Logger.warn("Usuário #{state.user_id} atingiu o limite de subscrições: #{length(subscriptions)}/#{@max_subscriptions}", 
                 module: __MODULE__)
      
      response = Jason.encode!(%{
        type: "error", 
        error: "Limite de canais atingido", 
        code: "subscription_limit_exceeded",
        max_subscriptions: @max_subscriptions
      })
      
      {:reply, {:text, response}, req, state}
    else
      # Verifica se o usuário já está inscrito neste canal
      if Enum.member?(subscriptions, channel) do
        # Já está inscrito, retorna sucesso
        response = Jason.encode!(%{type: "subscribed", channel: channel, already_subscribed: true})
        {:reply, {:text, response}, req, state}
      else
        # Inscreve o usuário no canal
        case DeeperHub.Core.Network.Channels.subscribe(channel, state.user_id) do
          :ok ->
            # Adiciona o canal à lista de subscrições do usuário
            new_subscriptions = [channel | subscriptions]
            new_state = Map.put(state, :subscriptions, new_subscriptions)
            
            Logger.info("Usuário #{state.user_id} inscrito no canal: #{channel} (total: #{length(new_subscriptions)})", 
                        module: __MODULE__)
                        
            response = Jason.encode!(%{type: "subscribed", channel: channel})
            {:reply, {:text, response}, req, new_state}

          {:error, reason} ->
            Logger.warn("Falha ao inscrever usuário #{state.user_id} no canal: #{channel}, motivo: #{inspect(reason)}",
                      module: __MODULE__)
                      
            response = Jason.encode!(%{
              type: "error", 
              error: "Falha ao inscrever no canal", 
              code: "subscription_failed",
              reason: reason
            })
            
            {:reply, {:text, response}, req, state}
        end
      end
    end
  end

  defp handle_message(%{"type" => "unsubscribe", "channel" => channel}, req, state) do
    # Verifica se o usuário está inscrito neste canal
    subscriptions = Map.get(state, :subscriptions, [])
    
    if !Enum.member?(subscriptions, channel) do
      # Não está inscrito, retorna sucesso de qualquer forma
      response = Jason.encode!(%{type: "unsubscribed", channel: channel, already_unsubscribed: true})
      {:reply, {:text, response}, req, state}
    else
      # Cancela a inscrição do usuário no canal
      case DeeperHub.Core.Network.Channels.unsubscribe(channel, state.user_id) do
        :ok ->
          # Remove o canal da lista de subscrições do usuário
          new_subscriptions = Enum.reject(subscriptions, fn c -> c == channel end)
          new_state = Map.put(state, :subscriptions, new_subscriptions)
          
          Logger.info("Usuário #{state.user_id} desinscrito do canal: #{channel} (restantes: #{length(new_subscriptions)})", 
                      module: __MODULE__)
                      
          response = Jason.encode!(%{type: "unsubscribed", channel: channel})
          {:reply, {:text, response}, req, new_state}

        {:error, reason} ->
          Logger.warn("Falha ao desinscrever usuário #{state.user_id} do canal: #{channel}, motivo: #{inspect(reason)}",
                    module: __MODULE__)
                    
          response = Jason.encode!(%{
            type: "error", 
            error: "Falha ao desinscrever do canal", 
            code: "unsubscription_failed",
            reason: reason
          })
          
          {:reply, {:text, response}, req, state}
      end
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
