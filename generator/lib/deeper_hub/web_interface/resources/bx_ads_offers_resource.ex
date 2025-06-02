defmodule DeeperHub.WebInterface.Resources.BxAdsOffers do
  @moduledoc """
  Recurso REST para bx_ads_offers.
  Fornece endpoints para gerenciar bx_ads_offers.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAdsOffers,
    resource_name: "bx_ads_offer"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
