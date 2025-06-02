defmodule DeeperHub.WebInterface.Resources.BxNotificationsHandlers do
  @moduledoc """
  Recurso REST para bx_notifications_handlers.
  Fornece endpoints para gerenciar bx_notifications_handlers.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxNotificationsHandlers,
    resource_name: "bx_notifications_handler"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
