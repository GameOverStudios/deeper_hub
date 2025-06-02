defmodule DeeperHub.WebInterface.Resources.BxFilesFavoritesLists do
  @moduledoc """
  Recurso REST para bx_files_favorites_lists.
  Fornece endpoints para gerenciar bx_files_favorites_lists.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxFilesFavoritesLists,
    resource_name: "bx_files_favorites_list"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
