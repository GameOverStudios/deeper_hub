defmodule DeeperHub.WebInterface.Resources.BxMarketLicenses do
  @moduledoc """
  Recurso REST para bx_market_licenses.
  Fornece endpoints para gerenciar bx_market_licenses.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxMarketLicenses,
    resource_name: "bx_market_license"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
