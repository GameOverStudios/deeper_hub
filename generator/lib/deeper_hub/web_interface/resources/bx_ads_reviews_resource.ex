defmodule DeeperHub.WebInterface.Resources.BxAdsReviews do
  @moduledoc """
  Recurso REST para bx_ads_reviews.
  Fornece endpoints para gerenciar bx_ads_reviews.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAdsReviews,
    resource_name: "bx_ads_review"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
