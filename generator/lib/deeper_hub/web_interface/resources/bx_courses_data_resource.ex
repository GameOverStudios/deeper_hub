defmodule DeeperHub.WebInterface.Resources.BxCoursesData do
  @moduledoc """
  Recurso REST para bx_courses_datas.
  Fornece endpoints para gerenciar bx_courses_datas.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxCoursesData,
    resource_name: "bx_courses_data"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
