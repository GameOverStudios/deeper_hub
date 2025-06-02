defmodule DeeperHub.WebInterface.Resources.BxPersonsVotesTrack do
  @moduledoc """
  Recurso REST para bx_persons_votes_tracks.
  Fornece endpoints para gerenciar bx_persons_votes_tracks.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPersonsVotesTrack,
    resource_name: "bx_persons_votes_track"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
