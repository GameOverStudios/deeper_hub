defmodule DeeperHub.WebInterface.Resources.BxTimelineScoresTrack do
  @moduledoc """
  Recurso REST para bx_timeline_scores_tracks.
  Fornece endpoints para gerenciar bx_timeline_scores_tracks.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTimelineScoresTrack,
    resource_name: "bx_timeline_scores_track"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
