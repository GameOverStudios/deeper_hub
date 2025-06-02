defmodule DeeperHub.WebInterface.Resources.BxVideosMetaLocations do
  @moduledoc """
  Recurso REST para bx_videos_meta_locations.
  Fornece endpoints para gerenciar bx_videos_meta_locations.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxVideosMetaLocations,
    resource_name: "bx_videos_meta_location"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
