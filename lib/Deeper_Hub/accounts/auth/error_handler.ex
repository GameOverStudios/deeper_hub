defmodule DeeperHub.Accounts.Auth.ErrorHandler do
  @moduledoc """
  Módulo para tratamento de erros de autenticação no DeeperHub.
  
  Este módulo implementa callbacks para lidar com erros de autenticação
  e autorização, fornecendo respostas apropriadas para diferentes tipos de erros.
  """
  
  import Plug.Conn

  @doc """
  Manipula erros de autenticação, como tokens inválidos ou expirados.
  
  ## Parâmetros
    * `conn` - Conexão Plug
    * `type` - Tipo do erro de autenticação
  
  ## Retorno
    * Conexão com resposta de erro apropriada
  """
  def auth_error(conn, {type, _reason}, _opts) do
    body = Jason.encode!(%{error: error_message(type)})
    
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status_code(type), body)
  end
  
  # Mapeia tipos de erro para códigos de status HTTP
  defp status_code(:invalid_token), do: 401
  defp status_code(:unauthenticated), do: 401
  defp status_code(:unauthorized), do: 403
  defp status_code(:token_expired), do: 401
  defp status_code(_), do: 500
  
  # Mapeia tipos de erro para mensagens de erro
  defp error_message(:invalid_token), do: "Token inválido"
  defp error_message(:unauthenticated), do: "Não autenticado"
  defp error_message(:unauthorized), do: "Não autorizado"
  defp error_message(:token_expired), do: "Token expirado"
  defp error_message(_), do: "Erro de autenticação desconhecido"
end
