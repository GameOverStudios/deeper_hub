defmodule DeeperHub.WebInterface.Resources.BxTasksVideos do
  @moduledoc """
  Recurso REST para bx_tasks_videos.
  Fornece endpoints para gerenciar bx_tasks_videos.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTasksVideos,
    resource_name: "bx_tasks_video"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
