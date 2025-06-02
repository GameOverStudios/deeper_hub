defmodule DeeperHub.WebInterface.Resources.BxPhotosReportsTrack do
  @moduledoc """
  Recurso REST para bx_photos_reports_tracks.
  Fornece endpoints para gerenciar bx_photos_reports_tracks.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPhotosReportsTrack,
    resource_name: "bx_photos_reports_track"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
