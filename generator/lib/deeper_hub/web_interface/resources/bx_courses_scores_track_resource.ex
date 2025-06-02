defmodule DeeperHub.WebInterface.Resources.BxCoursesScoresTrack do
  @moduledoc """
  Recurso REST para bx_courses_scores_tracks.
  Fornece endpoints para gerenciar bx_courses_scores_tracks.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxCoursesScoresTrack,
    resource_name: "bx_courses_scores_track"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
