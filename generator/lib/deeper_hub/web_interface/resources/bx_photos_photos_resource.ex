defmodule DeeperHub.WebInterface.Resources.BxPhotosPhotos do
  @moduledoc """
  Recurso REST para bx_photos_photos.
  Fornece endpoints para gerenciar bx_photos_photos.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPhotosPhotos,
    resource_name: "bx_photos_photo"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
