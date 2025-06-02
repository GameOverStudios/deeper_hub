defmodule DeeperHub.WebInterface.Resources.BxEventsVotes do
  @moduledoc """
  Recurso REST para bx_events_votes.
  Fornece endpoints para gerenciar bx_events_votes.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxEventsVotes,
    resource_name: "bx_events_vote"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
