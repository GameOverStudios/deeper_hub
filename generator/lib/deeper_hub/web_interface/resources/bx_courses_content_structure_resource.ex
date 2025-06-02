defmodule DeeperHub.WebInterface.Resources.BxCoursesContentStructure do
  @moduledoc """
  Recurso REST para bx_courses_content_structures.
  Fornece endpoints para gerenciar bx_courses_content_structures.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxCoursesContentStructure,
    resource_name: "bx_courses_content_structure"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
