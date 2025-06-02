defmodule DeeperHub.WebInterface.Resources.BxCoursesContentNodes do
  @moduledoc """
  Recurso REST para bx_courses_content_nodes.
  Fornece endpoints para gerenciar bx_courses_content_nodes.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxCoursesContentNodes,
    resource_name: "bx_courses_content_node"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
