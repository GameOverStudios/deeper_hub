defmodule DeeperHub.WebInterface.Resources.BxAlbumsCmtsMedia do
  @moduledoc """
  Recurso REST para bx_albums_cmts_medias.
  Fornece endpoints para gerenciar bx_albums_cmts_medias.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAlbumsCmtsMedia,
    resource_name: "bx_albums_cmts_media"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
