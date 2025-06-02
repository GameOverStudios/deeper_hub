defmodule DeeperHub.WebInterface.Resources.BxPostsScores do
  @moduledoc """
  Recurso REST para bx_posts_scores.
  Fornece endpoints para gerenciar bx_posts_scores.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPostsScores,
    resource_name: "bx_posts_score"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
