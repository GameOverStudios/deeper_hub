defmodule DeeperHub.WebInterface.Resources.BxTimelineReportsTrack do
  @moduledoc """
  Recurso REST para bx_timeline_reports_tracks.
  Fornece endpoints para gerenciar bx_timeline_reports_tracks.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTimelineReportsTrack,
    resource_name: "bx_timeline_reports_track"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
