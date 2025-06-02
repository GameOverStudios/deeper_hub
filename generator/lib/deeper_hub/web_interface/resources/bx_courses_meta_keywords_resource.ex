defmodule DeeperHub.WebInterface.Resources.BxCoursesMetaKeywords do
  @moduledoc """
  Recurso REST para bx_courses_meta_keywords.
  Fornece endpoints para gerenciar bx_courses_meta_keywords.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxCoursesMetaKeywords,
    resource_name: "bx_courses_meta_keyword"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
