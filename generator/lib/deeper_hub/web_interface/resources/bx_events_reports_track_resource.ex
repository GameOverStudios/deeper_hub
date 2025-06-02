defmodule DeeperHub.WebInterface.Resources.BxEventsReportsTrack do
  @moduledoc """
  Recurso REST para bx_events_reports_tracks.
  Fornece endpoints para gerenciar bx_events_reports_tracks.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxEventsReportsTrack,
    resource_name: "bx_events_reports_track"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
