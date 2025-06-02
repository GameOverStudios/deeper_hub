defmodule DeeperHub.WebInterface.Resources.BxTasksVideosResized do
  @moduledoc """
  Recurso REST para bx_tasks_videos_resizeds.
  Fornece endpoints para gerenciar bx_tasks_videos_resizeds.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTasksVideosResized,
    resource_name: "bx_tasks_videos_resized"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
