defmodule DeeperHub.WebInterface.Resources.BxReviewsPhotosResized do
  @moduledoc """
  Recurso REST para bx_reviews_photos_resizeds.
  Fornece endpoints para gerenciar bx_reviews_photos_resizeds.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxReviewsPhotosResized,
    resource_name: "bx_reviews_photos_resized"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
