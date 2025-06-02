defmodule DeeperHub.WebInterface.Resources.BxClassesPhotosResized do
  @moduledoc """
  Recurso REST para bx_classes_photos_resizeds.
  Fornece endpoints para gerenciar bx_classes_photos_resizeds.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxClassesPhotosResized,
    resource_name: "bx_classes_photos_resized"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
