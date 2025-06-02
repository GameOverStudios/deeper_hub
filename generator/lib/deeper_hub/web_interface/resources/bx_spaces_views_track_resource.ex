defmodule DeeperHub.WebInterface.Resources.BxSpacesViewsTrack do
  @moduledoc """
  Recurso REST para bx_spaces_views_tracks.
  Fornece endpoints para gerenciar bx_spaces_views_tracks.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxSpacesViewsTrack,
    resource_name: "bx_spaces_views_track"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
