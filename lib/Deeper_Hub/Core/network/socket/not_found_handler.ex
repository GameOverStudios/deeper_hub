defmodule DeeperHub.Core.Network.Socket.NotFoundHandler do
  @moduledoc """
  Handler HTTP para rotas não encontradas no servidor WebSocket.
  
  Este módulo implementa um handler para requisições HTTP que não correspondem
  a nenhuma rota configurada, retornando uma resposta 404 adequada.
  """
  
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  
  @doc """
  Inicializa o handler de rotas não encontradas.
  """
  def init(req, state) do
    {:cowboy_rest, req, state}
  end
  
  @doc """
  Processa uma requisição para uma rota não encontrada.
  """
  def handle(req, state) do
    path = :cowboy_req.path(req)
    method = :cowboy_req.method(req)
    
    Logger.debug("Requisição não encontrada: #{method} #{path}", module: __MODULE__)
    
    # Prepara a resposta de erro
    response = %{
      status: "error",
      code: 404,
      message: "Rota não encontrada",
      path: path,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
    
    # Codifica a resposta como JSON
    body = Jason.encode!(response)
    
    # Define os cabeçalhos da resposta
    headers = %{
      "content-type" => "application/json",
      "cache-control" => "no-cache, no-store, must-revalidate"
    }
    
    # Envia a resposta
    req = :cowboy_req.reply(404, headers, body, req)
    {:ok, req, state}
  end
end
