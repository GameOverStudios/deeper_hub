defmodule DeeperHub.WebInterface.Resources.BxStoriesScores do
  @moduledoc """
  Recurso REST para bx_stories_scores.
  Fornece endpoints para gerenciar bx_stories_scores.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxStoriesScores,
    resource_name: "bx_stories_score"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
