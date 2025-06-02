defmodule DeeperHub.WebInterface.Resources.BxPhotosMediaResized do
  @moduledoc """
  Recurso REST para bx_photos_media_resizeds.
  Fornece endpoints para gerenciar bx_photos_media_resizeds.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPhotosMediaResized,
    resource_name: "bx_photos_media_resized"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
