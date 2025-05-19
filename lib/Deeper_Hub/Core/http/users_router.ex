defmodule DeeperHub.Core.HTTP.UsersRouter do
  @moduledoc """
  Router para as rotas de usuários do DeeperHub.
  
  Este módulo define as rotas relacionadas ao gerenciamento de usuários,
  como obtenção de perfil, atualização de dados e listagem de usuários.
  """
  
  use Plug.Router
  
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  alias DeeperHub.Accounts.User
  
  # Plugs que são executados para todas as requisições
  plug :match
  
  # Plug que executa a função de roteamento
  plug :dispatch
  
  # Rota para obter informações do usuário atual (autenticado)
  get "/me" do
    # Aqui seria implementada a lógica para obter o usuário autenticado
    # usando o token JWT do cabeçalho de autorização
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{
      message: "Endpoint em implementação",
      code: "not_implemented_yet"
    }))
  end
  
  # Rota para obter informações de um usuário específico
  get "/:id" do
    case User.get(id) do
      {:ok, user} ->
        # Remove informações sensíveis
        user_safe = Map.drop(user, ["password_hash"])
        
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(user_safe))
        
      {:error, :not_found} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{
          error: "Usuário não encontrado",
          code: "user_not_found"
        }))
        
      {:error, reason} ->
        Logger.error("Erro ao buscar usuário: #{inspect(reason)}", module: __MODULE__)
        
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{
          error: "Erro interno ao buscar usuário",
          code: "internal_error"
        }))
    end
  end
  
  # Rota para atualizar informações do usuário
  put "/:id" do
    # Aqui seria implementada a lógica para atualizar o usuário
    # verificando se o usuário autenticado tem permissão para isso
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{
      message: "Endpoint em implementação",
      code: "not_implemented_yet"
    }))
  end
  
  # Rota padrão para requisições não correspondentes
  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{
      error: "Rota de usuário não encontrada",
      code: "user_route_not_found"
    }))
  end
end
