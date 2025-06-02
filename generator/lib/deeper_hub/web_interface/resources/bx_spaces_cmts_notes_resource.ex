defmodule DeeperHub.WebInterface.Resources.BxSpacesCmtsNotes do
  @moduledoc """
  Recurso REST para bx_spaces_cmts_notes.
  Fornece endpoints para gerenciar bx_spaces_cmts_notes.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxSpacesCmtsNotes,
    resource_name: "bx_spaces_cmts_note"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
