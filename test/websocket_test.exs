#!/usr/bin/env elixir

# Script para testar o servidor WebSocket do DeeperHub
# Execute com: elixir websocket_test.exs

# Carrega as dependências necessárias
Mix.install([
  {:jason, "~> 1.4"}
])

# Não precisamos importar o módulo Bitwise, usaremos Bitwise.bxor diretamente

defmodule WebSocketTest do
  @moduledoc """
  Módulo para testar o servidor WebSocket do DeeperHub.
  
  Este script se conecta ao servidor WebSocket, envia algumas mensagens
  e exibe as respostas recebidas.
  """
  
  @doc """
  Inicia o teste do WebSocket.
  """
  def run do
    IO.puts("Iniciando teste do WebSocket...")
    
    # Conecta ao servidor WebSocket
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 8080, [:binary, active: false, packet: :raw])
    IO.puts("Conectado ao servidor WebSocket")
    
    # Envia o handshake HTTP para upgrade para WebSocket
    handshake = generate_handshake()
    :ok = :gen_tcp.send(socket, handshake)
    IO.puts("Handshake enviado")
    
    # Recebe a resposta do handshake
    {:ok, response} = :gen_tcp.recv(socket, 0, 5000)
    IO.puts("Resposta do handshake recebida:")
    IO.puts(response)
    
    # Verifica se o handshake foi bem-sucedido
    if String.contains?(response, "101 Switching Protocols") do
      IO.puts("Handshake bem-sucedido, conexão WebSocket estabelecida")
      
      # Envia uma mensagem de teste
      message = %{type: "echo", data: %{message: "Olá, servidor!"}}
      send_websocket_message(socket, Jason.encode!(message))
      IO.puts("Mensagem enviada: #{inspect(message)}")
      
      # Recebe a resposta
      {:ok, frame} = recv_websocket_frame(socket)
      IO.puts("Resposta recebida: #{inspect(frame)}")
      
      # Fecha a conexão
      send_close_frame(socket)
      IO.puts("Frame de fechamento enviado")
      
      # Tenta receber o frame de fechamento de resposta com timeout reduzido
      case recv_websocket_frame(socket, 2000) do
        {:ok, close_frame} ->
          IO.puts("Frame de fechamento recebido: #{inspect(close_frame)}")
        {:error, :timeout} ->
          IO.puts("Timeout ao esperar frame de fechamento - isso é normal em alguns servidores")
      end
      
      :gen_tcp.close(socket)
      IO.puts("Conexão fechada")
    else
      IO.puts("Falha no handshake")
      :gen_tcp.close(socket)
    end
  end
  
  # Gera o handshake HTTP para upgrade para WebSocket
  defp generate_handshake do
    key = :crypto.strong_rand_bytes(16) |> Base.encode64()
    
    """
    GET / HTTP/1.1\r
    Host: localhost:8080\r
    Upgrade: websocket\r
    Connection: Upgrade\r
    Sec-WebSocket-Key: #{key}\r
    Sec-WebSocket-Version: 13\r
    Origin: http://localhost\r
    \r
    """
  end
  
  # Envia uma mensagem WebSocket
  defp send_websocket_message(socket, message) do
    # Constrói o frame WebSocket
    frame = build_websocket_frame(message, :text)
    :gen_tcp.send(socket, frame)
  end
  
  # Envia um frame de fechamento
  defp send_close_frame(socket) do
    frame = build_websocket_frame("", :close)
    :gen_tcp.send(socket, frame)
  end
  
  # Constrói um frame WebSocket
  defp build_websocket_frame(payload, type) do
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
    
    # Retorna o frame completo
    header <> payload
  end
  
  # Recebe um frame WebSocket
  defp recv_websocket_frame(socket, timeout \\ 5000) do
    # Recebe o cabeçalho do frame (2 bytes)
    case :gen_tcp.recv(socket, 2, timeout) do
      {:ok, <<_fin::1, _rsv::3, opcode::4, mask::1, payload_len::7>>} ->
    
        # Determina o tamanho real do payload
        {real_payload_len, socket} = case payload_len do
          126 ->
            # Payload de 16 bits
            {:ok, <<len::16>>} = :gen_tcp.recv(socket, 2, timeout)
            {len, socket}
            
          127 ->
            # Payload de 64 bits
            {:ok, <<len::64>>} = :gen_tcp.recv(socket, 8, timeout)
            {len, socket}
            
          _ ->
            # Payload de 7 bits
            {payload_len, socket}
        end
    
        # Lê a máscara se presente
        {mask_key, socket} = if mask == 1 do
          {:ok, mask_key} = :gen_tcp.recv(socket, 4, timeout)
          {mask_key, socket}
        else
          {nil, socket}
        end
        
        # Lê o payload
        {:ok, payload} = :gen_tcp.recv(socket, real_payload_len, timeout)
    
        # Desmascara o payload se necessário
        unmasked_payload = if mask == 1 do
          unmask_payload(payload, mask_key)
        else
          payload
        end
        
        # Imprime o payload para debug
        IO.puts("Payload recebido: #{inspect(unmasked_payload)}")
        
        # Determina o tipo de frame
        frame_type = case opcode do
          0x1 -> :text
          0x2 -> :binary
          0x8 -> :close
          0x9 -> :ping
          0xA -> :pong
          _ -> :unknown
        end
        
        # Se for um frame de texto, decodifica como JSON
        decoded_payload = if frame_type == :text do
          case Jason.decode(unmasked_payload) do
            {:ok, json} -> 
              IO.puts("JSON decodificado com sucesso: #{inspect(json)}")
              json
            {:error, reason} -> 
              IO.puts("Erro ao decodificar JSON: #{inspect(reason)}")
              unmasked_payload
          end
        else
          unmasked_payload
        end
        
        {:ok, %{type: frame_type, payload: decoded_payload}}
        
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # Desmascara o payload
  defp unmask_payload(payload, mask_key) do
    unmask_payload(payload, mask_key, 0, <<>>)
  end
  
  defp unmask_payload(<<>>, _mask_key, _i, acc) do
    acc
  end
  
  defp unmask_payload(<<byte::8, rest::binary>>, mask_key, i, acc) do
    mask_byte = :binary.at(mask_key, rem(i, 4))
    unmasked_byte = Bitwise.bxor(byte, mask_byte)
    unmask_payload(rest, mask_key, i + 1, <<acc::binary, unmasked_byte::8>>)
  end
end

# Executa o teste
WebSocketTest.run()
