defmodule DeeperHub.WebInterface.Resources.BxPollsScoresTrack do
  @moduledoc """
  Recurso REST para bx_polls_scores_tracks.
  Fornece endpoints para gerenciar bx_polls_scores_tracks.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPollsScoresTrack,
    resource_name: "bx_polls_scores_track"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
