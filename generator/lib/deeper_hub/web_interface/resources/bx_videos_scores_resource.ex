defmodule DeeperHub.WebInterface.Resources.BxVideosScores do
  @moduledoc """
  Recurso REST para bx_videos_scores.
  Fornece endpoints para gerenciar bx_videos_scores.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxVideosScores,
    resource_name: "bx_videos_score"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
