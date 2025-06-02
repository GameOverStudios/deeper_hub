defmodule DeeperHub.WebInterface.Resources.BxReviewsCovers do
  @moduledoc """
  Recurso REST para bx_reviews_covers.
  Fornece endpoints para gerenciar bx_reviews_covers.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxReviewsCovers,
    resource_name: "bx_reviews_cover"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
