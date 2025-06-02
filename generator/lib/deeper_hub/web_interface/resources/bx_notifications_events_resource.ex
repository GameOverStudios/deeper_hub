defmodule DeeperHub.WebInterface.Resources.BxNotificationsEvents do
  @moduledoc """
  Recurso REST para bx_notifications_events.
  Fornece endpoints para gerenciar bx_notifications_events.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxNotificationsEvents,
    resource_name: "bx_notifications_event"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
