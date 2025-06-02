defmodule DeeperHub.WebInterface.Resources.BxEventsReactionsTrack do
  @moduledoc """
  Recurso REST para bx_events_reactions_tracks.
  Fornece endpoints para gerenciar bx_events_reactions_tracks.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxEventsReactionsTrack,
    resource_name: "bx_events_reactions_track"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
