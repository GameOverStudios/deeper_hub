defmodule DeeperHub.WebInterface.Resources.BxPostsReactions do
  @moduledoc """
  Recurso REST para bx_posts_reactions.
  Fornece endpoints para gerenciar bx_posts_reactions.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPostsReactions,
    resource_name: "bx_posts_reaction"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
