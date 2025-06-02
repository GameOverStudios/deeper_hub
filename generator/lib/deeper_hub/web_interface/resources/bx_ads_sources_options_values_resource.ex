defmodule DeeperHub.WebInterface.Resources.BxAdsSourcesOptionsValues do
  @moduledoc """
  Recurso REST para bx_ads_sources_options_values.
  Fornece endpoints para gerenciar bx_ads_sources_options_values.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAdsSourcesOptionsValues,
    resource_name: "bx_ads_sources_options_value"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
