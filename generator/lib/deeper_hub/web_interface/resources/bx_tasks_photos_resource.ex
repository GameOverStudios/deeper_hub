defmodule DeeperHub.WebInterface.Resources.BxTasksPhotos do
  @moduledoc """
  Recurso REST para bx_tasks_photos.
  Fornece endpoints para gerenciar bx_tasks_photos.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTasksPhotos,
    resource_name: "bx_tasks_photo"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
