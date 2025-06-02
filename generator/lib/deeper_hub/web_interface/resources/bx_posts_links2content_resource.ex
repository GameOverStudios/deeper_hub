defmodule DeeperHub.WebInterface.Resources.BxPostsLinks2content do
  @moduledoc """
  Recurso REST para bx_posts_links2contents.
  Fornece endpoints para gerenciar bx_posts_links2contents.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPostsLinks2content,
    resource_name: "bx_posts_links2content"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
