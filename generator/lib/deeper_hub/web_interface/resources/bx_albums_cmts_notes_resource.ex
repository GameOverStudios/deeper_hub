defmodule DeeperHub.WebInterface.Resources.BxAlbumsCmtsNotes do
  @moduledoc """
  Recurso REST para bx_albums_cmts_notes.
  Fornece endpoints para gerenciar bx_albums_cmts_notes.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAlbumsCmtsNotes,
    resource_name: "bx_albums_cmts_note"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
