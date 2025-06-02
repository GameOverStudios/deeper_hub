defmodule DeeperHub.WebInterface.Resources.BxOrganizationsPrices do
  @moduledoc """
  Recurso REST para bx_organizations_prices.
  Fornece endpoints para gerenciar bx_organizations_prices.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxOrganizationsPrices,
    resource_name: "bx_organizations_price"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
