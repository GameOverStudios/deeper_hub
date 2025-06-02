defmodule DeeperHub.WebInterface.Resources.BxPhotosMetaKeywordsCamera do
  @moduledoc """
  Recurso REST para bx_photos_meta_keywords_cameras.
  Fornece endpoints para gerenciar bx_photos_meta_keywords_cameras.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPhotosMetaKeywordsCamera,
    resource_name: "bx_photos_meta_keywords_camera"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
