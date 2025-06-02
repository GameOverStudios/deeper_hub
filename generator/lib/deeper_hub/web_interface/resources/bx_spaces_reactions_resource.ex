defmodule DeeperHub.WebInterface.Resources.BxSpacesReactions do
  @moduledoc """
  Recurso REST para bx_spaces_reactions.
  Fornece endpoints para gerenciar bx_spaces_reactions.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxSpacesReactions,
    resource_name: "bx_spaces_reaction"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
