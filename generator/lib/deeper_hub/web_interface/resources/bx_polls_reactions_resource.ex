defmodule DeeperHub.WebInterface.Resources.BxPollsReactions do
  @moduledoc """
  Recurso REST para bx_polls_reactions.
  Fornece endpoints para gerenciar bx_polls_reactions.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPollsReactions,
    resource_name: "bx_polls_reaction"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
