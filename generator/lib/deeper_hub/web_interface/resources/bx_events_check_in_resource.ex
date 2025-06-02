defmodule DeeperHub.WebInterface.Resources.BxEventsCheckIn do
  @moduledoc """
  Recurso REST para bx_events_check_ins.
  Fornece endpoints para gerenciar bx_events_check_ins.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxEventsCheckIn,
    resource_name: "bx_events_check_in"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
