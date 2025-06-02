defmodule DeeperHub.WebInterface.Resources.BxSpacesStarsTrack do
  @moduledoc """
  Recurso REST para bx_spaces_stars_tracks.
  Fornece endpoints para gerenciar bx_spaces_stars_tracks.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxSpacesStarsTrack,
    resource_name: "bx_spaces_stars_track"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
