defmodule DeeperHub.WebInterface.Resources.BxStoriesReactions do
  @moduledoc """
  Recurso REST para bx_stories_reactions.
  Fornece endpoints para gerenciar bx_stories_reactions.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxStoriesReactions,
    resource_name: "bx_stories_reaction"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
