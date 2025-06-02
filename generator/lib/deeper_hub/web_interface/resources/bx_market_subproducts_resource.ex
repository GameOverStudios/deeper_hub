defmodule DeeperHub.WebInterface.Resources.BxMarketSubproducts do
  @moduledoc """
  Recurso REST para bx_market_subproducts.
  Fornece endpoints para gerenciar bx_market_subproducts.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxMarketSubproducts,
    resource_name: "bx_market_subproduct"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
