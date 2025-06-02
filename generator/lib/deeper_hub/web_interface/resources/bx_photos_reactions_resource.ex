defmodule DeeperHub.WebInterface.Resources.BxPhotosReactions do
  @moduledoc """
  Recurso REST para bx_photos_reactions.
  Fornece endpoints para gerenciar bx_photos_reactions.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPhotosReactions,
    resource_name: "bx_photos_reaction"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
