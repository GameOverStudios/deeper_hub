defmodule DeeperHub.WebInterface.Resources.BxMarketMetaLocations do
  @moduledoc """
  Recurso REST para bx_market_meta_locations.
  Fornece endpoints para gerenciar bx_market_meta_locations.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxMarketMetaLocations,
    resource_name: "bx_market_meta_location"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
