defmodule DeeperHub.WebInterface.Resources.BxCoursesVotesTrack do
  @moduledoc """
  Recurso REST para bx_courses_votes_tracks.
  Fornece endpoints para gerenciar bx_courses_votes_tracks.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxCoursesVotesTrack,
    resource_name: "bx_courses_votes_track"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
