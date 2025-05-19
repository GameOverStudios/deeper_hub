defmodule DeeperHub.WebInterface.Controllers.EmailVerificationController do
  @moduledoc """
  Controlador para verificação de e-mail.

  Este controlador fornece endpoints para solicitar, verificar e reenviar
  verificações de e-mail para usuários.
  """

  alias DeeperHub.Accounts.Auth.EmailVerification
  alias DeeperHub.WebInterface.Plugs.JsonResponse
  require DeeperHub.Core.Logger

  @doc """
  Endpoint para solicitar verificação de e-mail.

  ## Parâmetros
    * `conn` - Conexão Plug
    * `params` - Parâmetros da requisição:
      * `email` - Email a ser verificado (opcional, usa o email do usuário autenticado se não fornecido)

  ## Retorno
    * `200 OK` - Solicitação enviada com sucesso
    * `401 Unauthorized` - Usuário não autenticado
    * `500 Internal Server Error` - Erro interno
  """
  def request_verification(conn, params) do
    # Obtém o usuário autenticado do contexto da requisição
    case conn.assigns[:current_user] do
      nil ->
        conn
        |> JsonResponse.json_unauthorized(%{
          error: "unauthorized",
          message: "Usuário não autenticado"
        })

      user ->
        # Obtém o e-mail a ser verificado (usa o do usuário se não fornecido)
        email = Map.get(params, "email", user["email"])

        # Obtém informações do cliente
        ip_address = conn.remote_ip |> Tuple.to_list() |> Enum.join(".")

        # Tenta solicitar a verificação
        case EmailVerification.request_verification(user["id"], email, ip_address) do
          {:ok, _token} ->
            conn
            |> JsonResponse.json_ok(%{
              success: true,
              message: "E-mail de verificação enviado com sucesso. Por favor, verifique sua caixa de entrada."
            })

          {:error, _reason} ->
            conn
            |> JsonResponse.json_server_error(%{
              error: "server_error",
              message: "Erro ao enviar e-mail de verificação. Tente novamente mais tarde."
            })
        end
    end
  end

  @doc """
  Endpoint para verificar um token de verificação de e-mail.

  ## Parâmetros
    * `conn` - Conexão Plug
    * `params` - Parâmetros da requisição:
      * `token` - Token de verificação

  ## Retorno
    * `200 OK` - E-mail verificado com sucesso
    * `400 Bad Request` - Parâmetros inválidos
    * `401 Unauthorized` - Token inválido ou expirado
    * `500 Internal Server Error` - Erro interno
  """
  def verify_email(conn, params) do
    # Extrai parâmetros
    token = Map.get(params, "token")

    # Valida parâmetros obrigatórios
    if is_nil(token) do
      conn
      |> JsonResponse.json_bad_request(%{
        error: "missing_parameters",
        message: "Token de verificação é obrigatório"
      })
    else
      # Obtém informações do cliente
      ip_address = conn.remote_ip |> Tuple.to_list() |> Enum.join(".")

      # Tenta verificar o token
      case EmailVerification.verify_token(token, ip_address) do
        {:ok, _user_id, email} ->
          conn
          |> JsonResponse.json_ok(%{
            success: true,
            message: "E-mail #{email} verificado com sucesso.",
            email: email
          })

        {:error, :token_expired} ->
          conn
          |> JsonResponse.json_unauthorized(%{
            error: "token_expired",
            message: "O token de verificação expirou. Por favor, solicite um novo."
          })

        {:error, :token_not_found} ->
          conn
          |> JsonResponse.json_unauthorized(%{
            error: "token_not_found",
            message: "Token de verificação inválido ou já utilizado."
          })

        {:error, _reason} ->
          conn
          |> JsonResponse.json_server_error(%{
            error: "server_error",
            message: "Erro ao verificar e-mail. Tente novamente mais tarde."
          })
      end
    end
  end

  @doc """
  Endpoint para reenviar e-mail de verificação.

  ## Parâmetros
    * `conn` - Conexão Plug
    * `params` - Parâmetros da requisição:
      * `email` - Email para o qual reenviar a verificação

  ## Retorno
    * `200 OK` - E-mail reenviado com sucesso
    * `400 Bad Request` - Parâmetros inválidos
    * `401 Unauthorized` - Usuário não autenticado
    * `500 Internal Server Error` - Erro interno
  """
  def resend_verification(conn, params) do
    # Extrai parâmetros
    email = Map.get(params, "email")

    # Valida parâmetros obrigatórios
    if is_nil(email) do
      conn
      |> JsonResponse.json_bad_request(%{
        error: "missing_parameters",
        message: "E-mail é obrigatório"
      })
    else
      # Obtém o usuário autenticado do contexto da requisição
      case conn.assigns[:current_user] do
        nil ->
          conn
          |> JsonResponse.json_unauthorized(%{
            error: "unauthorized",
            message: "Usuário não autenticado"
          })

        user ->
          # Obtém informações do cliente
          ip_address = conn.remote_ip |> Tuple.to_list() |> Enum.join(".")

          # Tenta reenviar a verificação
          case EmailVerification.resend_verification(user["id"], email, ip_address) do
            {:ok, _token} ->
              conn
              |> JsonResponse.json_ok(%{
                success: true,
                message: "E-mail de verificação reenviado com sucesso. Por favor, verifique sua caixa de entrada."
              })

            {:error, _reason} ->
              conn
              |> JsonResponse.json_server_error(%{
                error: "server_error",
                message: "Erro ao reenviar e-mail de verificação. Tente novamente mais tarde."
              })
          end
      end
    end
  end

  @doc """
  Endpoint para verificar o status de verificação de um e-mail.

  ## Parâmetros
    * `conn` - Conexão Plug
    * `params` - Parâmetros da requisição:
      * `email` - Email a ser verificado (opcional, usa o email do usuário autenticado se não fornecido)

  ## Retorno
    * `200 OK` - Retorna o status de verificação
    * `401 Unauthorized` - Usuário não autenticado
    * `500 Internal Server Error` - Erro interno
  """
  def check_verification_status(conn, params) do
    # Obtém o usuário autenticado do contexto da requisição
    case conn.assigns[:current_user] do
      nil ->
        conn
        |> JsonResponse.json_unauthorized(%{
          error: "unauthorized",
          message: "Usuário não autenticado"
        })

      user ->
        # Obtém o e-mail a ser verificado (usa o do usuário se não fornecido)
        email = Map.get(params, "email", user["email"])

        # Verifica o status
        case EmailVerification.is_verified?(user["id"], email) do
          {:ok, is_verified} ->
            conn
            |> JsonResponse.json_ok(%{
              email: email,
              verified: is_verified
            })

          {:error, :user_not_found} ->
            conn
            |> JsonResponse.json_not_found(%{
              error: "user_not_found",
              message: "Usuário ou e-mail não encontrado"
            })

          {:error, _reason} ->
            conn
            |> JsonResponse.json_server_error(%{
              error: "server_error",
              message: "Erro ao verificar status do e-mail. Tente novamente mais tarde."
            })
        end
    end
  end
end
