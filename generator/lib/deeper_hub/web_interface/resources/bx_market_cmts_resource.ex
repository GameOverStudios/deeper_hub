defmodule DeeperHub.WebInterface.Resources.BxMarketCmts do
  @moduledoc """
  Recurso REST para bx_market_cmts.
  Fornece endpoints para gerenciar bx_market_cmts.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxMarketCmts,
    resource_name: "bx_market_cmt"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
