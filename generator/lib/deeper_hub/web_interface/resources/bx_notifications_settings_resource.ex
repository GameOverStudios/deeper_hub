defmodule DeeperHub.WebInterface.Resources.BxNotificationsSettings do
  @moduledoc """
  Recurso REST para bx_notifications_settings.
  Fornece endpoints para gerenciar bx_notifications_settings.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxNotificationsSettings,
    resource_name: "bx_notifications_setting"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
