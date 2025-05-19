defmodule DeeperHub.WebInterface.Controllers.SessionController do
  @moduledoc """
  Controlador para gerenciamento de sessões de usuário.

  Este controlador fornece endpoints para login, logout, refresh de tokens,
  listagem de sessões ativas e gerenciamento de sessões.
  """

  alias DeeperHub.Accounts.Auth
  alias DeeperHub.Accounts.Auth.Logout
  alias DeeperHub.Accounts.SessionManager
  require DeeperHub.Core.Logger

  @doc """
  Endpoint para login de usuário.

  ## Parâmetros
    * `conn` - Conexão Plug
    * `params` - Parâmetros da requisição:
      * `email` - Email do usuário
      * `password` - Senha do usuário
      * `persistent` - Se a sessão deve ser persistente (opcional)
      * `device_info` - Informações sobre o dispositivo (opcional)

  ## Retorno
    * `200 OK` - Login bem-sucedido, retorna tokens e informações do usuário
    * `400 Bad Request` - Parâmetros inválidos
    * `401 Unauthorized` - Credenciais inválidas
    * `403 Forbidden` - Email não verificado
    * `500 Internal Server Error` - Erro interno
  """
  def login(conn, params) do
    # Extrai parâmetros
    email = Map.get(params, "email")
    password = Map.get(params, "password")
    persistent = Map.get(params, "persistent", false)
    device_info = Map.get(params, "device_info", %{})

    # Valida parâmetros obrigatórios
    if is_nil(email) or is_nil(password) do
      conn
      |> Plug.Conn.put_status(400)
      |> Plug.Conn.json(%{
        error: "missing_parameters",
        message: "Email e senha são obrigatórios"
      })
    else
      # Obtém informações do cliente
      ip_address = conn.remote_ip |> Tuple.to_list() |> Enum.join(".")
      user_agent = Plug.Conn.get_req_header(conn, "user-agent") |> List.first() || "desconhecido"

      # Tenta realizar o login
      case Auth.login_with_email_password(email, password, [
        device_info: device_info,
        ip_address: ip_address,
        user_agent: user_agent,
        persistent: persistent
      ]) do
        {:ok, user, tokens, session_id} ->
          # Remove campos sensíveis do usuário
          user_safe = Map.drop(user, ["password_hash"])

          # Adiciona o ID da sessão à resposta
          response = Map.put(tokens, :session_id, session_id)

          conn
          |> Plug.Conn.put_status(200)
          |> Plug.Conn.json(%{
            user: user_safe,
            auth: response
          })

        {:error, :invalid_credentials} ->
          conn
          |> Plug.Conn.put_status(401)
          |> Plug.Conn.json(%{
            error: "invalid_credentials",
            message: "Email ou senha inválidos"
          })

        {:error, :email_not_verified} ->
          conn
          |> Plug.Conn.put_status(403)
          |> Plug.Conn.json(%{
            error: "email_not_verified",
            message: "Email não verificado. Por favor, verifique seu email antes de fazer login."
          })

        {:error, _reason} ->
          conn
          |> Plug.Conn.put_status(500)
          |> Plug.Conn.json(%{
            error: "server_error",
            message: "Erro ao processar login. Tente novamente mais tarde."
          })
      end
    end
  end

  @doc """
  Endpoint para atualização de tokens (refresh).

  ## Parâmetros
    * `conn` - Conexão Plug
    * `params` - Parâmetros da requisição:
      * `refresh_token` - Token de refresh
      * `session_id` - ID da sessão

  ## Retorno
    * `200 OK` - Tokens atualizados com sucesso
    * `400 Bad Request` - Parâmetros inválidos
    * `401 Unauthorized` - Token inválido
    * `404 Not Found` - Sessão não encontrada
    * `500 Internal Server Error` - Erro interno
  """
  def refresh(conn, params) do
    # Extrai parâmetros
    refresh_token = Map.get(params, "refresh_token")
    session_id = Map.get(params, "session_id")

    # Valida parâmetros obrigatórios
    if is_nil(refresh_token) or is_nil(session_id) do
      conn
      |> Plug.Conn.put_status(400)
      |> Plug.Conn.json(%{
        error: "missing_parameters",
        message: "Token de refresh e ID da sessão são obrigatórios"
      })
    else
      # Obtém informações do cliente
      ip_address = conn.remote_ip |> Tuple.to_list() |> Enum.join(".")

      # Tenta atualizar os tokens
      case Auth.refresh_tokens(refresh_token, session_id, [
        ip_address: ip_address
      ]) do
        {:ok, user, tokens} ->
          # Remove campos sensíveis do usuário
          user_safe = Map.drop(user, ["password_hash"])

          conn
          |> Plug.Conn.put_status(200)
          |> Plug.Conn.json(%{
            user: user_safe,
            auth: tokens
          })

        {:error, :invalid_token} ->
          conn
          |> Plug.Conn.put_status(401)
          |> Plug.Conn.json(%{
            error: "invalid_token",
            message: "Token de refresh inválido ou expirado"
          })

        {:error, :session_not_found} ->
          conn
          |> Plug.Conn.put_status(404)
          |> Plug.Conn.json(%{
            error: "session_not_found",
            message: "Sessão não encontrada"
          })

        {:error, :session_expired} ->
          conn
          |> Plug.Conn.put_status(401)
          |> Plug.Conn.json(%{
            error: "session_expired",
            message: "Sessão expirada. Por favor, faça login novamente."
          })

        {:error, _reason} ->
          conn
          |> Plug.Conn.put_status(500)
          |> Plug.Conn.json(%{
            error: "server_error",
            message: "Erro ao atualizar tokens. Tente novamente mais tarde."
          })
      end
    end
  end

  @doc """
  Endpoint para logout.

  ## Parâmetros
    * `conn` - Conexão Plug
    * `params` - Parâmetros da requisição:
      * `session_id` - ID da sessão
      * `all_sessions` - Se deve encerrar todas as sessões do usuário (opcional)

  ## Retorno
    * `200 OK` - Logout realizado com sucesso
    * `400 Bad Request` - Parâmetros inválidos
    * `404 Not Found` - Sessão não encontrada
    * `500 Internal Server Error` - Erro interno
  """
  def logout(conn, params) do
    # Extrai parâmetros
    session_id = Map.get(params, "session_id")
    all_sessions = Map.get(params, "all_sessions", false)

    # Valida parâmetros obrigatórios
    if is_nil(session_id) do
      conn
      |> Plug.Conn.put_status(400)
      |> Plug.Conn.json(%{
        error: "missing_parameters",
        message: "ID da sessão é obrigatório"
      })
    else
      # Obtém informações do cliente
      ip_address = conn.remote_ip |> Tuple.to_list() |> Enum.join(".")

      # Tenta realizar o logout
      case Logout.logout(session_id, [
        ip_address: ip_address,
        all_sessions: all_sessions
      ]) do
        :ok ->
          conn
          |> Plug.Conn.put_status(200)
          |> Plug.Conn.json(%{
            success: true,
            message: if(all_sessions, do: "Todas as sessões encerradas com sucesso", else: "Logout realizado com sucesso")
          })

        {:error, :session_not_found} ->
          conn
          |> Plug.Conn.put_status(404)
          |> Plug.Conn.json(%{
            error: "session_not_found",
            message: "Sessão não encontrada"
          })

        {:error, _reason} ->
          conn
          |> Plug.Conn.put_status(500)
          |> Plug.Conn.json(%{
            error: "server_error",
            message: "Erro ao processar logout. Tente novamente mais tarde."
          })
      end
    end
  end

  @doc """
  Endpoint para listar sessões ativas do usuário.

  ## Parâmetros
    * `conn` - Conexão Plug
    * `_params` - Parâmetros da requisição (não utilizado)

  ## Retorno
    * `200 OK` - Lista de sessões ativas
    * `401 Unauthorized` - Usuário não autenticado
    * `500 Internal Server Error` - Erro interno
  """
  def list_sessions(conn, _params) do
    # Obtém o usuário autenticado do contexto da requisição
    case conn.assigns[:current_user] do
      nil ->
        conn
        |> Plug.Conn.put_status(401)
        |> Plug.Conn.json(%{
          error: "unauthorized",
          message: "Usuário não autenticado"
        })

      user ->
        # Tenta listar as sessões ativas
        case SessionManager.list_active_sessions(user["id"]) do
          {:ok, sessions} ->
            # Formata as sessões para exibição
            formatted_sessions = Enum.map(sessions, fn session ->
              # Calcula informações adicionais
              now = DateTime.utc_now()

              last_activity = case DateTime.from_iso8601(session["last_activity_at"]) do
                {:ok, dt, _} -> dt
                _ -> now
              end

              expires_at = case DateTime.from_iso8601(session["expires_at"]) do
                {:ok, dt, _} -> dt
                _ -> now
              end

              # Calcula tempo desde a última atividade
              last_activity_diff = DateTime.diff(now, last_activity, :second)

              # Calcula tempo até a expiração
              expires_in = DateTime.diff(expires_at, now, :second)

              # Verifica se é a sessão atual
              is_current = session["id"] == conn.assigns[:current_session_id]

              # Retorna a sessão formatada
              %{
                id: session["id"],
                device_info: session["device_info"],
                ip_address: session["ip_address"],
                user_agent: session["user_agent"],
                persistent: session["persistent"],
                last_activity_at: session["last_activity_at"],
                last_activity_ago: format_time_diff(last_activity_diff),
                expires_at: session["expires_at"],
                expires_in: format_time_diff(expires_in),
                created_at: session["created_at"],
                is_current: is_current
              }
            end)

            conn
            |> Plug.Conn.put_status(200)
            |> Plug.Conn.json(%{
              sessions: formatted_sessions
            })

          {:error, _reason} ->
            conn
            |> Plug.Conn.put_status(500)
            |> Plug.Conn.json(%{
              error: "server_error",
              message: "Erro ao listar sessões. Tente novamente mais tarde."
            })
        end
    end
  end

  @doc """
  Endpoint para encerrar uma sessão específica.

  ## Parâmetros
    * `conn` - Conexão Plug
    * `params` - Parâmetros da requisição:
      * `session_id` - ID da sessão a ser encerrada

  ## Retorno
    * `200 OK` - Sessão encerrada com sucesso
    * `400 Bad Request` - Parâmetros inválidos
    * `401 Unauthorized` - Usuário não autenticado
    * `403 Forbidden` - Usuário não tem permissão para encerrar a sessão
    * `404 Not Found` - Sessão não encontrada
    * `500 Internal Server Error` - Erro interno
  """
  def terminate_session(conn, params) do
    # Extrai parâmetros
    session_id = Map.get(params, "session_id")

    # Valida parâmetros obrigatórios
    if is_nil(session_id) do
      conn
      |> Plug.Conn.put_status(400)
      |> Plug.Conn.json(%{
        error: "missing_parameters",
        message: "ID da sessão é obrigatório"
      })
    else
      # Obtém o usuário autenticado do contexto da requisição
      case conn.assigns[:current_user] do
        nil ->
          conn
          |> Plug.Conn.put_status(401)
          |> Plug.Conn.json(%{
            error: "unauthorized",
            message: "Usuário não autenticado"
          })

        user ->
          # Verifica se a sessão pertence ao usuário
          sql = "SELECT user_id FROM user_sessions WHERE id = ?;"

          case DeeperHub.Core.Data.Repo.query(sql, [session_id]) do
            {:ok, %{rows: [[session_user_id]]}} ->
              if session_user_id == user["id"] do
                # Tenta encerrar a sessão
                case SessionManager.invalidate_session(session_id, "user_terminated") do
                  :ok ->
                    conn
                    |> Plug.Conn.put_status(200)
                    |> Plug.Conn.json(%{
                      success: true,
                      message: "Sessão encerrada com sucesso"
                    })

                  {:error, _reason} ->
                    conn
                    |> Plug.Conn.put_status(500)
                    |> Plug.Conn.json(%{
                      error: "server_error",
                      message: "Erro ao encerrar sessão. Tente novamente mais tarde."
                    })
                end
              else
                # Usuário não tem permissão para encerrar esta sessão
                conn
                |> Plug.Conn.put_status(403)
                |> Plug.Conn.json(%{
                  error: "forbidden",
                  message: "Você não tem permissão para encerrar esta sessão"
                })
              end

            {:ok, %{rows: []}} ->
              # Sessão não encontrada
              conn
              |> Plug.Conn.put_status(404)
              |> Plug.Conn.json(%{
                error: "session_not_found",
                message: "Sessão não encontrada"
              })

            {:error, _reason} ->
              conn
              |> Plug.Conn.put_status(500)
              |> Plug.Conn.json(%{
                error: "server_error",
                message: "Erro ao verificar sessão. Tente novamente mais tarde."
              })
          end
      end
    end
  end

  # Formata a diferença de tempo em uma string legível
  defp format_time_diff(seconds) when seconds < 60, do: "#{seconds} segundos"
  defp format_time_diff(seconds) when seconds < 3600 do
    minutes = div(seconds, 60)
    "#{minutes} #{pluralize(minutes, "minuto", "minutos")}"
  end
  defp format_time_diff(seconds) when seconds < 86400 do
    hours = div(seconds, 3600)
    "#{hours} #{pluralize(hours, "hora", "horas")}"
  end
  defp format_time_diff(seconds) do
    days = div(seconds, 86400)
    "#{days} #{pluralize(days, "dia", "dias")}"
  end

  # Pluraliza uma palavra com base na quantidade
  defp pluralize(1, singular, _plural), do: singular
  defp pluralize(_count, _singular, plural), do: plural
end
