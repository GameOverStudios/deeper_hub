defmodule DeeperHub.WebInterface.Resources.BxForumLinks2content do
  @moduledoc """
  Recurso REST para bx_forum_links2contents.
  Fornece endpoints para gerenciar bx_forum_links2contents.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxForumLinks2content,
    resource_name: "bx_forum_links2content"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
