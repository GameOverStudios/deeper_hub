defmodule DeeperHub.WebInterface.Resources.BxAlbumsFavoritesMediaTrack do
  @moduledoc """
  Recurso REST para bx_albums_favorites_media_tracks.
  Fornece endpoints para gerenciar bx_albums_favorites_media_tracks.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAlbumsFavoritesMediaTrack,
    resource_name: "bx_albums_favorites_media_track"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
