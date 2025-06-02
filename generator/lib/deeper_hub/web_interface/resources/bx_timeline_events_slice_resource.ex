defmodule DeeperHub.WebInterface.Resources.BxTimelineEventsSlice do
  @moduledoc """
  Recurso REST para bx_timeline_events_slices.
  Fornece endpoints para gerenciar bx_timeline_events_slices.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTimelineEventsSlice,
    resource_name: "bx_timeline_events_slice"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
