defmodule DeeperHub.WebInterface.Resources.BxReviewsVideos do
  @moduledoc """
  Recurso REST para bx_reviews_videos.
  Fornece endpoints para gerenciar bx_reviews_videos.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxReviewsVideos,
    resource_name: "bx_reviews_video"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
