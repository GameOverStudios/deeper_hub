defmodule DeeperHub.WebInterface.Resources.BxAdsPromoLicensesDeleted do
  @moduledoc """
  Recurso REST para bx_ads_promo_licenses_deleteds.
  Fornece endpoints para gerenciar bx_ads_promo_licenses_deleteds.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAdsPromoLicensesDeleted,
    resource_name: "bx_ads_promo_licenses_deleted"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
