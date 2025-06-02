defmodule DeeperHub.WebInterface.Resources.BxAdsCategories do
  @moduledoc """
  Recurso REST para bx_ads_categories.
  Fornece endpoints para gerenciar bx_ads_categories.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAdsCategories,
    resource_name: "bx_ads_categorie"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
