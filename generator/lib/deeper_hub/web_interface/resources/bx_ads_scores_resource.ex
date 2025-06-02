defmodule DeeperHub.WebInterface.Resources.BxAdsScores do
  @moduledoc """
  Recurso REST para bx_ads_scores.
  Fornece endpoints para gerenciar bx_ads_scores.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAdsScores,
    resource_name: "bx_ads_score"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
