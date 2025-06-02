defmodule DeeperHub.WebInterface.Resources.BxAdsLicenses do
  @moduledoc """
  Recurso REST para bx_ads_licenses.
  Fornece endpoints para gerenciar bx_ads_licenses.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAdsLicenses,
    resource_name: "bx_ads_license"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
