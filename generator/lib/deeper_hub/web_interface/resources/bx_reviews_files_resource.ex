defmodule DeeperHub.WebInterface.Resources.BxReviewsFiles do
  @moduledoc """
  Recurso REST para bx_reviews_files.
  Fornece endpoints para gerenciar bx_reviews_files.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxReviewsFiles,
    resource_name: "bx_reviews_file"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
