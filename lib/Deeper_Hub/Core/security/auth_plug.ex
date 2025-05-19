defmodule DeeperHub.Core.Security.AuthPlug do
  @moduledoc """
  Plug para autenticação de requisições HTTP.

  Este plug verifica se a requisição possui um token JWT válido
  no cabeçalho de autorização e adiciona as informações do usuário
  ao contexto da requisição.
  """

  import Plug.Conn

  require DeeperHub.Core.Logger
  alias DeeperHub.Accounts.Auth.Guardian

  @doc """
  Inicializa o plug com as opções fornecidas.

  ## Opções

  - `:required` - Se `true`, a autenticação é obrigatória (padrão: `true`)
  - `:resource_type` - Tipo de recurso a ser verificado (padrão: `"access"`)
  """
  def init(opts) do
    %{
      required: Keyword.get(opts, :required, true),
      resource_type: Keyword.get(opts, :resource_type, "access")
    }
  end

  @doc """
  Verifica se a requisição possui um token JWT válido.

  ## Parâmetros

  - `conn` - A conexão Plug
  - `opts` - Opções do plug

  ## Retorno

  - A conexão Plug, possivelmente modificada
  """
  def call(conn, opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, claims} <- Guardian.decode_and_verify(token, %{"typ" => opts.resource_type}),
         {:ok, user} <- Guardian.resource_from_claims(claims) do
      # Adiciona as informações do usuário ao contexto da requisição
      conn
      |> assign(:current_user, user)
      |> assign(:current_token, token)
      |> assign(:token_claims, claims)
    else
      _ ->
        if opts.required do
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(401, Jason.encode!(%{
            error: "Não autorizado",
            code: "unauthorized"
          }))
          |> halt()
        else
          conn
        end
    end
  end
end
