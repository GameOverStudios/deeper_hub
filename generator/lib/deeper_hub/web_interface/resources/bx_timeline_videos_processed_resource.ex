defmodule DeeperHub.WebInterface.Resources.BxTimelineVideosProcessed do
  @moduledoc """
  Recurso REST para bx_timeline_videos_processeds.
  Fornece endpoints para gerenciar bx_timeline_videos_processeds.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTimelineVideosProcessed,
    resource_name: "bx_timeline_videos_processed"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
