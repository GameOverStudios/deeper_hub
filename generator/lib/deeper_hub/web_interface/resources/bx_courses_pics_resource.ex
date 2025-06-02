defmodule DeeperHub.WebInterface.Resources.BxCoursesPics do
  @moduledoc """
  Recurso REST para bx_courses_pics.
  Fornece endpoints para gerenciar bx_courses_pics.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxCoursesPics,
    resource_name: "bx_courses_pic"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
