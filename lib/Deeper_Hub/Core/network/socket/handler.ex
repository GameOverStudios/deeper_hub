defmodule DeeperHub.Core.Network.Socket.Handler do
  @moduledoc """
  Handler WebSocket para o servidor Cowboy.

  Este módulo implementa o comportamento de handler WebSocket do Cowboy,
  gerenciando o ciclo de vida das conexões WebSocket e integrando com o
  sistema de conexões do DeeperHub.

  Foi projetado para alta performance, lidando eficientemente com um grande
  número de conexões simultâneas.
  """

  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Network.Socket.Connection

  # Implementação do comportamento :cowboy_websocket

  @doc """
  Inicializa uma nova conexão WebSocket.

  Esta função é chamada pelo Cowboy quando uma nova conexão WebSocket é estabelecida.
  """
  def init(req, state) do
    Logger.debug("Nova conexão WebSocket recebida", module: __MODULE__)

    # Extrai informações da requisição
    headers = :cowboy_req.headers(req)
    query_params = :cowboy_req.parse_qs(req)

    # Configura o timeout para a conexão WebSocket (30 minutos)
    # Isso permite conexões de longa duração sem timeout prematuro
    timeout = 30 * 60 * 1000

    # Configura o tamanho máximo de mensagem (1MB)
    max_frame_size = 1024 * 1024

    # Inicia o processo de conexão
    {:ok, pid} = DynamicSupervisor.start_child(
      DeeperHub.Core.Network.Socket.ConnectionSupervisor,
      {Connection, [req, [metadata: %{headers: headers, query_params: query_params}]]}
    )

    # Armazena o PID do processo de conexão no estado
    state = Map.put(state, :connection_pid, pid)

    # Informa ao Cowboy que esta é uma conexão WebSocket
    {:cowboy_websocket, req, state, %{idle_timeout: timeout, max_frame_size: max_frame_size}}
  end

  @doc """
  Coordena mensagens WebSocket recebidas.

  Esta função é chamada pelo Cowboy quando uma mensagem WebSocket é recebida.
  """
  def websocket_handle({:text, message}, state) do
    Logger.debug("Mensagem WebSocket recebida: #{inspect(message)}", module: __MODULE__)

    # Encaminha a mensagem para o processo de conexão
    if pid = state[:connection_pid] do
      send(pid, {:websocket_message, message})
    end

    {:ok, state}
  end

  def websocket_handle({:binary, message}, state) do
    Logger.debug("Mensagem binária WebSocket recebida: #{byte_size(message)} bytes", module: __MODULE__)

    # Encaminha a mensagem para o processo de conexão
    if pid = state[:connection_pid] do
      send(pid, {:websocket_message, {:binary, message}})
    end

    {:ok, state}
  end

  def websocket_handle({:ping, _data}, state) do
    # Responde automaticamente a pings com pongs
    {:ok, state}
  end

  def websocket_handle(frame, state) do
    Logger.debug("Frame WebSocket não tratado: #{inspect(frame)}", module: __MODULE__)
    {:ok, state}
  end

  @doc """
  Coordena mensagens Erlang enviadas para o processo do handler.

  Esta função é chamada quando uma mensagem Erlang é enviada para o processo
  do handler WebSocket.
  """
  def websocket_info({:send, message}, state) when is_binary(message) do
    # Envia uma mensagem de texto para o cliente
    {:reply, {:text, message}, state}
  end

  def websocket_info({:send, message}, state) do
    # Codifica a mensagem como JSON e envia para o cliente
    json = Jason.encode!(message)
    {:reply, {:text, json}, state}
  end

  def websocket_info({:send_binary, message}, state) when is_binary(message) do
    # Envia uma mensagem binária para o cliente
    {:reply, {:binary, message}, state}
  end

  def websocket_info({:close, reason}, state) do
    # Fecha a conexão WebSocket
    Logger.debug("Fechando conexão WebSocket: #{inspect(reason)}", module: __MODULE__)
    {:reply, {:close, 1000, to_string(reason)}, state}
  end

  def websocket_info(info, state) do
    Logger.debug("Mensagem Erlang não tratada: #{inspect(info)}", module: __MODULE__)
    {:ok, state}
  end

  @doc """
  Coordena o término da conexão WebSocket.

  Esta função é chamada quando a conexão WebSocket é encerrada.
  """
  def terminate(reason, _req, state) do
    Logger.debug("Conexão WebSocket terminada: #{inspect(reason)}", module: __MODULE__)

    # Notifica o processo de conexão sobre o término
    if pid = state[:connection_pid] do
      send(pid, {:websocket_close, reason})
    end

    :ok
  end
end
