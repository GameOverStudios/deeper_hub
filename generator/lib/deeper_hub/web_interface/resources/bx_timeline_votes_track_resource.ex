defmodule DeeperHub.WebInterface.Resources.BxTimelineVotesTrack do
  @moduledoc """
  Recurso REST para bx_timeline_votes_tracks.
  Fornece endpoints para gerenciar bx_timeline_votes_tracks.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTimelineVotesTrack,
    resource_name: "bx_timeline_votes_track"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
