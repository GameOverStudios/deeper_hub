defmodule DeeperHub.WebInterface.Resources.BxPhotosScores do
  @moduledoc """
  Recurso REST para bx_photos_scores.
  Fornece endpoints para gerenciar bx_photos_scores.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPhotosScores,
    resource_name: "bx_photos_score"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
