defmodule DeeperHub.WebInterface.Resources.BxReviewsCmts do
  @moduledoc """
  Recurso REST para bx_reviews_cmts.
  Fornece endpoints para gerenciar bx_reviews_cmts.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxReviewsCmts,
    resource_name: "bx_reviews_cmt"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
