defmodule DeeperHub.WebInterface.Resources.BxAdsCommodities do
  @moduledoc """
  Recurso REST para bx_ads_commodities.
  Fornece endpoints para gerenciar bx_ads_commodities.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAdsCommodities,
    resource_name: "bx_ads_commoditie"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
