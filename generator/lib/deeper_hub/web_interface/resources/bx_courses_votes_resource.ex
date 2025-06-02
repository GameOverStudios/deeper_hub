defmodule DeeperHub.WebInterface.Resources.BxCoursesVotes do
  @moduledoc """
  Recurso REST para bx_courses_votes.
  Fornece endpoints para gerenciar bx_courses_votes.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxCoursesVotes,
    resource_name: "bx_courses_vote"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
