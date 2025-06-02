defmodule DeeperHub.WebInterface.Resources.BxAdsVideos do
  @moduledoc """
  Recurso REST para bx_ads_videos.
  Fornece endpoints para gerenciar bx_ads_videos.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAdsVideos,
    resource_name: "bx_ads_video"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
