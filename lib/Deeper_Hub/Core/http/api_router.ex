defmodule DeeperHub.Core.HTTP.APIRouter do
  @moduledoc """
  Router para as rotas de API do DeeperHub.

  Este módulo define as rotas de API da aplicação, organizadas por recursos.
  Todas as rotas, exceto as de autenticação, exigem um token JWT válido.
  """

  use Plug.Router

  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  alias DeeperHub.Core.Security.AuthPlug

  # Plugs que são executados para todas as requisições
  plug :match

  # Plug que executa a função de roteamento
  plug :dispatch

  # Rotas de autenticação (não requerem token)
  forward "/auth", to: DeeperHub.Core.HTTP.AuthRouter

  # Plug de autenticação para verificar se a rota requer autenticação
  defp authenticate_protected_routes(conn, _opts) do
    path = conn.path_info

    # Verifica se a rota é protegida
    needs_auth = case path do
      ["users" | _] -> true
      ["channels" | _] -> true
      _ -> false
    end

    if needs_auth do
      # Aplica o plug de autenticação
      AuthPlug.call(conn, AuthPlug.init(required: true))
    else
      conn
    end
  end

  # Aplica o plug de autenticação para todas as rotas
  plug :authenticate_protected_routes

  # Rotas de usuários (requerem autenticação)
  forward "/users", to: DeeperHub.Core.HTTP.UsersRouter

  # Rotas de canais (requerem autenticação)
  forward "/channels", to: DeeperHub.Core.HTTP.ChannelsRouter

  # Rota padrão para requisições não correspondentes
  match _ do
    Logger.debug("Rota de API não encontrada: #{conn.request_path}",
                module: __MODULE__,
                method: conn.method)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{error: "Rota não encontrada", code: "api_route_not_found"}))
  end
end
