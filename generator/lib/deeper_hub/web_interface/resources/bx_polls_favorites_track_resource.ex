defmodule DeeperHub.WebInterface.Resources.BxPollsFavoritesTrack do
  @moduledoc """
  Recurso REST para bx_polls_favorites_tracks.
  Fornece endpoints para gerenciar bx_polls_favorites_tracks.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPollsFavoritesTrack,
    resource_name: "bx_polls_favorites_track"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
