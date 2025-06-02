defmodule DeeperHub.WebInterface.Resources.BxAdsLinks do
  @moduledoc """
  Recurso REST para bx_ads_links.
  Fornece endpoints para gerenciar bx_ads_links.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAdsLinks,
    resource_name: "bx_ads_link"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
