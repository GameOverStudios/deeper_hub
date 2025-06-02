defmodule DeeperHub.WebInterface.Resources.BxEventsReactions do
  @moduledoc """
  Recurso REST para bx_events_reactions.
  Fornece endpoints para gerenciar bx_events_reactions.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxEventsReactions,
    resource_name: "bx_events_reaction"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
