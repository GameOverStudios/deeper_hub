defmodule DeeperHub.WebInterface.Resources.BxAdsFiles do
  @moduledoc """
  Recurso REST para bx_ads_files.
  Fornece endpoints para gerenciar bx_ads_files.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAdsFiles,
    resource_name: "bx_ads_file"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
