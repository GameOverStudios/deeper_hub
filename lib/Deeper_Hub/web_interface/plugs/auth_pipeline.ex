defmodule DeeperHub.WebInterface.Plugs.AuthPipeline do
  @moduledoc """
  Pipeline de autenticação para o DeeperHub.

  Este módulo define os plugs utilizados para autenticação e autorização
  de requisições, incluindo proteção contra ataques de força bruta.
  """

  use Plug.Builder
  
  import Plug.Conn, only: [fetch_session: 2, fetch_query_params: 2]
  
  alias DeeperHub.Core.Security.AuthAttack
  alias DeeperHub.Core.Security.AuthPlug
  require Logger

  # Inicializa o módulo de proteção contra ataques
  AuthAttack.init()

  # Define o pipeline de autenticação
  plug :fetch_session
  plug :fetch_query_params

  # Proteção contra ataques de força bruta
  plug :apply_auth_attack
  # Plug para autenticação via JWT
  plug AuthPlug, resource_type: "access"

  # Função auxiliar para inicializar o pipeline
  def init(opts), do: opts

  # Função auxiliar para chamar o pipeline
  def call(conn, _opts) do
    conn
  end

  # Nota: Utilizamos Plug.Conn.fetch_session/2 e Plug.Conn.fetch_query_params/2 diretamente no pipeline

  # Função auxiliar para aplicar proteção contra ataques de força bruta
  defp apply_auth_attack(conn, _opts) do
    AuthAttack.rate_limit_auth(conn, [])
  end
end
