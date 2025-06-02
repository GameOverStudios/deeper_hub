defmodule DeeperHub.WebInterface.Resources.BxAlbumsCmts do
  @moduledoc """
  Recurso REST para bx_albums_cmts.
  Fornece endpoints para gerenciar bx_albums_cmts.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAlbumsCmts,
    resource_name: "bx_albums_cmt"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
