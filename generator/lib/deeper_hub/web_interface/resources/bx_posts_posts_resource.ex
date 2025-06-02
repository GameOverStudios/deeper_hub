defmodule DeeperHub.WebInterface.Resources.BxPostsPosts do
  @moduledoc """
  Recurso REST para bx_posts_posts.
  Fornece endpoints para gerenciar bx_posts_posts.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPostsPosts,
    resource_name: "bx_posts_post"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
