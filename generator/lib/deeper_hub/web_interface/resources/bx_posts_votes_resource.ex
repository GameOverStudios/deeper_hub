defmodule DeeperHub.WebInterface.Resources.BxPostsVotes do
  @moduledoc """
  Recurso REST para bx_posts_votes.
  Fornece endpoints para gerenciar bx_posts_votes.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPostsVotes,
    resource_name: "bx_posts_vote"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
