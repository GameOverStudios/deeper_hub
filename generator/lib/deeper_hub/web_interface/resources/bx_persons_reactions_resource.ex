defmodule DeeperHub.WebInterface.Resources.BxPersonsReactions do
  @moduledoc """
  Recurso REST para bx_persons_reactions.
  Fornece endpoints para gerenciar bx_persons_reactions.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPersonsReactions,
    resource_name: "bx_persons_reaction"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
