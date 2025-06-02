defmodule DeeperHub.WebInterface.Resources.BxReviewsPhotos do
  @moduledoc """
  Recurso REST para bx_reviews_photos.
  Fornece endpoints para gerenciar bx_reviews_photos.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxReviewsPhotos,
    resource_name: "bx_reviews_photo"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
