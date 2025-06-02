defmodule DeeperHub.WebInterface.Resources.BxAdsPromoTracker do
  @moduledoc """
  Recurso REST para bx_ads_promo_trackers.
  Fornece endpoints para gerenciar bx_ads_promo_trackers.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAdsPromoTracker,
    resource_name: "bx_ads_promo_tracker"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
