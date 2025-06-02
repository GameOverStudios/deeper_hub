defmodule DeeperHub.WebInterface.Resources.BxAdsCategoriesTypes do
  @moduledoc """
  Recurso REST para bx_ads_categories_types.
  Fornece endpoints para gerenciar bx_ads_categories_types.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAdsCategoriesTypes,
    resource_name: "bx_ads_categories_type"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
