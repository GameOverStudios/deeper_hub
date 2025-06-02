defmodule DeeperHub.WebInterface.Resources.BxForumFavoritesLists do
  @moduledoc """
  Recurso REST para bx_forum_favorites_lists.
  Fornece endpoints para gerenciar bx_forum_favorites_lists.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxForumFavoritesLists,
    resource_name: "bx_forum_favorites_list"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
