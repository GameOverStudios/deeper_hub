defmodule DeeperHub.WebInterface.Resources.BxEventsIntervals do
  @moduledoc """
  Recurso REST para bx_events_intervals.
  Fornece endpoints para gerenciar bx_events_intervals.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxEventsIntervals,
    resource_name: "bx_events_interval"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
