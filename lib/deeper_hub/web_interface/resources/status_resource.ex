defmodule DeeperHub.WebInterface.Resources.StatusResource do
  @moduledoc """
  Recurso que fornece informações sobre o status do sistema.
  """
  use Plug.Router
  plug :match
  plug :dispatch
  
  get "/" do
    status_info = %{
      nome: "DeeperHub",
      status: "operacional",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
    
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(status_info))
  end
  
  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{erro: "Recurso não encontrado"}))
  end
end
