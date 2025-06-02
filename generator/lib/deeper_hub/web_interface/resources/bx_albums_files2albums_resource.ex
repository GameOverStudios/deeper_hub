defmodule DeeperHub.WebInterface.Resources.BxAlbumsFiles2albums do
  @moduledoc """
  Recurso REST para bx_albums_files2albums.
  Fornece endpoints para gerenciar bx_albums_files2albums.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAlbumsFiles2albums,
    resource_name: "bx_albums_files2album"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
