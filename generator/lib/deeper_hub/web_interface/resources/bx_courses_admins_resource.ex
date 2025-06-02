defmodule DeeperHub.WebInterface.Resources.BxCoursesAdmins do
  @moduledoc """
  Recurso REST para bx_courses_admins.
  Fornece endpoints para gerenciar bx_courses_admins.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxCoursesAdmins,
    resource_name: "bx_courses_admin"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
