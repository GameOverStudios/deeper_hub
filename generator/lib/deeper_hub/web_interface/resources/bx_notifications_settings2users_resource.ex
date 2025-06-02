defmodule DeeperHub.WebInterface.Resources.BxNotificationsSettings2users do
  @moduledoc """
  Recurso REST para bx_notifications_settings2users.
  Fornece endpoints para gerenciar bx_notifications_settings2users.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxNotificationsSettings2users,
    resource_name: "bx_notifications_settings2user"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
