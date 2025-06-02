defmodule DeeperHub.WebInterface.Resources.BxReviewsSvotes do
  @moduledoc """
  Recurso REST para bx_reviews_svotes.
  Fornece endpoints para gerenciar bx_reviews_svotes.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxReviewsSvotes,
    resource_name: "bx_reviews_svote"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
