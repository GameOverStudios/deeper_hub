defmodule DeeperHub.WebInterface.Resources.BxCoursesScores do
  @moduledoc """
  Recurso REST para bx_courses_scores.
  Fornece endpoints para gerenciar bx_courses_scores.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxCoursesScores,
    resource_name: "bx_courses_score"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
