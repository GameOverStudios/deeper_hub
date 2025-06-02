defmodule DeeperHub.WebInterface.Resources.BxCoursesInvites do
  @moduledoc """
  Recurso REST para bx_courses_invites.
  Fornece endpoints para gerenciar bx_courses_invites.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxCoursesInvites,
    resource_name: "bx_courses_invite"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
