defmodule DeeperHub.WebInterface.Resources.BxAdsCovers do
  @moduledoc """
  Recurso REST para bx_ads_covers.
  Fornece endpoints para gerenciar bx_ads_covers.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAdsCovers,
    resource_name: "bx_ads_cover"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
