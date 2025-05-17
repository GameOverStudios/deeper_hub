defmodule Deeper_Hub.Core.WebSockets.WebSocketProtocol do
  @moduledoc """
  Implementação do protocolo WebSocket usando Ranch.
  
  Este módulo implementa o protocolo WebSocket sobre o Ranch,
  permitindo comunicação bidirecional em tempo real.
  """
  
  @behaviour :ranch_protocol
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.EventBus
  alias Deeper_Hub.Core.WebSockets.WebSocketListener
  
  # Timeout para operações de socket (5 segundos)
  @timeout 5000
  
  # Constantes para o protocolo WebSocket
  @ws_guid "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
  
  @doc """
  Inicia o protocolo WebSocket.
  
  ## Parâmetros
  
    - `ref`: Referência do listener
    - `transport`: Módulo de transporte
    - `opts`: Opções adicionais
  """
  def start_link(ref, transport, opts) do
    pid = spawn_link(__MODULE__, :init, [ref, transport, opts])
    {:ok, pid}
  end
  
  @doc """
  Inicializa o protocolo WebSocket.
  
  ## Parâmetros
  
    - `ref`: Referência do listener
    - `transport`: Módulo de transporte
    - `opts`: Opções adicionais
  """
  def init(ref, transport, _opts) do
    Logger.info("Iniciando protocolo WebSocket", %{module: __MODULE__})
    
    # Realiza o handshake com o cliente
    {:ok, socket} = :ranch.handshake(ref)
    
    # Processa o handshake do WebSocket
    case process_http_upgrade(socket, transport) do
      {:ok, headers, client_id} ->
        # Handshake bem-sucedido, inicia o loop de processamento de frames
        Logger.info("Handshake WebSocket bem-sucedido", %{
          module: __MODULE__,
          client_id: client_id,
          client: extract_client_info(socket, headers)
        })
        
        # Publica evento de conexão estabelecida
        EventBus.publish(:websocket_connected, %{
          client: client_id,
          timestamp: :os.system_time(:millisecond)
        })
        
        # Inicia o loop de processamento de frames
        websocket_loop(socket, transport, %{
          headers: headers,
          client_id: client_id,
          client: extract_client_info(socket, headers)
        })
        
      {:error, reason} ->
        # Falha no handshake, fecha a conexão
        Logger.error("Falha no handshake WebSocket", %{
          module: __MODULE__,
          reason: reason
        })
        
        transport.close(socket)
    end
  end
  
  # Processa o handshake HTTP para upgrade para WebSocket
  defp process_http_upgrade(socket, transport) do
    case transport.recv(socket, 0, @timeout) do
      {:ok, data} ->
        # Analisa o cabeçalho HTTP
        case parse_http_request(data) do
          {:ok, headers} ->
            # Verifica se é uma solicitação de upgrade para WebSocket
            if is_websocket_upgrade_request?(headers) do
              # Gera a resposta de handshake
              response = generate_handshake_response(headers)
              
              # Obtém o ID do cliente
              client_id = extract_client_id(headers)
              
              # Envia a resposta
              case transport.send(socket, response) do
                :ok ->
                  # Registra a conexão ativa
                  WebSocketListener.register_connection(client_id, socket, transport)
                  
                  {:ok, headers, client_id}
                
                error -> error
              end
            else
              {:error, :not_websocket_upgrade}
            end
            
          error -> error
        end
        
      error -> error
    end
  end
  
  # Verifica se a solicitação é um upgrade para WebSocket
  defp is_websocket_upgrade_request?(headers) do
    connection = Map.get(headers, "connection", "")
    upgrade = Map.get(headers, "upgrade", "")
    
    String.downcase(connection) =~ "upgrade" && 
    String.downcase(upgrade) =~ "websocket" &&
    Map.has_key?(headers, "sec-websocket-key")
  end
  
  # Gera a resposta de handshake para o WebSocket
  defp generate_handshake_response(headers) do
    # Obtém a chave do cliente
    key = Map.get(headers, "sec-websocket-key", "")
    
    # Gera a chave de aceitação
    accept = :crypto.hash(:sha, key <> @ws_guid) |> Base.encode64()
    
    # Constrói a resposta HTTP
    """
    HTTP/1.1 101 Switching Protocols\r
    Upgrade: websocket\r
    Connection: Upgrade\r
    Sec-WebSocket-Accept: #{accept}\r
    \r
    """
  end
  
  # Extrai o ID do cliente
  defp extract_client_id(_headers) do
    # Gera um ID único para o cliente
    # Poderia ser baseado em informações do cliente, como IP, user-agent, etc.
    "client_" <> UUID.uuid4()
  end
  
  # Extrai informações do cliente
  defp extract_client_info(socket, headers) do
    # Obtém o endereço IP e porta do cliente
    {:ok, {ip, port}} = :inet.peername(socket)
    
    # Formata o endereço IP
    ip_str = ip |> :inet.ntoa() |> to_string()
    
    # Obtém o user-agent
    user_agent = Map.get(headers, "user-agent", "unknown")
    
    # Obtém o host
    host = Map.get(headers, "host", "unknown")
    
    %{
      ip: ip_str,
      port: port,
      user_agent: user_agent,
      host: host
    }
  end
  
  # Loop principal do WebSocket
  defp websocket_loop(socket, transport, state) do
    case receive_frame(socket, transport) do
      {:ok, :ping, _} ->
        # Responde a um ping com um pong
        send_frame(socket, transport, :pong, "")
        websocket_loop(socket, transport, state)
        
      {:ok, :close, _} ->
        # Cliente solicitou fechamento, responde e fecha a conexão
        send_frame(socket, transport, :close, "")
        
        # Remove a conexão ativa
        WebSocketListener.unregister_connection(state.client_id, :client_close)
        
        transport.close(socket)
        
      {:ok, :text, payload} ->
        # Recebeu uma mensagem de texto
        handle_text_message(socket, transport, payload, state)
        websocket_loop(socket, transport, state)
        
      {:ok, :binary, payload} ->
        # Recebeu uma mensagem binária
        handle_binary_message(socket, transport, payload, state)
        websocket_loop(socket, transport, state)
        
      {:error, :timeout} ->
        # Timeout, continua o loop
        websocket_loop(socket, transport, state)
        
      {:error, :closed} ->
        # Conexão fechada pelo cliente sem frame de fechamento
        Logger.info("Conexão fechada pelo cliente sem frame de fechamento", %{
          module: __MODULE__,
          client_id: state.client_id
        })
        
        # Remove a conexão ativa
        WebSocketListener.unregister_connection(state.client_id, :client_close_abrupt)
        
        # Não tenta fechar o socket, pois já está fechado
        :ok
        
      {:error, reason} ->
        # Erro na conexão, fecha o socket
        Logger.error("Erro na conexão WebSocket", %{
          module: __MODULE__,
          client_id: state.client_id,
          reason: reason
        })
        
        # Remove a conexão ativa
        WebSocketListener.unregister_connection(state.client_id, {:error, reason})
        
        # Tenta fechar o socket, ignorando erros
        try do
          transport.close(socket)
        catch
          _, _ -> :ok
        end
        
        :ok
    end
  end
  
  # Manipula mensagens de texto recebidas
  defp handle_text_message(socket, transport, payload, state) do
    Logger.debug("Mensagem de texto recebida", %{
      module: __MODULE__,
      client_id: state.client_id,
      payload_size: byte_size(payload)
    })
    
    # Tenta decodificar como JSON
    case Jason.decode(payload) do
      {:ok, json} ->
        # Processa a mensagem JSON
        process_json_message(socket, transport, json, state)
        
      {:error, _} ->
        # Não é JSON válido, responde com erro
        error_response = Jason.encode!(%{
          error: "Invalid JSON format"
        })
        
        send_frame(socket, transport, :text, error_response)
    end
  end
  
  # Processa mensagens JSON
  defp process_json_message(socket, transport, json, state) do
    # Publica evento de mensagem recebida
    EventBus.publish(:websocket_message_received, %{
      client: state.client_id,
      message: json,
      timestamp: :os.system_time(:millisecond)
    })
    
    # Processa a mensagem com base no tipo
    case Map.get(json, "type") do
      "echo" ->
        # Simplesmente ecoa a mensagem de volta
        response = Jason.encode!(json)
        send_frame(socket, transport, :text, response)
        
      "subscribe" ->
        # Inscreve o cliente em um tópico
        topic = Map.get(json, "topic")
        
        if topic do
          # Adiciona o tópico ao estado do cliente
          # (Aqui você implementaria a lógica de inscrição)
          
          # Responde com confirmação
          response = Jason.encode!(%{
            type: "subscribed",
            topic: topic
          })
          
          send_frame(socket, transport, :text, response)
        else
          # Tópico não especificado
          error_response = Jason.encode!(%{
            error: "Topic not specified"
          })
          
          send_frame(socket, transport, :text, error_response)
        end
        
      _ ->
        # Tipo de mensagem desconhecido
        error_response = Jason.encode!(%{
          error: "Unknown message type"
        })
        
        send_frame(socket, transport, :text, error_response)
    end
  end
  
  # Manipula mensagens binárias recebidas
  defp handle_binary_message(_socket, _transport, payload, state) do
    Logger.debug("Mensagem binária recebida", %{
      module: __MODULE__,
      client_id: state.client_id,
      payload_size: byte_size(payload)
    })
    
    # Publica evento de mensagem binária recebida
    EventBus.publish(:websocket_binary_received, %{
      client: state.client,
      payload_size: byte_size(payload),
      timestamp: :os.system_time(:millisecond)
    })
    
    # Aqui você implementaria a lógica para processar mensagens binárias
    :ok
  end
  
  # Recebe um frame WebSocket
  defp receive_frame(socket, transport) do
    # Esta é uma implementação simplificada
    # Uma implementação completa precisaria lidar com fragmentação, mascaramento, etc.
    case transport.recv(socket, 2, @timeout) do
      {:ok, <<_fin::1, _rsv::3, opcode::4, mask::1, payload_len::7>>} ->
        # Determina o tamanho real do payload
        {payload_len, socket, transport} = case payload_len do
          126 ->
            # Payload de 16 bits
            {:ok, <<len::16>>} = transport.recv(socket, 2, @timeout)
            {len, socket, transport}
            
          127 ->
            # Payload de 64 bits
            {:ok, <<len::64>>} = transport.recv(socket, 8, @timeout)
            {len, socket, transport}
            
          len ->
            # Payload curto
            {len, socket, transport}
        end
        
        # Lê a máscara se presente
        {mask_key, socket, transport} = if mask == 1 do
          {:ok, mask_key} = transport.recv(socket, 4, @timeout)
          {mask_key, socket, transport}
        else
          {<<0, 0, 0, 0>>, socket, transport}
        end
        
        # Lê o payload
        case transport.recv(socket, payload_len, @timeout) do
          {:ok, payload} ->
            # Continua o processamento normal
            process_payload(payload, mask, mask_key, opcode)
            
          {:error, :closed} ->
            # Conexão fechada pelo cliente
            Logger.info("Conexão fechada pelo cliente", %{
              module: __MODULE__
            })
            {:error, :closed}
            
          {:error, reason} = error ->
            # Outro erro
            Logger.error("Erro ao receber payload", %{
              module: __MODULE__,
              reason: reason
            })
            error
        end
        
      # Erro no recebimento do cabeçalho
      {:error, reason} = error ->
        Logger.error("Erro ao receber cabeçalho do frame", %{
          module: __MODULE__,
          reason: reason
        })
        error
    end
  end
  
  # Processa o payload recebido
  defp process_payload(payload, mask, mask_key, opcode) do
    # Desmascara o payload se necessário
    payload = if mask == 1, do: unmask(payload, mask_key), else: payload
    
    # Determina o tipo de frame
    frame_type = case opcode do
      0x1 -> :text
      0x2 -> :binary
      0x8 -> :close
      0x9 -> :ping
      0xA -> :pong
      _ -> :unknown
    end
    
    {:ok, frame_type, payload}
  end
  
  @doc """
  Envia uma mensagem de texto para um cliente.
  
  ## Parâmetros
  
    - `socket`: O socket da conexão
    - `transport`: O módulo de transporte
    - `message`: A mensagem a ser enviada
  
  ## Retorno
  
    - `:ok` - Se a mensagem for enviada com sucesso
    - `{:error, reason}` - Se ocorrer um erro ao enviar a mensagem
  """
  def send_text(socket, transport, message) do
    try do
      send_frame(socket, transport, :text, message)
    rescue
      e in _ ->
        Logger.error("Erro ao enviar mensagem de texto", %{
          module: __MODULE__,
          error: e
        })
        {:error, e}
    end
  end
  
  @doc """
  Envia uma mensagem binária para um cliente.
  
  ## Parâmetros
  
    - `socket`: O socket da conexão
    - `transport`: O módulo de transporte
    - `data`: Os dados binários a serem enviados
  
  ## Retorno
  
    - `:ok` - Se a mensagem for enviada com sucesso
    - `{:error, reason}` - Se ocorrer um erro ao enviar a mensagem
  """
  def send_binary(socket, transport, data) do
    try do
      send_frame(socket, transport, :binary, data)
    rescue
      e in _ ->
        Logger.error("Erro ao enviar mensagem binária", %{
          module: __MODULE__,
          error: e
        })
        {:error, e}
    end
  end
  
  # Envia um frame WebSocket
  defp send_frame(socket, transport, type, payload) do
    # Determina o opcode com base no tipo
    opcode = case type do
      :text -> 0x1
      :binary -> 0x2
      :close -> 0x8
      :ping -> 0x9
      :pong -> 0xA
      _ -> 0x1 # Padrão para texto
    end
    
    # Determina o tamanho do payload
    payload_len = byte_size(payload)
    
    # Constrói o cabeçalho do frame
    header = if payload_len < 126 do
      <<1::1, 0::3, opcode::4, 0::1, payload_len::7>>
    else
      if payload_len < 65536 do
        <<1::1, 0::3, opcode::4, 0::1, 126::7, payload_len::16>>
      else
        <<1::1, 0::3, opcode::4, 0::1, 127::7, payload_len::64>>
      end
    end
    
    # Envia o frame
    transport.send(socket, [header, payload])
  end
  
  # Desmascara o payload
  defp unmask(payload, mask_key) do
    unmask(payload, mask_key, 0, <<>>)
  end
  
  defp unmask(<<>>, _mask_key, _i, acc) do
    acc
  end
  
  defp unmask(<<byte::8, rest::binary>>, mask_key, i, acc) do
    mask_byte = :binary.at(mask_key, rem(i, 4))
    unmasked_byte = Bitwise.bxor(byte, mask_byte)
    unmask(rest, mask_key, i + 1, <<acc::binary, unmasked_byte::8>>)
  end
  
  # Analisa uma solicitação HTTP
  defp parse_http_request(data) do
    # Divide a solicitação em linhas
    lines = String.split(data, "\r\n")
    
    # Analisa as linhas de cabeçalho
    headers = Enum.reduce(tl(lines), %{}, fn line, acc ->
      case String.split(line, ": ", parts: 2) do
        [key, value] -> Map.put(acc, String.downcase(key), value)
        _ -> acc
      end
    end)
    
    {:ok, headers}
  end
end
