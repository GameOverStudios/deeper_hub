defmodule DeeperHub.WebInterface.Resources.BxReviewsScores do
  @moduledoc """
  Recurso REST para bx_reviews_scores.
  Fornece endpoints para gerenciar bx_reviews_scores.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxReviewsScores,
    resource_name: "bx_reviews_score"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
