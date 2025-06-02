defmodule DeeperHub.WebInterface.Resources.BxForumVideos do
  @moduledoc """
  Recurso REST para bx_forum_videos.
  Fornece endpoints para gerenciar bx_forum_videos.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxForumVideos,
    resource_name: "bx_forum_video"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
