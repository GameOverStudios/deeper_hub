defmodule DeeperHub.WebInterface.Resources.BxAdsPhotos do
  @moduledoc """
  Recurso REST para bx_ads_photos.
  Fornece endpoints para gerenciar bx_ads_photos.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAdsPhotos,
    resource_name: "bx_ads_photo"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
