defmodule DeeperHub.WebInterface.Resources.BxForumReactions do
  @moduledoc """
  Recurso REST para bx_forum_reactions.
  Fornece endpoints para gerenciar bx_forum_reactions.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxForumReactions,
    resource_name: "bx_forum_reaction"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
