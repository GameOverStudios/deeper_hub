defmodule DeeperHub.WebInterface.Resources.BxCoursesContentNodes2users do
  @moduledoc """
  Recurso REST para bx_courses_content_nodes2users.
  Fornece endpoints para gerenciar bx_courses_content_nodes2users.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxCoursesContentNodes2users,
    resource_name: "bx_courses_content_nodes2user"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
