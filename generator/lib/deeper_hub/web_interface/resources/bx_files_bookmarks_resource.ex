defmodule DeeperHub.WebInterface.Resources.BxFilesBookmarks do
  @moduledoc """
  Recurso REST para bx_files_bookmarks.
  Fornece endpoints para gerenciar bx_files_bookmarks.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxFilesBookmarks,
    resource_name: "bx_files_bookmark"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
