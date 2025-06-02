defmodule DeeperHub.WebInterface.Resources.BxCoursesContentData2users do
  @moduledoc """
  Recurso REST para bx_courses_content_data2users.
  Fornece endpoints para gerenciar bx_courses_content_data2users.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxCoursesContentData2users,
    resource_name: "bx_courses_content_data2user"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
