defmodule DeeperHub.WebInterface.Resources.BxAdsPhotosResized do
  @moduledoc """
  Recurso REST para bx_ads_photos_resizeds.
  Fornece endpoints para gerenciar bx_ads_photos_resizeds.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAdsPhotosResized,
    resource_name: "bx_ads_photos_resized"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
