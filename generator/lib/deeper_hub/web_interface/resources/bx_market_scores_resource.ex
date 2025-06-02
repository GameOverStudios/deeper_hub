defmodule DeeperHub.WebInterface.Resources.BxMarketScores do
  @moduledoc """
  Recurso REST para bx_market_scores.
  Fornece endpoints para gerenciar bx_market_scores.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxMarketScores,
    resource_name: "bx_market_score"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
