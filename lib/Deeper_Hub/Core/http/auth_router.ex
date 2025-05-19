defmodule DeeperHub.Core.HTTP.AuthRouter do
  @moduledoc """
  Router para as rotas de autenticação do DeeperHub.
  
  Este módulo define as rotas relacionadas à autenticação de usuários,
  como login, registro e gerenciamento de tokens.
  """
  
  use Plug.Router
  
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  alias DeeperHub.Accounts.Auth
  
  # Plugs que são executados para todas as requisições
  plug :match
  
  # Plug que executa a função de roteamento
  plug :dispatch
  
  # Rota para registro de usuário
  post "/register" do
    case conn.body_params do
      %{"username" => username, "email" => email, "password" => password} = params ->
        # Cria um mapa com as chaves como átomos para o Auth.register_user
        user_params = %{
          username: username,
          email: email,
          password: password,
          full_name: Map.get(params, "full_name", ""),
          bio: Map.get(params, "bio", ""),
          avatar_url: Map.get(params, "avatar_url", "")
        }
        
        case Auth.register_user(user_params) do
          {:ok, user} ->
            # Remove o campo password_hash da resposta
            user_without_password = Map.drop(user, ["password_hash"])
            
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(201, Jason.encode!(%{
              message: "Usuário registrado com sucesso",
              user: user_without_password
            }))
            
          {:error, {:missing_fields, fields}} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(400, Jason.encode!(%{
              error: "Campos obrigatórios ausentes",
              code: "missing_fields",
              fields: Enum.map(fields, &Atom.to_string/1)
            }))
            
          {:error, :invalid_email} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(400, Jason.encode!(%{
              error: "Formato de email inválido",
              code: "invalid_email"
            }))
            
          {:error, :password_too_short} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(400, Jason.encode!(%{
              error: "Senha muito curta, mínimo de 8 caracteres",
              code: "password_too_short"
            }))
            
          {:error, :password_needs_uppercase} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(400, Jason.encode!(%{
              error: "A senha deve conter pelo menos uma letra maiúscula",
              code: "password_needs_uppercase"
            }))
            
          {:error, :password_needs_lowercase} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(400, Jason.encode!(%{
              error: "A senha deve conter pelo menos uma letra minúscula",
              code: "password_needs_lowercase"
            }))
            
          {:error, :password_needs_number} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(400, Jason.encode!(%{
              error: "A senha deve conter pelo menos um número",
              code: "password_needs_number"
            }))
            
          {:error, :password_needs_special_char} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(400, Jason.encode!(%{
              error: "A senha deve conter pelo menos um caractere especial",
              code: "password_needs_special_char"
            }))
            
          {:error, reason} ->
            Logger.error("Erro ao registrar usuário: #{inspect(reason)}", module: __MODULE__)
            
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(500, Jason.encode!(%{
              error: "Erro interno ao registrar usuário",
              code: "internal_error"
            }))
        end
        
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{
          error: "Parâmetros inválidos. Esperado: username, email, password",
          code: "invalid_parameters"
        }))
    end
  end
  
  # Rota para login de usuário
  post "/login" do
    case conn.body_params do
      %{"email" => email, "password" => password} ->
        case Auth.authenticate_user(email, password) do
          {:ok, user} ->
            case Auth.generate_tokens(user) do
              {:ok, tokens} ->
                conn
                |> put_resp_content_type("application/json")
                |> send_resp(200, Jason.encode!(%{
                  message: "Login realizado com sucesso",
                  user_id: user["id"],
                  tokens: tokens
                }))
                
              {:error, reason} ->
                Logger.error("Erro ao gerar tokens: #{inspect(reason)}", module: __MODULE__)
                
                conn
                |> put_resp_content_type("application/json")
                |> send_resp(500, Jason.encode!(%{
                  error: "Erro ao gerar tokens",
                  code: "token_generation_failed"
                }))
            end
            
          {:error, :invalid_credentials} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(401, Jason.encode!(%{
              error: "Credenciais inválidas",
              code: "invalid_credentials"
            }))
            
          {:error, reason} ->
            Logger.error("Erro ao autenticar usuário: #{inspect(reason)}", module: __MODULE__)
            
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(500, Jason.encode!(%{
              error: "Erro interno ao autenticar usuário",
              code: "internal_error"
            }))
        end
        
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{
          error: "Parâmetros inválidos. Esperado: email, password",
          code: "invalid_parameters"
        }))
    end
  end
  
  # Rota para atualização de token
  post "/refresh" do
    case conn.body_params do
      %{"refresh_token" => refresh_token} ->
        case Auth.refresh_tokens(refresh_token) do
          {:ok, tokens} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{
              message: "Tokens atualizados com sucesso",
              tokens: tokens
            }))
            
          {:error, :invalid_token} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(401, Jason.encode!(%{
              error: "Token de atualização inválido",
              code: "invalid_refresh_token"
            }))
            
          {:error, reason} ->
            Logger.error("Erro ao atualizar tokens: #{inspect(reason)}", module: __MODULE__)
            
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(500, Jason.encode!(%{
              error: "Erro interno ao atualizar tokens",
              code: "internal_error"
            }))
        end
        
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{
          error: "Parâmetros inválidos. Esperado: refresh_token",
          code: "invalid_parameters"
        }))
    end
  end
  
  # Rota para revogação de token
  post "/revoke" do
    case conn.body_params do
      %{"token" => token} ->
        case Auth.revoke_token(token) do
          :ok ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{
              message: "Token revogado com sucesso"
            }))
            
          {:error, reason} ->
            Logger.error("Erro ao revogar token: #{inspect(reason)}", module: __MODULE__)
            
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(500, Jason.encode!(%{
              error: "Erro interno ao revogar token",
              code: "internal_error"
            }))
        end
        
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{
          error: "Parâmetros inválidos. Esperado: token",
          code: "invalid_parameters"
        }))
    end
  end
  
  # Rota padrão para requisições não correspondentes
  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{
      error: "Rota de autenticação não encontrada",
      code: "auth_route_not_found"
    }))
  end
end
