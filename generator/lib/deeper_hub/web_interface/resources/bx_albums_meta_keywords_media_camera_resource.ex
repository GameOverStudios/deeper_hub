defmodule DeeperHub.WebInterface.Resources.BxAlbumsMetaKeywordsMediaCamera do
  @moduledoc """
  Recurso REST para bx_albums_meta_keywords_media_cameras.
  Fornece endpoints para gerenciar bx_albums_meta_keywords_media_cameras.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAlbumsMetaKeywordsMediaCamera,
    resource_name: "bx_albums_meta_keywords_media_camera"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
