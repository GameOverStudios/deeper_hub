defmodule DeeperHub.WebInterface.Resources.BxCoursesCmtsNotes do
  @moduledoc """
  Recurso REST para bx_courses_cmts_notes.
  Fornece endpoints para gerenciar bx_courses_cmts_notes.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxCoursesCmtsNotes,
    resource_name: "bx_courses_cmts_note"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
