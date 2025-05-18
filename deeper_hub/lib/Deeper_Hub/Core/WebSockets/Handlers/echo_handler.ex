defmodule Deeper_Hub.Core.WebSockets.Handlers.EchoHandler do
  @moduledoc """
  Handler para mensagens de eco.

  Este módulo simplesmente retorna o payload recebido, útil para testes.
  """

  alias Deeper_Hub.Core.Logger

  @doc """
  Manipula uma mensagem de eco.

  ## Parâmetros

    - `payload`: O payload da mensagem

  ## Retorno

    - `{:ok, response}` contendo o mesmo payload
  """
  def handle(payload) do
    Logger.debug("Processando mensagem de eco", %{
      module: __MODULE__,
      payload: payload
    })

    {:ok, %{
      type: "echo.response",
      payload: payload,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }}
  end
end
