defmodule DeeperHub.WebInterface.Resources.BxAlbumsReactions do
  @moduledoc """
  Recurso REST para bx_albums_reactions.
  Fornece endpoints para gerenciar bx_albums_reactions.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAlbumsReactions,
    resource_name: "bx_albums_reaction"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
