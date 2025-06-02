defmodule DeeperHub.WebInterface.Resources.BxMarketPhotos2products do
  @moduledoc """
  Recurso REST para bx_market_photos2products.
  Fornece endpoints para gerenciar bx_market_photos2products.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxMarketPhotos2products,
    resource_name: "bx_market_photos2product"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
