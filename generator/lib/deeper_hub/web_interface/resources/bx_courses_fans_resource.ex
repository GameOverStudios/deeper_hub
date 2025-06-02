defmodule DeeperHub.WebInterface.Resources.BxCoursesFans do
  @moduledoc """
  Recurso REST para bx_courses_fans.
  Fornece endpoints para gerenciar bx_courses_fans.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxCoursesFans,
    resource_name: "bx_courses_fan"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
