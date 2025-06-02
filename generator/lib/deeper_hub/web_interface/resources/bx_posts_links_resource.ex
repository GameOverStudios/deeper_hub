defmodule DeeperHub.WebInterface.Resources.BxPostsLinks do
  @moduledoc """
  Recurso REST para bx_posts_links.
  Fornece endpoints para gerenciar bx_posts_links.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPostsLinks,
    resource_name: "bx_posts_link"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
