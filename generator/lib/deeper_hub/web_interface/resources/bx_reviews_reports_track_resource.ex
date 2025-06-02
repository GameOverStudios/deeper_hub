defmodule DeeperHub.WebInterface.Resources.BxReviewsReportsTrack do
  @moduledoc """
  Recurso REST para bx_reviews_reports_tracks.
  Fornece endpoints para gerenciar bx_reviews_reports_tracks.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxReviewsReportsTrack,
    resource_name: "bx_reviews_reports_track"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
