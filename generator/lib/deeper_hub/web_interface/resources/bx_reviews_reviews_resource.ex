defmodule DeeperHub.WebInterface.Resources.BxReviewsReviews do
  @moduledoc """
  Recurso REST para bx_reviews_reviews.
  Fornece endpoints para gerenciar bx_reviews_reviews.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxReviewsReviews,
    resource_name: "bx_reviews_review"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
