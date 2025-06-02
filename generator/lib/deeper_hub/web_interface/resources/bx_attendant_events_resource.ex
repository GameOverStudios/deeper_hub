defmodule DeeperHub.WebInterface.Resources.BxAttendantEvents do
  @moduledoc """
  Recurso REST para bx_attendant_events.
  Fornece endpoints para gerenciar bx_attendant_events.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAttendantEvents,
    resource_name: "bx_attendant_event"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
