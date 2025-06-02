defmodule DeeperHub.WebInterface.Resources.BxStoriesVotesTrack do
  @moduledoc """
  Recurso REST para bx_stories_votes_tracks.
  Fornece endpoints para gerenciar bx_stories_votes_tracks.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxStoriesVotesTrack,
    resource_name: "bx_stories_votes_track"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
