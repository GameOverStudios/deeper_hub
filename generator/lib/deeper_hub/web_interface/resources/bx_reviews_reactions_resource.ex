defmodule DeeperHub.WebInterface.Resources.BxReviewsReactions do
  @moduledoc """
  Recurso REST para bx_reviews_reactions.
  Fornece endpoints para gerenciar bx_reviews_reactions.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxReviewsReactions,
    resource_name: "bx_reviews_reaction"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
