defmodule DeeperHub.Core.Websocket.Endpoint do
  @moduledoc """
  Endpoint WebSocket do DeeperHub.

  Este endpoint:
  - Gerencia as conexões WebSocket
  - Configura SSL/TLS
  - Implementa timeout de conexão
  """

  use Phoenix.Endpoint, otp_app: :deeper_hub

  socket "/socket", DeeperHub.Core.Websocket.Socket,
    websocket: [timeout: 45_000, compress: true],
    longpoll: false

  # Configuração de timeout
  @session_timeout 30_000

  # Configurações de socket que podem ser usadas em outros lugares
  def socket_opts do
    [
      compress: true,
      timeout: @session_timeout,
      transport_options: [
        max_payload: 1_000_000,
        timeout: @session_timeout
      ]
    ]
  end

  # Configuração do endpoint gerenciada via config/runtime.exs

  def config_change(changed, _new, removed) do
    DeeperHub.Core.Websocket.Endpoint.config_change(changed, removed)
    :ok
  end

  # Configuração do servidor HTTP


  plug Plug.Static,
    at: "/",
    from: :deeper_hub,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  plug Plug.Session,
    store: :cookie,
    key: "_deeper_hub_key",
    signing_salt: "yada yada"


end
