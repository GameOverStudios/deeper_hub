defmodule DeeperHub.Core.HTTP.Endpoint do
  @moduledoc """
  Endpoint HTTP para o DeeperHub.

  Este módulo define o endpoint HTTP principal da aplicação,
  configurando os plugs necessários para processamento de requisições.
  """

  use Plug.Router

  require DeeperHub.Core.Logger

  # Plugs que são executados para todas as requisições
  plug :match
  plug Plug.RequestId
  plug Plug.Logger, log: :debug

  # Plug de segurança que aplica Plug.Attack e outros mecanismos de proteção
  plug DeeperHub.Core.Security.SecurityPlug

  # Plug CORS para permitir requisições de origens diferentes
  plug CORSPlug, origin: "*"

  # Parsers para diferentes tipos de conteúdo
  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason

  # Plug que executa a função de roteamento
  plug :dispatch

  # Rota para verificação de saúde do sistema
  get "/health" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{status: "ok", timestamp: :os.system_time(:second)}))
  end

  # Rota para métricas (se necessário)
  get "/metrics" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{
      connections: get_connection_count(),
      uptime_seconds: get_uptime_seconds()
    }))
  end

  # Encaminha requisições de API para o router de API
  forward "/api", to: DeeperHub.Core.HTTP.APIRouter

  # Rota padrão para requisições não correspondentes
  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{error: "Rota não encontrada", code: "not_found"}))
  end

  # Obtém o número de conexões ativas
  defp get_connection_count do
    table = :ets.whereis(:socket_connections)

    if table == :undefined do
      0
    else
      :ets.info(table, :size) || 0
    end
  end

  # Obtém o tempo de atividade do sistema em segundos
  defp get_uptime_seconds do
    {uptime, _} = :erlang.statistics(:wall_clock)
    div(uptime, 1000)
  end
end
