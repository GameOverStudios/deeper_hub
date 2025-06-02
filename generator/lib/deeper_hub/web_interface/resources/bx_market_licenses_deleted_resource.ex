defmodule DeeperHub.WebInterface.Resources.BxMarketLicensesDeleted do
  @moduledoc """
  Recurso REST para bx_market_licenses_deleteds.
  Fornece endpoints para gerenciar bx_market_licenses_deleteds.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxMarketLicensesDeleted,
    resource_name: "bx_market_licenses_deleted"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
