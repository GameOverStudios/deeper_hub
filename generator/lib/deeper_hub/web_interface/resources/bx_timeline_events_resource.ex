defmodule DeeperHub.WebInterface.Resources.BxTimelineEvents do
  @moduledoc """
  Recurso REST para bx_timeline_events.
  Fornece endpoints para gerenciar bx_timeline_events.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTimelineEvents,
    resource_name: "bx_timeline_event"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
