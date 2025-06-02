defmodule DeeperHub.WebInterface.Resources.BxClassesPhotos do
  @moduledoc """
  Recurso REST para bx_classes_photos.
  Fornece endpoints para gerenciar bx_classes_photos.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxClassesPhotos,
    resource_name: "bx_classes_photo"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
