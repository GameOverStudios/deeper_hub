defmodule DeeperHub.WebInterface.Resources.RoutesResource do
  @moduledoc """
  Recurso que lista todas as rotas disponíveis na API.
  Este módulo é responsável por fornecer documentação sobre os endpoints da API.
  """
  use Plug.Router
  plug(:match)
  plug(:dispatch)

  get "/" do
    # Lista de todas as rotas disponíveis
    rotas = [
      %{
        caminho: "/",
        metodo: "GET",
        descricao: "Página inicial da API"
      },
      %{
        caminho: "/api",
        metodo: "GET",
        descricao: "Informações sobre a API"
      },
      %{
        caminho: "/api/status",
        metodo: "GET",
        descricao: "Status do sistema"
      },
      %{
        caminho: "/api/info",
        metodo: "GET",
        descricao: "Informações detalhadas do servidor"
      },
      %{
        caminho: "/api/routes",
        metodo: "GET",
        descricao: "Lista de todas as rotas disponíveis"
      }
    ]

    # Formatação da resposta
    resposta = %{
      api: "DeeperHub API v1",
      total_rotas: length(rotas),
      rotas: rotas
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(resposta))
  end

  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{erro: "Recurso não encontrado"}))
  end
end
