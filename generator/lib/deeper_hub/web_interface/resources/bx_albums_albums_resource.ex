defmodule DeeperHub.WebInterface.Resources.BxAlbumsAlbums do
  @moduledoc """
  Recurso REST para bx_albums_albums.
  Fornece endpoints para gerenciar bx_albums_albums.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAlbumsAlbums,
    resource_name: "bx_albums_album"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
