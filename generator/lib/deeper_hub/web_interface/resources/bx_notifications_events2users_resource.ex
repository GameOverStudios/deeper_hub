defmodule DeeperHub.WebInterface.Resources.BxNotificationsEvents2users do
  @moduledoc """
  Recurso REST para bx_notifications_events2users.
  Fornece endpoints para gerenciar bx_notifications_events2users.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxNotificationsEvents2users,
    resource_name: "bx_notifications_events2user"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
