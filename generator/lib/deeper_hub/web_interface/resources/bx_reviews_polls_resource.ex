defmodule DeeperHub.WebInterface.Resources.BxReviewsPolls do
  @moduledoc """
  Recurso REST para bx_reviews_polls.
  Fornece endpoints para gerenciar bx_reviews_polls.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxReviewsPolls,
    resource_name: "bx_reviews_poll"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
