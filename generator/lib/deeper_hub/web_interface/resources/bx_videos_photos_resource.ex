defmodule DeeperHub.WebInterface.Resources.BxVideosPhotos do
  @moduledoc """
  Recurso REST para bx_videos_photos.
  Fornece endpoints para gerenciar bx_videos_photos.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxVideosPhotos,
    resource_name: "bx_videos_photo"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
