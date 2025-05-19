defmodule DeeperHub.Core.HTTP.APIRouter do
  @moduledoc """
  Router para as rotas de API do DeeperHub.

  Este módulo define as rotas de API da aplicação, organizadas por recursos.
  """

  use Plug.Router

  require DeeperHub.Core.Logger

  # Plugs que são executados para todas as requisições
  plug :match

  # Plug que executa a função de roteamento
  plug :dispatch

  # Rotas de autenticação
  forward "/auth", to: DeeperHub.Core.HTTP.AuthRouter

  # Rotas de usuários
  forward "/users", to: DeeperHub.Core.HTTP.UsersRouter

  # Rotas de canais
  forward "/channels", to: DeeperHub.Core.HTTP.ChannelsRouter

  # Rota padrão para requisições não correspondentes
  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{error: "Recurso de API não encontrado", code: "api_not_found"}))
  end
end
