defmodule DeeperHub.WebInterface.Resources.BxAdsSources do
  @moduledoc """
  Recurso REST para bx_ads_sources.
  Fornece endpoints para gerenciar bx_ads_sources.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAdsSources,
    resource_name: "bx_ads_source"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
