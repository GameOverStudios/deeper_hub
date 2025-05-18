defmodule DeeperHub.Core.Network.Socket.HealthHandler do
  @moduledoc """
  Handler HTTP para verificação de saúde do servidor WebSocket.
  
  Este módulo implementa um endpoint simples para verificação de saúde
  do servidor WebSocket, permitindo monitoramento e verificações de
  disponibilidade.
  """
  
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  
  @doc """
  Inicializa o handler de verificação de saúde.
  """
  def init(req, state) do
    {:cowboy_rest, req, state}
  end
  
  @doc """
  Processa uma requisição GET para o endpoint de saúde.
  """
  def handle(req, state) do
    Logger.debug("Requisição de verificação de saúde recebida", module: __MODULE__)
    
    # Obtém estatísticas do servidor WebSocket
    stats = 
      try do
        DeeperHub.Core.Network.Socket.Server.stats()
      rescue
        _ -> %{status: "unavailable"}
      end
    
    # Adiciona informações de tempo
    stats = Map.put(stats, :timestamp, DateTime.utc_now() |> DateTime.to_iso8601())
    stats = Map.put(stats, :status, "online")
    
    # Codifica as estatísticas como JSON
    body = Jason.encode!(stats)
    
    # Define os cabeçalhos da resposta
    headers = %{
      "content-type" => "application/json",
      "cache-control" => "no-cache, no-store, must-revalidate",
      "pragma" => "no-cache",
      "expires" => "0"
    }
    
    # Envia a resposta
    req = :cowboy_req.reply(200, headers, body, req)
    {:ok, req, state}
  end
end
